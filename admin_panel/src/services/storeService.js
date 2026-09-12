import { createClient } from '@supabase/supabase-js';
import { initializeApp, getApps } from 'firebase/app';
import { getMessaging, getToken, onMessage } from 'firebase/messaging';
import { INITIAL_SETTINGS, INITIAL_CATEGORIES, INITIAL_PRODUCTS, INITIAL_ORDERS } from '../data/initialData';

const rawUrl = import.meta.env.VITE_SUPABASE_URL || '';
const cleanUrl = rawUrl.replace(/\/rest\/v1\/?$/, '').replace(/\/$/, '');
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const isSupabaseConfigured = Boolean(
  cleanUrl && supabaseAnonKey && !cleanUrl.includes('placeholder')
);

export const supabase = isSupabaseConfigured
  ? createClient(cleanUrl, supabaseAnonKey)
  : null;

// ── Firebase Web Config ────────────────────────────────────────────────────
// Values come from google-services.json / Firebase Console → Project Settings.
const FIREBASE_CONFIG = {
  apiKey: 'AIzaSyAitpvecCjQB-7atmYY3WkVpixqCT-mh9g',
  authDomain: 'weighty-forest-411105.firebaseapp.com',
  projectId: 'weighty-forest-411105',
  storageBucket: 'weighty-forest-411105.firebasestorage.app',
  messagingSenderId: '716511278689',
  appId: '1:716511278689:android:293c2557f7e8a335871c20',
};

// VAPID key from Firebase Console → Project Settings → Cloud Messaging
// → Web Push certificates → Key pair  (paste yours into .env)
const VAPID_KEY = import.meta.env.VITE_FIREBASE_VAPID_KEY || '';

function getFirebaseMessaging() {
  const app = getApps().length ? getApps()[0] : initializeApp(FIREBASE_CONFIG);
  return getMessaging(app);
}

// LocalStorage helpers for offline/standalone mode (catalog data only - NOT auth)
const STORAGE_KEYS = {
  SETTINGS: 'freshkart_admin_settings',
  CATEGORIES: 'freshkart_admin_categories',
  PRODUCTS: 'freshkart_admin_products',
  ORDERS: 'freshkart_admin_orders',
};

function getLocalData(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) {
      localStorage.setItem(key, JSON.stringify(fallback));
      return fallback;
    }
    const data = JSON.parse(raw);
    if (key === STORAGE_KEYS.SETTINGS && data && data.whatsapp_number === '919876543210') {
      data.whatsapp_number = '918970050327';
      localStorage.setItem(key, JSON.stringify(data));
    }
    return data;
  } catch (e) {
    console.error('LocalStorage error:', e);
    return fallback;
  }
}

function setLocalData(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
  } catch (e) {
    console.error('LocalStorage error:', e);
  }
}

// ── Admin Push Notifications ───────────────────────────────────────────────

/**
 * Call this after the admin logs in.
 * Requests browser notification permission, registers for FCM Web Push,
 * and saves the token to Supabase so the Edge Function can find it.
 */
export async function initAdminPushNotifications() {
  try {
    if (!('Notification' in window)) {
      console.warn('[FCM Admin] Browser does not support notifications.');
      return;
    }

    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
      console.warn('[FCM Admin] Notification permission denied.');
      return;
    }

    if (!VAPID_KEY) {
      console.warn(
        '[FCM Admin] VITE_FIREBASE_VAPID_KEY is not set in .env. ' +
        'Get it from Firebase Console → Project Settings → Cloud Messaging → Web Push certificates.'
      );
      return;
    }

    const messaging = getFirebaseMessaging();

    // Register the service worker first
    const registration = await navigator.serviceWorker.register(
      '/firebase-messaging-sw.js',
      { scope: '/' }
    );
    await navigator.serviceWorker.ready;

    const token = await getToken(messaging, {
      vapidKey: VAPID_KEY,
      serviceWorkerRegistration: registration,
    });

    if (token) {
      console.log('[FCM Admin] Browser push token obtained.');
      // Save to Supabase under a fixed user_id so the Edge Function can find it
      if (isSupabaseConfigured && supabase) {
        await supabase.from('user_fcm_tokens').upsert(
          {
            user_id: 'admin',
            token,
            platform: 'web',
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'token' }
        );
      }
    }

    // Handle foreground messages (admin tab is open and in focus)
    onMessage(messaging, (payload) => {
      console.log('[FCM Admin] Foreground message:', payload);
      const { title, body } = payload.notification || {};
      if (title && Notification.permission === 'granted') {
        new Notification(title, {
          body,
          icon: '/logo/fresh_kart_icon.jpg',
          tag: payload.data?.order_id || 'freshkart-admin',
        });
      }
    });
  } catch (e) {
    console.warn('[FCM Admin] Push notification setup failed:', e);
  }
}

