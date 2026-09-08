class ProductModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final double mrp;
  final String unit; // '/kg', '/bunch', '/pack', '/pc'
  final String dietTag; // 'veg', 'egg', 'limited'
  final int spiceLevel;
  final String photoUrl;
  final bool inStock;
  final int? stockLeft;
  final double rating;
  final int reviewCount;
  final int sortOrder;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    required this.price,
    required this.mrp,
    this.unit = '/kg',
    this.dietTag = 'veg',
    this.spiceLevel = 0,
    required this.photoUrl,
    this.inStock = true,
    this.stockLeft,
    this.rating = 4.8,
    this.reviewCount = 36,
    this.sortOrder = 0,
  });

  int get discountPercentage {
    if (mrp <= price) return 0;
    return (((mrp - price) / mrp) * 100).round();
  }

  bool get isKgUnit => unit.toLowerCase().contains('kg');

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      mrp: (json['mrp'] as num).toDouble(),
      unit: json['unit'] as String? ?? '/kg',
      dietTag: json['diet_tag'] as String? ?? 'veg',
      spiceLevel: (json['spice_level'] as num?)?.toInt() ?? 0,
      photoUrl: json['photo_url'] as String? ?? '',
      inStock: json['in_stock'] as bool? ?? true,
      stockLeft: (json['stock_left'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 36,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      'diet_tag': dietTag,
      'spice_level': spiceLevel,
      'photo_url': photoUrl,
      'in_stock': inStock,
      'stock_left': stockLeft,
      'rating': rating,
      'review_count': reviewCount,
      'sort_order': sortOrder,
    };
  }
}
