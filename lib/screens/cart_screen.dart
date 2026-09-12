import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/store_provider.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/free_delivery_banner.dart';
import 'order_tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLocating = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = StorageService.getSavedName();
    // Pre-fill phone from Supabase auth user if available, else from saved prefs
    final authPhone = context.read<AuthProvider>().currentUserPhoneShort;
    _phoneController.text = authPhone.isNotEmpty
        ? authPhone
        : StorageService.getSavedPhone();
    _addressController.text = StorageService.getSavedAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final address = await LocationService.getCurrentAddress();
      if (address != null && mounted) {
        setState(() {
          _addressController.text = address;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address fetched from GPS location!'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch location: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _handleWhatsAppCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    final store = context.read<StoreProvider>();
    final orderProv = context.read<OrderProvider>();

    if (store.settings.isMaintenanceMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(store.settings.maintenanceMessage.isNotEmpty
              ? store.settings.maintenanceMessage
              : 'Store ordering is currently paused for maintenance.'),
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final placedOrder = await orderProv.placeOrder(
        cartItems: cart.itemList,
        customerName: _nameController.text.trim().isEmpty
            ? 'Customer'
            : _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        notes: _notesController.text.trim(),
        settings: store.settings,
      );

      // Clear the cart
      cart.clearCart();

      if (mounted) {
        // Navigate directly to live order tracking screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: placedOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final store = context.watch<StoreProvider>();

    final subtotal = cart.subtotal;
    final threshold = store.freeDeliveryThreshold;
    final deliveryFee = cart.getDeliveryFee(threshold, store.deliveryFee);
    final grandTotal = cart.getGrandTotal(threshold, store.deliveryFee);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fresh Basket'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => cart.clearCart(),
              child: const Text('Clear', style: TextStyle(color: AppTheme.danger)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_basket_outlined,
                        size: 44, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Your Fresh Basket is Empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Browse farm-fresh vegetables and fruits to add!',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Explore Fresh Produce'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  // Free delivery progress banner
                  FreeDeliveryBanner(
                    subtotal: subtotal,
                    threshold: threshold,
                  ),

                  const SizedBox(height: 16),

                  // Line items card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.itemList.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, idx) {
                        final item = cart.itemList[idx];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Photo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: item.product.photoUrl,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 160,
                                  memCacheHeight: 160,
                                  fadeInDuration: const Duration(milliseconds: 100),
                                  placeholder: (_, __) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.image_outlined,
                                        size: 18, color: Color(0xFFCBD5E1)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pack: ${item.portionLabel} • ₹${item.unitPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${item.subtotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Stepper
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          cart.decrement(item.cartKey),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Icon(Icons.remove, size: 14),
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          cart.increment(item.cartKey),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        child: Icon(Icons.add, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Customer Contact & Delivery Address
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: AppTheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delivery Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your Name (Optional)',
                            prefixIcon: Icon(Icons.person_outline, size: 18),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: Icon(Icons.phone_outlined, size: 18),
                            prefixText: '+91 ',
                            counterText: '', // hide the "0/10" counter
                          ),
                          validator: (value) {
                            final clean =
                                (value ?? '').replaceAll(RegExp(r'\D'), '');
                            if (clean.length != 10) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Address + GPS Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Delivery Address *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isLocating
                                  ? null
                                  : _handleUseCurrentLocation,
                              icon: _isLocating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.my_location_rounded,
                                      size: 15),
                              label: const Text(
                                'Use GPS Location',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Flat / House No., Apartment name, Street, Locality, Landmark...',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Please enter your complete delivery address';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Delivery instructions
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Instructions (Optional)',
                            hintText: 'e.g. Ring bell twice, leave at gate...',
                            prefixIcon:
                                Icon(Icons.edit_note_outlined, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bill Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment & Bill Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items Subtotal',
                                style: TextStyle(color: AppTheme.textMuted)),
                            Text('₹${subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee',
                                style: TextStyle(color: AppTheme.textMuted)),
                            Text(
                              deliveryFee == 0
                                  ? 'FREE'
                                  : '₹${deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: deliveryFee == 0
                                    ? AppTheme.success
                                    : AppTheme.textMain,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppTheme.borderLight),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'To Pay (Cash/UPI on Delivery)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '₹${grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // Bottom Bar with "Order on WhatsApp" Button
      bottomSheet: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: AppTheme.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (store.settings.isMaintenanceMode) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.construction_rounded,
                              color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.settings.maintenanceTitle.isNotEmpty
                                      ? store.settings.maintenanceTitle
                                      : 'Store Under Maintenance',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  store.settings.maintenanceMessage.isNotEmpty
                                      ? store.settings.maintenanceMessage
                                      : 'Ordering is temporarily paused.',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                if (store.settings.formattedMaintenanceResume
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Resuming: ${store.settings.formattedMaintenanceResume}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Cash on Delivery / UPI upon inspection at doorstep',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isPlacingOrder || store.settings.isMaintenanceMode)
                          ? null
                          : _handleWhatsAppCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: store.settings.isMaintenanceMode
                            ? Colors.grey.shade400
                            : const Color(0xFF25D366), // WhatsApp Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  store.settings.isMaintenanceMode
                                      ? Icons.block_rounded
                                      : Icons.chat_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  store.settings.isMaintenanceMode
                                      ? 'Ordering Paused (Maintenance)'
                                      : 'Order on WhatsApp • ₹${grandTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
