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

  /// Toggle this to true if you want to test your real production ad unit before Play Store release.
  /// (Ensure your device is registered as a Test Device in AdMob console).
  static const bool useLiveAdsInDebug = false;

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
    if (kReleaseMode || useLiveAdsInDebug) {
      // Production live banner ID
      if (Platform.isAndroid) {
        return androidBannerId;
      }
      return testIosBannerId; // Fallback for iOS until iOS ad unit is created
    }

    // Debug mode: Return official Google Test Ad ID
    return Platform.isAndroid ? testAndroidBannerId : testIosBannerId;
  }
}
