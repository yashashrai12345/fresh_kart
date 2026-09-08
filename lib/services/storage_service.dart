import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/app_constants.dart';
import '../models/order_model.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Device ID for anonymous customer tracking
  static Future<String> getDeviceId() async {
    _prefs ??= await SharedPreferences.getInstance();
    String? deviceId = _prefs?.getString(AppConstants.keyDeviceId);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await _prefs?.setString(AppConstants.keyDeviceId, deviceId);
    }
    return deviceId;
  }

  // Address, Phone, and Customer Name persistence
  static Future<void> saveCustomerDetails({
    required String name,
    required String phone,
    required String address,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(AppConstants.keySavedName, name);
    await _prefs?.setString(AppConstants.keySavedPhone, phone);
    await _prefs?.setString(AppConstants.keySavedAddress, address);
  }

  static String getSavedName() {
    return _prefs?.getString(AppConstants.keySavedName) ?? '';
  }

  static String getSavedPhone() {
    return _prefs?.getString(AppConstants.keySavedPhone) ?? '';
  }

  static String getSavedAddress() {
    return _prefs?.getString(AppConstants.keySavedAddress) ?? '';
  }

  // Local Orders Cache
  static Future<void> saveLocalOrder(OrderModel order) async {
    _prefs ??= await SharedPreferences.getInstance();
    List<OrderModel> orders = getLocalOrders();
    orders.removeWhere((o) => o.id == order.id);
    orders.insert(0, order);
    final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs?.setString(AppConstants.keyOrders, raw);
  }

  static List<OrderModel> getLocalOrders() {
    final raw = _prefs?.getString(AppConstants.keyOrders);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((i) => OrderModel.fromJson(i as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // Wishlist
  static Future<void> toggleWishlist(String productId) async {
    _prefs ??= await SharedPreferences.getInstance();
    List<String> list = getWishlist();
    if (list.contains(productId)) {
      list.remove(productId);
    } else {
      list.add(productId);
    }
    await _prefs?.setStringList(AppConstants.keyWishlist, list);
  }

  static List<String> getWishlist() {
    return _prefs?.getStringList(AppConstants.keyWishlist) ?? [];
  }
}