export const storeService = {
  // --- AUTH ---
  // SECURITY: Admin login strictly requires successful Supabase Auth.
  // There is NO fallback fake session — if Supabase auth fails, login fails.
  async login(email, password) {
    if (!isSupabaseConfigured || !supabase) {
      throw new Error(
        'Supabase is not configured. Admin login requires a live Supabase connection. ' +
        'Please check your VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY environment variables.'
      );
    }

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error || !data?.user) {
      throw new Error(error?.message || 'Invalid email or password. Please try again.');
    }

    return {
      id: data.user.id,
      email: data.user.email,
      name: data.user.user_metadata?.name || 'Green Basket Admin',
    };
  },

  // Restore session from Supabase (call on app startup)
  async restoreSession() {
    if (!isSupabaseConfigured || !supabase) return null;
    try {
      const { data: { session }, error } = await supabase.auth.getSession();
      if (error || !session?.user) return null;
      return {
        id: session.user.id,
        email: session.user.email,
        name: session.user.user_metadata?.name || 'Green Basket Admin',
      };
    } catch (e) {
      console.warn('Session restore error:', e);
      return null;
    }
  },

  async logout() {
    if (isSupabaseConfigured && supabase) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        console.warn('SignOut error:', e);
      }
    }
  },

  // --- SETTINGS ---
  async getSettings() {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase.from('store_settings').select('*').limit(1).single();
      if (!error && data) {
        setLocalData(STORAGE_KEYS.SETTINGS, data);
        return data;
      }
    }
    return getLocalData(STORAGE_KEYS.SETTINGS, INITIAL_SETTINGS);
  },

  async updateSettings(newSettings) {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase
        .from('store_settings')
        .update({ ...newSettings, updated_at: new Date().toISOString() })
        .eq('id', newSettings.id)
        .select()
        .single();
      if (error) throw new Error(error.message || 'Failed to update settings');
      if (data) {
        setLocalData(STORAGE_KEYS.SETTINGS, data);
        return data;
      }
    }
    setLocalData(STORAGE_KEYS.SETTINGS, newSettings);
    return newSettings;
  },

  // --- CATEGORIES ---
  async getCategories() {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .order('sort_order', { ascending: true });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.CATEGORIES, INITIAL_CATEGORIES);
  },

  async saveCategory(category) {
    let categories = await this.getCategories();
    let catToSave;
    if (category.id) {
      catToSave = { ...category };
      categories = categories.map(c => c.id === category.id ? { ...c, ...category } : c);
    } else {
      catToSave = {
        ...category,
        id: `cat_${Date.now()}`,
        slug: category.name.toLowerCase().replace(/\s+/g, '-'),
        sort_order: categories.length + 1,
        is_active: true
      };
      categories.push(catToSave);
    }

    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('categories').upsert(catToSave);
      if (error) throw new Error(error.message || 'Failed to save category');
    }
    setLocalData(STORAGE_KEYS.CATEGORIES, categories);
    return categories;
  },

  async deleteCategory(id) {
    // First check if category has products — Supabase cascade will handle it
    // but we want to warn the admin explicitly
    const products = await this.getProducts();
    const productCount = products.filter(p => p.category_id === id).length;
    if (productCount > 0) {
      throw new Error(
        `Cannot delete: this category has ${productCount} product(s). ` +
        `Please reassign or delete those products first.`
      );
    }

    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('categories').delete().eq('id', id);
      if (error) throw new Error(error.message || 'Failed to delete category from database');
    }

    // Only update local cache after successful Supabase deletion
    let categories = await this.getCategories();
    categories = categories.filter(c => c.id !== id);
    setLocalData(STORAGE_KEYS.CATEGORIES, categories);
    return categories;
  },

  // --- PRODUCTS ---
  async getProducts() {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('sort_order', { ascending: true });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.PRODUCTS, INITIAL_PRODUCTS);
  },

  async saveProduct(product) {
    let products = await this.getProducts();
    let prodToSave;
    if (product.id) {
      prodToSave = { ...product };
      products = products.map(p => p.id === product.id ? { ...p, ...product } : p);
    } else {
      prodToSave = {
        ...product,
        id: `prod_${Date.now()}`,
        rating: 4.8,
        review_count: 1,
        sort_order: products.length + 1
      };
      products.unshift(prodToSave);
    }

    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('products').upsert(prodToSave);
      if (error) throw new Error(error.message || 'Failed to save product');
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  async toggleProductStock(id, inStock) {
    let products = await this.getProducts();
    products = products.map(p => p.id === id ? { ...p, in_stock: inStock } : p);
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('products').update({ in_stock: inStock }).eq('id', id);
      if (error) throw new Error(error.message || 'Failed to update stock status');
    }
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  async deleteProduct(id) {
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase.from('products').delete().eq('id', id);
      if (error) throw new Error(error.message || 'Failed to delete product from database');
    }

    // Only update local cache after successful Supabase deletion
    let products = await this.getProducts();
    products = products.filter(p => p.id !== id);
    setLocalData(STORAGE_KEYS.PRODUCTS, products);
    return products;
  },

  // --- ORDERS ---
  async getOrders() {
    if (isSupabaseConfigured && supabase) {
      const { data, error } = await supabase
        .from('orders')
        .select('*')
        .order('created_at', { ascending: false });
      if (!error && data) return data;
    }
    return getLocalData(STORAGE_KEYS.ORDERS, INITIAL_ORDERS);
  },

  async updateOrderStatus(orderId, newStatus) {
    if (isSupabaseConfigured && supabase) {
      const { error } = await supabase
        .from('orders')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', orderId);
      if (error) throw new Error(error.message || 'Failed to update order status');
    }

    let orders = await this.getOrders();
    orders = orders.map(o => o.id === orderId
      ? { ...o, status: newStatus, updated_at: new Date().toISOString() }
      : o
    );
    setLocalData(STORAGE_KEYS.ORDERS, orders);
    return orders;
  }
};
