import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

/// Top-level background message handler — must be a top-level function,
/// not a class method. Registered in main.dart via
/// FirebaseMessaging.onBackgroundMessage().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  // Nothing extra needed — the system tray notification is shown automatically.
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Android notification channel for Fresh Kart order updates.
  static const _channel = AndroidNotificationChannel(
    'freshkart_orders',          // channel id
    'Order Updates',             // channel name
    description: 'Fresh Kart order status and delivery notifications',
    importance: Importance.high,
    playSound: true,
  );

  /// Call once in main() after Firebase.initializeApp().
  static Future<void> init() async {
    // 1. Request permission (iOS / Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Create the Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // 3. Initialize flutter_local_notifications (for foreground display)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    // 4. Handle foreground messages — show a local notification banner
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // 5. When user taps a notification while app is in background (not killed)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Notification tapped (background): ${message.data}');
      // Navigation handled by the app's existing realtime subscription
    });

    // 6. Check if app was opened from a terminated-state notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] App launched from notification: ${initial.data}');
    }
  }

  /// Save the FCM token to Supabase so the Edge Function can find this device.
  /// Call this after the user logs in with their Firebase UID.
  static Future<void> registerToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await SupabaseService.saveFcmToken(userId, token);
        debugPrint('[FCM] Token registered for user $userId');
      }

      // Also listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        SupabaseService.saveFcmToken(userId, newToken);
        debugPrint('[FCM] Token refreshed for user $userId');
      });
    } catch (e) {
      debugPrint('[FCM] Error registering token: $e');
    }
  }

  // ── Internal: show a local notification while app is in foreground ─────────

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF059669), // Fresh Kart green
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: false,
        contentTitle: notification.title,
        htmlFormatContentTitle: false,
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: message.data['order_id'],
    );
  }
}
