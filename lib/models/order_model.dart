class OrderItemSummary {
  final String productId;
  final String name;
  final int qty;
  final String? portion;
  final String? unit;
  final double unitPrice;
  final double subtotal;

  OrderItemSummary({
    required this.productId,
    required this.name,
    required this.qty,
    this.portion,
    this.unit,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 1,
      portion: json['portion'] as String?,
      unit: json['unit'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'qty': qty,
      'portion': portion,
      'unit': unit,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class OrderModel {
  final String id;
  final String deviceId;
  final String? userId; // Supabase auth.uid() — nullable for backward compat
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItemSummary> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.deviceId,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.status = 'PLACED',
    this.notes,
    required this.createdAt,
  });

  int get statusStepIndex {
    switch (status.toUpperCase()) {
      case 'PLACED':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'PACKED':
        return 2;
      case 'OUT_FOR_DELIVERY':
        return 3;
      case 'DELIVERED':
        return 4;
      case 'CANCELLED':
        return -1;
      default:
        return 0;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItemSummary> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => OrderItemSummary.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      customerName: json['customer_name'] as String? ?? 'Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      deliveryAddress: json['delivery_address'] as String? ?? '',
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PLACED',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
