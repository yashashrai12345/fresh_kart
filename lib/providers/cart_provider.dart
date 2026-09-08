import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => _items;

  List<CartItemModel> get itemList => _items.values.toList();

  int get itemCount => _items.length;

  int get totalUnitsCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  void addItem({
    required ProductModel product,
    String portionLabel = '1 unit',
    double portionMultiplier = 1.0,
    int quantity = 1,
  }) {
    final key = '${product.id}_$portionLabel';
    if (_items.containsKey(key)) {
      _items[key]!.quantity += quantity;
    } else {
      _items[key] = CartItemModel(
        product: product,
        quantity: quantity,
        portionLabel: portionLabel,
        portionMultiplier: portionMultiplier,
      );
    }
    notifyListeners();
  }

  void increment(String cartKey) {
    if (_items.containsKey(cartKey)) {
      _items[cartKey]!.quantity += 1;
      notifyListeners();
    }
  }

  void decrement(String cartKey) {
    if (_items.containsKey(cartKey)) {
      if (_items[cartKey]!.quantity > 1) {
        _items[cartKey]!.quantity -= 1;
      } else {
        _items.remove(cartKey);
      }
      notifyListeners();
    }
  }

  void removeItem(String cartKey) {
    _items.remove(cartKey);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Delivery calculations
  double getDeliveryFee(double threshold, double fee) {
    if (isEmpty) return 0.0;
    return subtotal >= threshold ? 0.0 : fee;
  }

  double getRemainingForFreeDelivery(double threshold) {
    return max(0.0, threshold - subtotal);
  }

  bool isFreeDeliveryUnlocked(double threshold) {
    return subtotal >= threshold && subtotal > 0;
  }

  double getGrandTotal(double threshold, double fee) {
    if (isEmpty) return 0.0;
    return subtotal + getDeliveryFee(threshold, fee);
  }

  CartItemModel? getFirstItemForProduct(String productId) {
    for (final item in _items.values) {
      if (item.product.id == productId) {
        return item;
      }
    }
    return null;
  }
}
