import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/store_settings_model.dart';
import 'storage_service.dart';

class SupabaseService {
  static bool _initialized = false;
  static SupabaseClient? _client;

  static SupabaseClient? get client => _client;
  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (AppConstants.isSupabaseConfigured) {
      try {
        String cleanUrl = AppConstants.supabaseUrl.trim();
        if (cleanUrl.endsWith('/rest/v1/')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - '/rest/v1/'.length);
        } else if (cleanUrl.endsWith('/rest/v1')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - '/rest/v1'.length);
        }
        if (cleanUrl.endsWith('/')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
        }

        await Supabase.initialize(
          url: cleanUrl,
          anonKey: AppConstants.supabaseAnonKey.trim(),
        );
        _client = Supabase.instance.client;
        _initialized = true;
        debugPrint('Supabase successfully initialized with $cleanUrl.');
      } catch (e) {
        debugPrint('Supabase init failed, falling back to local store: $e');
        _initialized = false;
      }
    } else {
      debugPrint('Supabase credentials not configured; running with Local APMC Store.');
      _initialized = false;
    }
  }

  // ── Convenience getter for the current authenticated user ────────────────

  static String? get currentUserId => _client?.auth.currentUser?.id;

  // ── CATALOG DATA (Categories & Products) ─────────────────────────────────

  static Future<List<CategoryModel>> getCategories() async {
    if (_initialized && _client != null) {
      try {
        final data = await _client!
            .from('categories')
            .select()
            .eq('is_active', true)
            .order('sort_order', ascending: true);
        return (data as List)
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error fetching categories from Supabase: $e');
      }
    }
    return _localCategories;
  }

  static Future<List<ProductModel>> getProducts() async {
    if (_initialized && _client != null) {
      try {
        final data = await _client!
            .from('products')
            .select()
            .order('sort_order', ascending: true);
        return (data as List)
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error fetching products from Supabase: $e');
      }
    }
    return _localProducts;
  }

  static Future<StoreSettingsModel> getStoreSettings() async {
    if (_initialized && _client != null) {
      try {
        final data = await _client!
            .from('store_settings')
            .select()
            .limit(1)
            .maybeSingle();
        if (data != null) {
          return StoreSettingsModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Error fetching store settings: $e');
      }
    }
    return const StoreSettingsModel();
  }

  // ── ORDERS ────────────────────────────────────────────────────────────────

  static Future<void> createOrder(OrderModel order) async {
    // 1. Always save locally first so user never loses order history
    await StorageService.saveLocalOrder(order);

    // 2. Sync to Supabase if connected
    if (_initialized && _client != null) {
      try {
        final payload = {
          'id': order.id,
          'device_id': order.deviceId,
          'customer_name': order.customerName,
          'customer_phone': order.customerPhone,
          'delivery_address': order.deliveryAddress,
          'items': order.items.map((i) => i.toJson()).toList(),
          'subtotal': order.subtotal,
          'delivery_fee': order.deliveryFee,
          'total': order.total,
          'status': order.status,
          'notes': order.notes,
          'whatsapp_sent': true,
        };
        // Include user_id if authenticated
        if (order.userId != null) {
          payload['user_id'] = order.userId!;
        }
        await _client!.from('orders').insert(payload);
      } catch (e) {
        debugPrint('Error syncing order to Supabase: $e');
      }
    }
  }

  /// Fetch orders for an authenticated user (primary method post-auth)
  static Future<List<OrderModel>> getOrdersForUser(String userId) async {
    if (_initialized && _client != null) {
      try {
        final data = await _client!
            .from('orders')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return (data as List)
            .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error fetching user orders from Supabase: $e');
      }
    }
    return StorageService.getLocalOrders();
  }

  /// Legacy: fetch orders by device_id (fallback for unauthenticated users)
  static Future<List<OrderModel>> getOrdersForDevice(String deviceId) async {
    if (_initialized && _client != null) {
      try {
        final data = await _client!
            .from('orders')
            .select()
            .eq('device_id', deviceId)
            .order('created_at', ascending: false);
        return (data as List)
            .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Error fetching orders from Supabase: $e');
      }
    }
    return StorageService.getLocalOrders();
  }

  // Realtime subscription for a single order (used on tracking screen)
  static Stream<OrderModel>? subscribeToOrder(String orderId) {
    if (_initialized && _client != null) {
      return _client!
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('id', orderId)
          .where((list) => list.isNotEmpty)
          .map((list) => OrderModel.fromJson(list.first));
    }
    return null;
  }

  // Realtime subscription for all orders of a user
  static Stream<List<OrderModel>>? subscribeToUserOrders(String userId) {
    if (_initialized && _client != null) {
      return _client!
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((list) => list.map((o) => OrderModel.fromJson(o)).toList());
    }
    return null;
  }

  // Legacy: Realtime for device-based orders (backward compat)
  static Stream<List<OrderModel>>? subscribeToDeviceOrders(String deviceId) {
    if (_initialized && _client != null) {
      return _client!
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .map((list) => list
              .map((o) => OrderModel.fromJson(o))
              .toList());
    }
    return null;
  }

  // Realtime subscription for products catalog (admin stock/price changes reflect immediately)
  static Stream<List<ProductModel>>? subscribeToProducts() {
    if (_initialized && _client != null) {
      return _client!
          .from('products')
          .stream(primaryKey: ['id'])
          .order('sort_order', ascending: true)
          .map((list) => list
              .map((p) => ProductModel.fromJson(p))
              .toList());
    }
    return null;
  }

  // ── WISHLIST (Supabase-backed when authenticated) ─────────────────────────

  /// Fetch user wishlist product IDs from Supabase
  static Future<List<String>> getWishlistForUser(String userId) async {
    if (_initialized && _client != null) {
      try {
        final data = await _client!
            .from('wishlist')
            .select('product_id')
            .eq('user_id', userId);
        return (data as List)
            .map((w) => w['product_id'] as String)
            .toList();
      } catch (e) {
        debugPrint('Error fetching wishlist from Supabase: $e');
      }
    }
    return [];
  }

  /// Add a product to the user's wishlist in Supabase
  static Future<void> addToWishlist(String userId, String productId) async {
    if (_initialized && _client != null) {
      try {
        await _client!.from('wishlist').upsert({
          'user_id': userId,
          'product_id': productId,
        });
      } catch (e) {
        debugPrint('Error adding to wishlist: $e');
      }
    }
  }

  /// Remove a product from the user's wishlist in Supabase
  static Future<void> removeFromWishlist(String userId, String productId) async {
    if (_initialized && _client != null) {
      try {
        await _client!
            .from('wishlist')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      } catch (e) {
        debugPrint('Error removing from wishlist: $e');
      }
    }
  }

  // ── Initial Local APMC Catalog Data ──────────────────────────────────────

  static final List<CategoryModel> _localCategories = [
    const CategoryModel(id: 'cat_veg', name: 'Fresh Vegetables', slug: 'vegetables', icon: 'carrot', sortOrder: 1),
    const CategoryModel(id: 'cat_greens', name: 'Leafy Greens & Herbs', slug: 'leafy-greens', icon: 'sprout', sortOrder: 2),
    const CategoryModel(id: 'cat_fruits', name: 'Fresh Fruits', slug: 'fruits', icon: 'apple', sortOrder: 3),
    const CategoryModel(id: 'cat_combos', name: 'Value Combo Packs', slug: 'combo-packs', icon: 'shopping-bag', sortOrder: 4),
  ];

  static final List<ProductModel> _localProducts = [
    // Vegetables
    const ProductModel(
      id: 'prod_tomato_hybrid',
      categoryId: 'cat_veg',
      name: 'Farm Fresh Hybrid Tomatoes',
      description: 'Firm, juicy, ruby-red farm tomatoes ideal for daily curries, gravies, and fresh salads.',
      price: 32,
      mrp: 45,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.8,
      reviewCount: 128,
      sortOrder: 1,
    ),
    const ProductModel(
      id: 'prod_onion_nasik',
      categoryId: 'cat_veg',
      name: 'Nasik Red Onions',
      description: 'Crisp, pungently flavorful grade-A red onions sourced directly from the Nasik hub.',
      price: 38,
      mrp: 52,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.9,
      reviewCount: 210,
      sortOrder: 2,
    ),
    const ProductModel(
      id: 'prod_potato_hassan',
      categoryId: 'cat_veg',
      name: 'Hassan Gold Potatoes',
      description: 'Thin-skinned, clean earthen potatoes. Starchy and fluffy when cooked, perfect for roasting & boiling.',
      price: 29,
      mrp: 40,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.7,
      reviewCount: 185,
      sortOrder: 3,
    ),
    const ProductModel(
      id: 'prod_bhindi_ladyfinger',
      categoryId: 'cat_veg',
      name: 'Tender Green Bhindi (Okra)',
      description: 'Crisp, snap-tender baby okras picked before sunrise. Non-slimy and cooks evenly.',
      price: 42,
      mrp: 60,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1604544203292-0ec5a1b32d56?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      stockLeft: 8,
      rating: 4.9,
      reviewCount: 94,
      sortOrder: 4,
    ),
    const ProductModel(
      id: 'prod_cauliflower',
      categoryId: 'cat_veg',
      name: 'Snow White Cauliflower',
      description: 'Tight, clean white curd with fresh outer green leaves intact preserving moisture.',
      price: 35,
      mrp: 50,
      unit: '/pc',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.6,
      reviewCount: 76,
      sortOrder: 5,
    ),
    const ProductModel(
      id: 'prod_capsicum_green',
      categoryId: 'cat_veg',
      name: 'Crisp Green Capsicum',
      description: 'Glossy thick-walled green bell peppers with a fresh sweet crunch.',
      price: 55,
      mrp: 75,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.8,
      reviewCount: 62,
      sortOrder: 6,
    ),
    const ProductModel(
      id: 'prod_carrot_ooty',
      categoryId: 'cat_veg',
      name: 'Ooty Red Carrots',
      description: 'Sweet, deep-orange farm-washed hill carrots loaded with carotene and natural crunch.',
      price: 48,
      mrp: 65,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.8,
      reviewCount: 89,
      sortOrder: 7,
    ),
    const ProductModel(
      id: 'prod_cucumber_salad',
      categoryId: 'cat_veg',
      name: 'Crisp Salad Cucumber',
      description: 'Cool, refreshing hydrating field cucumbers with tender seeds and delicate skin.',
      price: 30,
      mrp: 42,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.7,
      reviewCount: 53,
      sortOrder: 8,
    ),

    // Leafy Greens & Herbs
    const ProductModel(
      id: 'prod_palak_spinach',
      categoryId: 'cat_greens',
      name: 'Tender Farm Palak (Spinach)',
      description: 'Hydro-cleaned broad dark green spinach bunches rich in iron and dietary fiber.',
      price: 24,
      mrp: 35,
      unit: '/bunch',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.9,
      reviewCount: 145,
      sortOrder: 9,
    ),
    const ProductModel(
      id: 'prod_coriander_bunch',
      categoryId: 'cat_greens',
      name: 'Aromatic Country Coriander',
      description: 'Fragrant local desi coriander with fresh roots intact for long lasting aroma.',
      price: 15,
      mrp: 22,
      unit: '/bunch',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1589135233689-d56d7870636f?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.9,
      reviewCount: 230,
      sortOrder: 10,
    ),
    const ProductModel(
      id: 'prod_methi_leaves',
      categoryId: 'cat_greens',
      name: 'Fresh Desi Methi (Fenugreek)',
      description: 'Small-leafed aromatic fenugreek with authentic bittersweet flavor profile.',
      price: 22,
      mrp: 32,
      unit: '/bunch',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1628773822503-930a84d436a5?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      stockLeft: 4,
      rating: 4.7,
      reviewCount: 72,
      sortOrder: 11,
    ),

    // Fruits
    const ProductModel(
      id: 'prod_banana_robusta',
      categoryId: 'cat_fruits',
      name: 'Robusta Sweet Bananas',
      description: 'Naturally ripened, energizing sweet Cavendish bananas without carbide treatment.',
      price: 46,
      mrp: 60,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.8,
      reviewCount: 178,
      sortOrder: 12,
    ),
    const ProductModel(
      id: 'prod_mango_alphonso',
      categoryId: 'cat_fruits',
      name: 'Devgad Alphonso Mangoes (GI Tag)',
      description: 'The undisputed king of mangoes. Intensely fragrant, saffron pulp, zero fiber.',
      price: 380,
      mrp: 500,
      unit: '/kg',
      dietTag: 'limited',
      photoUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      stockLeft: 6,
      rating: 5.0,
      reviewCount: 92,
      sortOrder: 13,
    ),
    const ProductModel(
      id: 'prod_apple_shimla',
      categoryId: 'cat_fruits',
      name: 'Kinnaur Royal Apples',
      description: 'Crisp, sweet-tart Himalayan apples with natural red blush and superior crunch.',
      price: 140,
      mrp: 180,
      unit: '/kg',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.7,
      reviewCount: 134,
      sortOrder: 14,
    ),

    // Combos
    const ProductModel(
      id: 'prod_combo_kitchen_essentials',
      categoryId: 'cat_combos',
      name: 'Daily Kitchen Staples Basket',
      description: 'Includes 1kg Onions, 1kg Potatoes, 1kg Hybrid Tomatoes, and 100g Ginger + Chillies.',
      price: 129,
      mrp: 175,
      unit: '/pack',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.9,
      reviewCount: 312,
      sortOrder: 15,
    ),
    const ProductModel(
      id: 'prod_combo_greens_immunity',
      categoryId: 'cat_combos',
      name: 'Immunity Green Leafy Trio',
      description: 'Fresh combo bundle containing 2 Palak bunches, 1 Methi bunch, and 1 aromatic Mint bunch.',
      price: 65,
      mrp: 95,
      unit: '/pack',
      dietTag: 'veg',
      photoUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&auto=format&fit=crop&q=80',
      inStock: true,
      rating: 4.9,
      reviewCount: 140,
      sortOrder: 16,
    ),
  ];
}
