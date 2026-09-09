import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class WishlistProvider extends ChangeNotifier {
  Set<String> _wishlistIds = {};

  Set<String> get wishlistIds => _wishlistIds;

  /// Initialize wishlist.
  /// If user is authenticated, loads from Supabase.
  /// Otherwise falls back to local SharedPreferences.
  Future<void> init({String? userId}) async {
    if (userId != null && SupabaseService.isInitialized) {
      try {
        final ids = await SupabaseService.getWishlistForUser(userId);
        _wishlistIds = ids.toSet();
        // Also sync local storage for offline consistency
        await StorageService.setWishlist(_wishlistIds.toList());
      } catch (e) {
        debugPrint('WishlistProvider: Failed to load from Supabase, using local: $e');
        _wishlistIds = StorageService.getWishlist().toSet();
      }
    } else {
      _wishlistIds = StorageService.getWishlist().toSet();
    }
    notifyListeners();
  }

  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  Future<void> toggle(String productId, {String? userId}) async {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
      notifyListeners();
      // Persist
      await StorageService.setWishlist(_wishlistIds.toList());
      if (userId != null) {
        await SupabaseService.removeFromWishlist(userId, productId);
      }
    } else {
      _wishlistIds.add(productId);
      notifyListeners();
      // Persist
      await StorageService.setWishlist(_wishlistIds.toList());
      if (userId != null) {
        await SupabaseService.addToWishlist(userId, productId);
      }
    }
  }
}
