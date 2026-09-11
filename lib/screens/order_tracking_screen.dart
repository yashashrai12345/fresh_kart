import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../providers/store_provider.dart';
import '../services/whatsapp_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  Future<void> _confirmCancelOrder(
      BuildContext context, OrderProvider orderProv, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await orderProv.cancelOrder(orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Order cancelled successfully.'
                  : 'Could not cancel order. Please try again.',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  static const List<Map<String, dynamic>> _steps = [
    {
      'title': 'Order Placed',
      'subtitle': 'Order details sent via WhatsApp and confirmed',
      'icon': Icons.receipt_long_rounded,
    },
    {
      'title': 'Confirmed at Mandi',
      'subtitle': 'Reserved from daily fresh APMC arrival',
      'icon': Icons.thumb_up_alt_rounded,
    },
    {
      'title': 'Packed & Weighed',
      'subtitle': 'Triple-cleaned, weighed, and packed in eco-pouches',
      'icon': Icons.inventory_2_rounded,
    },
    {
      'title': 'Out for Delivery',
      'subtitle': 'Rider dispatched to your address',
      'icon': Icons.two_wheeler_rounded,
    },
    {
      'title': 'Delivered',
      'subtitle': 'Delivered fresh at your doorstep',
      'icon': Icons.check_circle_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();
    final store = context.watch<StoreProvider>();

    // Current live order state (from provider if matching, or passed order)
    final currentOrder = (orderProv.activeTrackingOrder?.id == order.id)
        ? orderProv.activeTrackingOrder!
        : (orderProv.orders.firstWhere(
            (o) => o.id == order.id,
            orElse: () => order,
          ));

    final currentStep = currentOrder.statusStepIndex;
    final isCancelled = currentOrder.status.toUpperCase() == 'CANCELLED';
    final isPlaced = currentOrder.status.toUpperCase() == 'PLACED';

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${currentOrder.id}'),
        actions: [
          if (!isCancelled)
            IconButton(
              onPressed: () {
                WhatsAppService.launchWhatsAppChat(
                  phoneNumber: store.settings.whatsappNumber,
                  prefilledMessage:
                      'Hi Fresh Kart! I am checking on my order #${currentOrder.id}.',
                );
              },
              icon: const Icon(Icons.support_agent_rounded,
                  color: AppTheme.primary),
              tooltip: 'Support Chat',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Order Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCancelled
                    ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]
                    : [const Color(0xFF064E3B), const Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isCancelled ? AppTheme.danger : AppTheme.primaryDark)
                      .withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Order #${currentOrder.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '₹${currentOrder.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (isCancelled) ...[
                  const Row(
                    children: [
                      Icon(Icons.cancel_rounded,
                          color: Color(0xFFFCA5A5), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Order Cancelled',
                        style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This order has been cancelled.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Estimated Morning Delivery',
                    style:
                        TextStyle(color: Color(0xFFA7F3D0), fontSize: 12),
                  ),
                  const Text(
                    'Tomorrow • 6:00 AM – 9:00 AM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cancelled Banner (replaces timeline)
          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_outlined,
                        color: AppTheme.danger, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Cancelled',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.danger,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'No charges have been applied. If you paid online, a refund will be processed within 3–5 business days.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 5-Stage Live Status Timeline Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Live Delivery Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle,
                                size: 8, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text(
                              'Live Sync',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stepper Items
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _steps.length,
                    itemBuilder: (context, idx) {
                      final isCompleted = idx <= currentStep;
                      final isCurrent = idx == currentStep;
                      final stepData = _steps[idx];

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Indicator + Vertical Line
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? AppTheme.primary
                                      : const Color(0xFFF1F5F9),
                                  border: isCurrent
                                      ? Border.all(
                                          color: AppTheme.accentWarm,
                                          width: 2)
                                      : null,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primary
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  stepData['icon'] as IconData,
                                  size: 18,
                                  color: isCompleted
                                      ? Colors.white
                                      : AppTheme.textLight,
                                ),
                              ),
                              if (idx < _steps.length - 1)
                                Container(
                                  width: 2,
                                  height: 42,
                                  color: isCompleted && idx < currentStep
                                      ? AppTheme.primary
                                      : AppTheme.border,
                                ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          // Text Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stepData['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: isCompleted
                                          ? AppTheme.textMain
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stepData['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCompleted
                                          ? AppTheme.textMuted
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Order Items Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 14),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentOrder.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 16, color: AppTheme.borderLight),
                  itemBuilder: (context, idx) {
                    final itm = currentOrder.items[idx];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${itm.name} x ${itm.qty}${itm.portion != null ? ' (${itm.portion})' : ''}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${itm.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const Divider(height: 24, color: AppTheme.border),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal',
                        style: TextStyle(color: AppTheme.textMuted)),
                    Text('₹${currentOrder.subtotal.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Fee',
                        style: TextStyle(color: AppTheme.textMuted)),
                    Text(
                      currentOrder.deliveryFee == 0
                          ? 'FREE'
                          : '₹${currentOrder.deliveryFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: currentOrder.deliveryFee == 0
                            ? AppTheme.success
                            : AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '₹${currentOrder.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Destination Address Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentOrder.deliveryAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Cancel Order button — only for PLACED orders
          if (isPlaced) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _confirmCancelOrder(context, orderProv, currentOrder.id),
                icon: const Icon(Icons.cancel_outlined,
                    size: 18, color: AppTheme.danger),
                label: const Text(
                  'Cancel This Order',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppTheme.danger, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
