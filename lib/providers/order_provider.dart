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

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final deviceId = await StorageService.getDeviceId();
      _orders = await SupabaseService.getOrdersForDevice(deviceId);
      // Start a live subscription to all this device's orders so that
      // any admin status change is reflected immediately in the app.
      _startAllOrdersSubscription(deviceId);
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Subscribe to live updates for every order belonging to this device.
  void _startAllOrdersSubscription(String deviceId) {
    _allOrdersSubscription?.cancel();
    final stream = SupabaseService.subscribeToDeviceOrders(deviceId);
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

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _allOrdersSubscription?.cancel();
    super.dispose();
  }
}
