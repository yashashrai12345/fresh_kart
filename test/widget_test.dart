import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_kart/models/order_model.dart';
import 'package:fresh_kart/models/product_model.dart';
import 'package:fresh_kart/models/store_settings_model.dart';
import 'package:fresh_kart/providers/auth_provider.dart';
import 'package:fresh_kart/providers/cart_provider.dart';
import 'package:fresh_kart/services/whatsapp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fresh Kart Cart & Checkout Tests', () {
    const testTomato = ProductModel(
      id: 'test_tomato',
      categoryId: 'cat_veg',
      name: 'Farm Fresh Tomatoes',
      price: 32.0,
      mrp: 45.0,
      unit: '/kg',
      photoUrl: '',
    );

    const testSpinach = ProductModel(
      id: 'test_spinach',
      categoryId: 'cat_greens',
      name: 'Fresh Spinach',
      price: 24.0,
      mrp: 35.0,
      unit: '/bunch',
      photoUrl: '',
    );

    test('Cart accurately calculates subtotal and portion multipliers', () {
      final cart = CartProvider();

      // Add 2kg tomatoes (1kg * 2) = 64
      cart.addItem(
        product: testTomato,
        portionLabel: '1 kg',
        portionMultiplier: 1.0,
        quantity: 2,
      );

      // Add 1 bunch of spinach = 24
      cart.addItem(
        product: testSpinach,
        portionLabel: '1 bunch',
        portionMultiplier: 1.0,
        quantity: 1,
      );

      expect(cart.itemCount, 2);
      expect(cart.totalUnitsCount, 3);
      expect(cart.subtotal, 88.0);
    });

    test('Free delivery threshold logic works as specified (free above ₹250)', () {
      final cart = CartProvider();
      const threshold = 250.0;
      const flatFee = 30.0;

      // Subtotal 0 -> 0 fee
      expect(cart.getDeliveryFee(threshold, flatFee), 0.0);

      // Add item worth 100
      cart.addItem(
        product: testTomato,
        quantity: 3, // 3 * 32 = 96
      );
      expect(cart.getDeliveryFee(threshold, flatFee), flatFee);
      expect(cart.getRemainingForFreeDelivery(threshold), 250.0 - 96.0);
      expect(cart.isFreeDeliveryUnlocked(threshold), false);

      // Add 5 more items worth 160 (total 256 >= 250)
      cart.addItem(
        product: testTomato,
        quantity: 5, // 5 * 32 = 160 -> Total 256
      );
      expect(cart.isFreeDeliveryUnlocked(threshold), true);
      expect(cart.getDeliveryFee(threshold, flatFee), 0.0);
      expect(cart.getRemainingForFreeDelivery(threshold), 0.0);
      expect(cart.getGrandTotal(threshold, flatFee), 256.0);
    });

    test('WhatsApp message builder formats itemized text matching specification', () {
      final order = OrderModel(
        id: 'FK-9999',
        deviceId: 'device_test',
        customerName: 'Aarav Patel',
        customerPhone: '8970050327',
        deliveryAddress: 'Flat 102, Green Meadows, Indiranagar',
        items: [
          OrderItemSummary(
            productId: 'test_tomato',
            name: 'Farm Fresh Tomatoes',
            qty: 2,
            portion: '1 kg',
            unit: '/kg',
            unitPrice: 32.0,
            subtotal: 64.0,
          ),
          OrderItemSummary(
            productId: 'test_spinach',
            name: 'Fresh Spinach',
            qty: 1,
            portion: '1 bunch',
            unit: '/bunch',
            unitPrice: 24.0,
            subtotal: 24.0,
          ),
        ],
        subtotal: 88.0,
        deliveryFee: 30.0,
        total: 118.0,
        status: 'PLACED',
        createdAt: DateTime.now(),
      );

      const settings = StoreSettingsModel(
        whatsappNumber: '918970050327',
        freeDeliveryThreshold: 250.0,
      );

      final message = WhatsAppService.buildOrderMessage(
        order: order,
        settings: settings,
      );

      expect(message.contains('*GREEN BASKET ORDER* (#FK-9999)'), isTrue);
      expect(message.contains('Farm Fresh Tomatoes x 2 (1 kg) - ₹64'), isTrue);
      expect(message.contains('Fresh Spinach x 1 (1 bunch) - ₹24'), isTrue);
      expect(message.contains('Items Total: ₹88'), isTrue);
      expect(message.contains('Delivery Fee: ₹30'), isTrue);
      expect(message.contains('*Grand Total: ₹118*'), isTrue);
      expect(message.contains('Flat 102, Green Meadows, Indiranagar'), isTrue);
      expect(message.contains('8970050327'), isTrue);
      expect(message.contains('Please confirm my order!'), isTrue);
    });
  });

  group('Fresh Kart AuthProvider Tests', () {
    test('AuthProvider initializes safely without crashing', () {
      final auth = AuthProvider();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.isLoading, isFalse);
      expect(auth.isGoogleLoading, isFalse);
      expect(auth.currentUserName, 'Customer');
      expect(auth.currentUserEmail, isEmpty);
      expect(auth.currentUserPhone, isEmpty);
    });

    test('AuthProvider gracefully reports error when Supabase client is unconfigured', () async {
      final auth = AuthProvider();
      final googleResult = await auth.signInWithGoogle();
      expect(googleResult, isFalse);
      expect(auth.errorMessage, isNotNull);

      final otpResult = await auth.sendOTP('9876543210');
      expect(otpResult, isFalse);

      final verifyResult = await auth.verifyOTP('9876543210', '123456');
      expect(verifyResult, isFalse);
    });
  });
}

