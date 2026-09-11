import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/store_settings_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _activeTrackingOrder;
  StreamSubscription<OrderModel>? _trackingSubscription;
  StreamSubscription<List<OrderModel>>? _allOrdersSubscription;
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  OrderModel? get activeTrackingOrder => _activeTrackingOrder;
  bool get isLoading => _isLoading;

  Future<void> loadOrders({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use passed Firebase UID if provided, otherwise fall back to Supabase session (legacy)
      final resolvedUserId = userId ?? SupabaseService.currentUserId;

      if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
        // Authenticated user: fetch by user_id (Firebase UID stored in Supabase)
        _orders = await SupabaseService.getOrdersForUser(resolvedUserId);
        _startAllOrdersSubscription(userId: resolvedUserId);
      } else {
        // Unauthenticated fallback: device-based
        final deviceId = await StorageService.getDeviceId();
        _orders = await SupabaseService.getOrdersForDevice(deviceId);
        _startAllOrdersSubscription(deviceId: deviceId);
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      // Fallback to local orders
      _orders = StorageService.getLocalOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to live updates for orders
  void _startAllOrdersSubscription({String? userId, String? deviceId}) {
    _allOrdersSubscription?.cancel();

    Stream<List<OrderModel>>? stream;
    if (userId != null) {
      stream = SupabaseService.subscribeToUserOrders(userId);
    } else if (deviceId != null) {
      stream = SupabaseService.subscribeToDeviceOrders(deviceId);
    }

    if (stream != null) {
      _allOrdersSubscription = stream.listen((updatedOrders) {
        _orders = updatedOrders;
        // Keep active tracking order in sync as well
        if (_activeTrackingOrder != null) {
          final found = updatedOrders
              .where((o) => o.id == _activeTrackingOrder!.id)
              .toList();
          if (found.isNotEmpty) {
            _activeTrackingOrder = found.first;
          }
        }
        notifyListeners();
      });
    }
  }

  void setActiveTrackingOrder(OrderModel order) {
    _activeTrackingOrder = order;
    _startSingleOrderSubscription(order.id);
    notifyListeners();
  }

  // Fine-grained subscription for a single order being tracked.
  void _startSingleOrderSubscription(String orderId) {
    _trackingSubscription?.cancel();
    final stream = SupabaseService.subscribeToOrder(orderId);
    if (stream != null) {
      _trackingSubscription = stream.listen((updatedOrder) {
        _activeTrackingOrder = updatedOrder;
        // Mirror into the orders list too
        final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
        notifyListeners();
      });
    }
  }

  Future<OrderModel> placeOrder({
    required List<CartItemModel> cartItems,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String? notes,
    required StoreSettingsModel settings,
  }) async {
    final deviceId = await StorageService.getDeviceId();
    final userId = SupabaseService.currentUserId; // null if not authenticated

    // Generate unique readable order code
    final randomCode = 1000 + Random().nextInt(9000);
    final orderId = 'FK-$randomCode';

    // Build item summaries
    final items = cartItems.map((item) {
      return OrderItemSummary(
        productId: item.product.id,
        name: item.product.name,
        qty: item.quantity,
        portion: item.portionLabel,
        unit: item.product.unit,
        unitPrice: item.unitPrice,
        subtotal: item.subtotal,
      );
    }).toList();

    final subtotal =
        cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
    final deliveryFee =
        subtotal >= settings.freeDeliveryThreshold ? 0.0 : settings.deliveryFee;
    final total = subtotal + deliveryFee;

    final order = OrderModel(
      id: orderId,
      deviceId: deviceId,
      userId: userId, // Associate with authenticated user if available
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      status: 'PLACED',
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Save customer preferences for next time
    await StorageService.saveCustomerDetails(
      name: customerName,
      phone: customerPhone,
      address: deliveryAddress,
    );

    // Persist to backend and local storage
    await SupabaseService.createOrder(order);

    // Add to local state
    _orders.insert(0, order);
    _activeTrackingOrder = order;
    _startSingleOrderSubscription(order.id);
    notifyListeners();

    // Handoff to WhatsApp
    await WhatsAppService.sendOrderOnWhatsApp(
      order: order,
      settings: settings,
    );

    return order;
  }

  /// Cancel a PLACED order. Optimistically updates local state and syncs to Supabase.
  Future<bool> cancelOrder(String orderId) async {
    // Optimistic UI update
    final idx = _orders.indexWhere((o) => o.id == orderId);
    OrderModel? original;
    if (idx != -1 && _orders[idx].status.toUpperCase() == 'PLACED') {
      original = _orders[idx];
      final cancelled = OrderModel(
        id: original.id,
        deviceId: original.deviceId,
        userId: original.userId,
        customerName: original.customerName,
        customerPhone: original.customerPhone,
        deliveryAddress: original.deliveryAddress,
        items: original.items,
        subtotal: original.subtotal,
        deliveryFee: original.deliveryFee,
        total: original.total,
        status: 'CANCELLED',
        notes: original.notes,
        createdAt: original.createdAt,
      );
      _orders[idx] = cancelled;
      if (_activeTrackingOrder?.id == orderId) {
        _activeTrackingOrder = cancelled;
      }
      // Update local cache
      await StorageService.saveLocalOrder(cancelled);
      notifyListeners();
    } else {
      return false; // Not PLACED or not found
    }

    // Sync to Supabase
    final success = await SupabaseService.cancelOrder(orderId);
    if (!success) {
      // Roll back on failure
      _orders[idx] = original;
      if (_activeTrackingOrder?.id == orderId) {
        _activeTrackingOrder = original;
      }
      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _allOrdersSubscription?.cancel();
    super.dispose();
  }
}
