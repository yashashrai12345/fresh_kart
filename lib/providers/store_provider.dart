import 'package:flutter/foundation.dart';
import '../models/store_settings_model.dart';
import '../services/supabase_service.dart';

class StoreProvider extends ChangeNotifier {
  StoreSettingsModel _settings = const StoreSettingsModel();
  bool _isLoading = true;

  StoreSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;

  double get freeDeliveryThreshold => _settings.freeDeliveryThreshold;
  double get deliveryFee => _settings.deliveryFee;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await SupabaseService.getStoreSettings();
    } catch (e) {
      debugPrint('Error loading store settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
