import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final String portionLabel; // '1 kg', '500g', '250g', '1 bunch', etc.
  final double portionMultiplier; // 1.0, 0.5, 0.25

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.portionLabel = '1 unit',
    this.portionMultiplier = 1.0,
  });

  String get cartKey => '${product.id}_$portionLabel';

  double get unitPrice => (product.price * portionMultiplier).roundToDouble();

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': product.id,
      'name': product.name,
      'qty': quantity,
      'portion': portionLabel,
      'unit': product.unit,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory CartItemModel.fromJson(
      Map<String, dynamic> json, ProductModel product) {
    return CartItemModel(
      product: product,
      quantity: (json['qty'] as num?)?.toInt() ?? 1,
      portionLabel: json['portion'] as String? ?? '1 unit',
      portionMultiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
