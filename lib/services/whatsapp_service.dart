import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../models/store_settings_model.dart';

class WhatsAppService {
  /// Builds the formatted itemized order message matching the PRD specification
  static String buildOrderMessage({
    required OrderModel order,
    required StoreSettingsModel settings,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 *FRESH KART ORDER* (#${order.id})');
    buffer.writeln('-----------------------------');

    for (final item in order.items) {
      final portionText =
          (item.portion != null && item.portion!.isNotEmpty) ? ' (${item.portion})' : '';
      buffer.writeln('• ${item.name} x ${item.qty}$portionText - ₹${item.subtotal.toStringAsFixed(0)}');
    }

    buffer.writeln('-----------------------------');
    buffer.writeln('Items Total: ₹${order.subtotal.toStringAsFixed(0)}');

    if (order.deliveryFee == 0) {
      buffer.writeln(
          'Delivery Fee: FREE (Order > ₹${settings.freeDeliveryThreshold.toStringAsFixed(0)})');
    } else {
      buffer.writeln('Delivery Fee: ₹${order.deliveryFee.toStringAsFixed(0)}');
    }

    buffer.writeln('*Grand Total: ₹${order.total.toStringAsFixed(0)}*');
    buffer.writeln('');
    buffer.writeln('📍 *Delivery Address:*');
    buffer.writeln(order.deliveryAddress);
    buffer.writeln('📞 *Phone:* ${order.customerPhone}');

    if (order.notes != null && order.notes!.trim().isNotEmpty) {
      buffer.writeln('📝 *Notes:* ${order.notes}');
    }

    buffer.writeln('-----------------------------');
    buffer.writeln('Please confirm my order! Cash / UPI on Delivery.');

    return buffer.toString();
  }

  /// Launches WhatsApp with the pre-filled order message
  static Future<bool> sendOrderOnWhatsApp({
    required OrderModel order,
    required StoreSettingsModel settings,
  }) async {
    final message = buildOrderMessage(order: order, settings: settings);
    return launchWhatsAppChat(
      phoneNumber: settings.whatsappNumber,
      prefilledMessage: message,
    );
  }

  /// General helper to open WhatsApp chat with support or order desk
  static Future<bool> launchWhatsAppChat({
    required String phoneNumber,
    String? prefilledMessage,
  }) async {
    // Sanitize phone number (strip spaces, symbols, plus)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final query = prefilledMessage != null
        ? '?text=${Uri.encodeComponent(prefilledMessage)}'
        : '';
    final uri = Uri.parse('https://wa.me/$cleanNumber$query');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched;
    } catch (e) {
      debugPrint('WhatsApp Launch Error: $e');
      return false;
    }
  }
}
