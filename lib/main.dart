import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/order_provider.dart';
import 'providers/store_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Limit memory image cache to 100 images and 50MB RAM to prevent OutOfMemory/GC pauses
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;

  // Initialize storage, Supabase, Firebase, and AdMob
  await StorageService.init();
  await SupabaseService.init();
  await AdService.init();

  try {
    await Firebase.initializeApp();

    // Register the background message handler BEFORE any other FCM calls
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize notification channel and foreground listeners
    await NotificationService.init();
  } catch (e) {
    debugPrint('Firebase initialization: $e');
  }

  runApp(const GreenBasketApp());
}

class GreenBasketApp extends StatelessWidget {
  const GreenBasketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth must be first so other providers can depend on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        title: 'Green Basket',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}
