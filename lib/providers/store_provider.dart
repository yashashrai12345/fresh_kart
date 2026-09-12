import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/store_settings_model.dart';
import '../services/supabase_service.dart';

class StoreProvider extends ChangeNotifier {
  StoreSettingsModel _settings = const StoreSettingsModel();
  bool _isLoading = true;
  StreamSubscription<StoreSettingsModel>? _settingsSubscription;

  StoreSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  double get freeDeliveryThreshold => _settings.freeDeliveryThreshold;
  double get deliveryFee => _settings.deliveryFee;

  void initRealtimeSubscription() {
    if (_settingsSubscription != null) return;
    final stream = SupabaseService.subscribeToStoreSettings();
    if (stream != null) {
      _settingsSubscription = stream.listen((newSettings) {
        debugPrint('[Realtime] Store settings updated live: maintenance=${newSettings.isMaintenanceMode}');
        _settings = newSettings;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('[Realtime] Error in store settings stream: $e');
      });
    }
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await SupabaseService.getStoreSettings();
      initRealtimeSubscription();
    } catch (e) {
      debugPrint('Error loading store settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
