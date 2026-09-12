// Green Basket — Supabase Edge Function: send-notification
// Triggered by Supabase Database Webhooks on INSERT and UPDATE of the orders table.
//
// Webhook payload shape:
//   { type: 'INSERT' | 'UPDATE', table: 'orders', record: {...}, old_record: {...} }
//
// Environment secrets (set via: supabase secrets set KEY=value):
//   FIREBASE_PROJECT_ID     — e.g. weighty-forest-411105
//   FIREBASE_SERVICE_ACCOUNT_JSON — full JSON string of the service account key

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? '';
const SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

// ── JWT: Generate a short-lived OAuth2 token for FCM HTTP v1 API ──────────

async function getAccessToken(): Promise<string> {
  const sa = JSON.parse(SERVICE_ACCOUNT_JSON);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  const signingInput = `${encode(header)}.${encode(payload)}`;

  // Import the RSA private key
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${arrayBufferToBase64Url(signature)}`;

  // Exchange JWT for access token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token as string;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function arrayBufferToBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

// ── Send FCM push to a list of tokens ─────────────────────────────────────

async function sendFcmNotification(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string> = {}
) {
  if (tokens.length === 0) return;

  const accessToken = await getAccessToken();
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

  const results = await Promise.allSettled(
    tokens.map((token) =>
      fetch(fcmUrl, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data,
            android: {
              priority: 'high',
              notification: {
                channel_id: 'freshkart_orders',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            webpush: {
              notification: {
                icon: '/logo/fresh_kart_icon.jpg',
                require_interaction: true,
              },
            },
          },
        }),
      }).then((r) => r.json())
    )
  );

  for (const result of results) {
    if (result.status === 'fulfilled') {
      const res = result.value;
      if (res.error) console.warn('[FCM] Send error:', JSON.stringify(res.error));
    }
  }
}

// ── Main handler ───────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const body = await req.json();
    const { type, record, old_record } = body;

    if (!record) {
      return new Response('No record in payload', { status: 400 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const orderId: string = record.id;
    const newStatus: string = (record.status ?? '').toUpperCase();
    const oldStatus: string = (old_record?.status ?? '').toUpperCase();

    // ── Helper: Fetch customer FCM tokens (with fallback) ────────────────
    async function getCustomerTokens(userId?: string | null): Promise<string[]> {
      if (userId) {
        const { data } = await supabase
          .from('user_fcm_tokens')
          .select('token')
          .eq('user_id', userId);
        if (data && data.length > 0) {
          return data.map((r: { token: string }) => r.token);
        }
      }
      // Fallback: look up any registered Android device tokens
      const { data } = await supabase
        .from('user_fcm_tokens')
        .select('token')
        .eq('platform', 'android')
        .order('updated_at', { ascending: false })
        .limit(5);
      return (data ?? []).map((r: { token: string }) => r.token);
    }

    // ── Case 1: New order placed → notify admin AND customer ─────────────
    if (type === 'INSERT' && (newStatus === 'PLACED' || !newStatus)) {
      const { data: adminTokens } = await supabase
        .from('user_fcm_tokens')
        .select('token')
        .eq('user_id', 'admin');

      const aTokens = (adminTokens ?? []).map((r: { token: string }) => r.token);
      const total = record.total ? `₹${Math.round(record.total)}` : '';
      const name = record.customer_name ?? 'A customer';

      // 1. Notify Admin browser
      await sendFcmNotification(
        aTokens,
        '🛒 New Order Received!',
        `Order #${orderId} · ${total} from ${name}`,
        { order_id: orderId, type: 'new_order' }
      );

      // 2. Notify Customer mobile app
      const cTokens = await getCustomerTokens(record.user_id);
      if (cTokens.length > 0) {
        await sendFcmNotification(
          cTokens,
          '🎉 Order Placed Successfully!',
          `Your Green Basket order #${orderId} for ${total} has been received.`,
          { order_id: orderId, type: 'order_placed', status: 'PLACED' }
        );
      }

      return new Response(
        JSON.stringify({ sent: 'both', admin_count: aTokens.length, customer_count: cTokens.length }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }

    // ── Case 2: Order status updated → notify customer ───────────────────
    if (type === 'UPDATE' && newStatus !== oldStatus) {
      const msgMap: Record<string, { title: string; body: string }> = {
        CONFIRMED: {
          title: '✅ Order Confirmed!',
          body: `Your Green Basket order #${orderId} is confirmed and being prepared!`,
        },
        OUT_FOR_DELIVERY: {
          title: '🛵 Out for Delivery!',
          body: `Your Green Basket order #${orderId} is on its way to you!`,
        },
        CANCELLED: {
          title: '❌ Order Cancelled',
          body: `Your Green Basket order #${orderId} has been cancelled.`,
        },
        DELIVERED: {
          title: '🎉 Order Delivered!',
          body: `Your Green Basket order #${orderId} has been delivered. Enjoy!`,
        },
      };

      const msg = msgMap[newStatus];
      if (!msg) {
        return new Response(JSON.stringify({ skipped: 'status not a notify trigger' }), {
          headers: { 'Content-Type': 'application/json' },
        });
      }

      const tokens = await getCustomerTokens(record.user_id);

      await sendFcmNotification(tokens, msg.title, msg.body, {
        order_id: orderId,
        status: newStatus,
        type: 'order_update',
      });

      return new Response(
        JSON.stringify({ sent: 'customer', status: newStatus, count: tokens.length }),
        { headers: { 'Content-Type': 'application/json' } }
      );
    }

    return new Response(JSON.stringify({ skipped: 'no matching trigger' }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('[send-notification] Error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
