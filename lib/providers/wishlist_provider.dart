import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class WishlistProvider extends ChangeNotifier {
  Set<String> _wishlistIds = {};

  Set<String> get wishlistIds => _wishlistIds;

  void init() {
    _wishlistIds = StorageService.getWishlist().toSet();
    notifyListeners();
  }

  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  Future<void> toggle(String productId) async {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    notifyListeners();
    await StorageService.toggleWishlist(productId);
  }
}
