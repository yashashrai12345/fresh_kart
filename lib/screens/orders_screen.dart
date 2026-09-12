import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      context.read<OrderProvider>().loadOrders(userId: userId);
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch (status.toUpperCase()) {
      case 'PLACED':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        break;
      case 'CONFIRMED':
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0369A1);
        break;
      case 'PACKED':
        bg = const Color(0xFFF3E8FF);
        text = const Color(0xFF6B21A8);
        break;
      case 'OUT_FOR_DELIVERY':
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFF9A3412);
        break;
      case 'DELIVERED':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF166534);
        break;
      case 'CANCELLED':
        bg = AppTheme.dangerLight;
        text = AppTheme.danger;
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Future<void> _confirmCancelOrder(
      BuildContext context, OrderProvider orderProv, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Past Orders'),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          final userId = context.read<AuthProvider>().currentUser?.id;
          return orderProv.loadOrders(userId: userId);
        },
        child: orderProv.isLoading
            ? const Center(child: CircularProgressIndicator())
            : orderProv.orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              size: 40, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Orders Placed Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Orders you place will show live tracking here.',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProv.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final order = orderProv.orders[idx];
                      final isPlaced =
                          order.status.toUpperCase() == 'PLACED';
                      final isCancelled =
                          order.status.toUpperCase() == 'CANCELLED';

                      return GestureDetector(
                        onTap: isCancelled
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderTrackingScreen(order: order),
                                  ),
                                );
                              },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCancelled
                                  ? AppTheme.dangerLight
                                  : AppTheme.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order.id}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isCancelled
                                          ? AppTheme.textMuted
                                          : AppTheme.primaryDark,
                                    ),
                                  ),
                                  _buildStatusBadge(order.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${order.items.length} items • ₹${order.total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isCancelled
                                      ? AppTheme.textLight
                                      : AppTheme.textMain,
                                  decoration: isCancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.formattedCreatedAt,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const Divider(
                                  height: 20, color: AppTheme.borderLight),
                              if (isCancelled) ...[
                                // Cancelled order footer
                                Row(
                                  children: const [
                                    Icon(Icons.cancel_outlined,
                                        size: 14, color: AppTheme.danger),
                                    SizedBox(width: 6),
                                    Text(
                                      'This order was cancelled',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'View Live Status & Items',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 18, color: AppTheme.primary),
                                  ],
                                ),
                                // Cancel button — only for PLACED orders
                                if (isPlaced) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _confirmCancelOrder(
                                          context, orderProv, order.id),
                                      icon: const Icon(
                                          Icons.cancel_outlined,
                                          size: 16,
                                          color: AppTheme.danger),
                                      label: const Text(
                                        'Cancel Order',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.danger,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AppTheme.danger,
                                            width: 1.2),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
