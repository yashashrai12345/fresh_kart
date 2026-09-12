// Firebase Cloud Messaging Service Worker for Green Basket Admin Panel
// This file MUST be at the root of the served web app (public/).
// It handles background push notifications in the browser.

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// ── Firebase config — matches weighty-forest-411105 project ──────────────────
// These are public / safe to expose in the service worker.
firebase.initializeApp({
  apiKey: 'AIzaSyAitpvecCjQB-7atmYY3WkVpixqCT-mh9g',
  authDomain: 'weighty-forest-411105.firebaseapp.com',
  projectId: 'weighty-forest-411105',
  storageBucket: 'weighty-forest-411105.firebasestorage.app',
  messagingSenderId: '716511278689',
  appId: '1:716511278689:android:293c2557f7e8a335871c20',
});

const messaging = firebase.messaging();

// Handle background messages (browser tab not in focus)
messaging.onBackgroundMessage((payload) => {
  console.log('[FCM SW] Background message received:', payload);

  const notification = payload.notification || {};
  const title = notification.title || '🛒 Green Basket';
  const body = notification.body || 'You have a new notification.';

  self.registration.showNotification(title, {
    body,
    icon: '/logo/fresh_kart_icon.jpg',
    badge: '/logo/fresh_kart_icon.jpg',
    tag: payload.data?.order_id || 'freshkart',
    data: payload.data,
    requireInteraction: true,
  });
});

// Clicking the notification opens / focuses the admin panel tab
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        if (windowClients.length > 0) {
          return windowClients[0].focus();
        }
        return clients.openWindow('/');
      })
  );
});
