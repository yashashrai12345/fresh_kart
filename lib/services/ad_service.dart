import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Your Production AdMob IDs
  static const String androidAppId = 'ca-app-pub-2263317775787748~1020634249';
  static const String androidBannerId = 'ca-app-pub-2263317775787748/2602530417';

  // Google Official Sample Test Ad Unit IDs (used in debug to prevent AdMob policy strikes)
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  /// Set to true while testing on physical phone so Google's official Test Ads always appear.
  /// Set to false when you are ready to build the final bundle for Google Play Store upload!
  static const bool forceTestAds = true;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initializes the Google Mobile Ads SDK
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdMob] Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      debugPrint('[AdMob] Failed to initialize Google Mobile Ads SDK: $e');
    }
  }

  /// Returns the appropriate Banner Ad Unit ID based on platform and build mode
  static String get bannerAdUnitId {
    // If testing ads is requested (or in debug mode), always return Google's official Test Ad ID
    if (forceTestAds || !kReleaseMode) {
      return Platform.isAndroid ? testAndroidBannerId : testIosBannerId;
    }

    // Production release mode for Google Play Store
    if (Platform.isAndroid) {
      return androidBannerId;
    }
    return testIosBannerId;
  }
}
