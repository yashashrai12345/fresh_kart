import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/order_provider.dart';
import '../providers/store_provider.dart';
import '../providers/wishlist_provider.dart';
import '../widgets/category_chips_bar.dart';
import '../widgets/floating_cart_bar.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'product_detail_sheet.dart';
import 'store_info_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      context.read<StoreProvider>().loadSettings();
      context.read<CatalogProvider>().loadCatalog();
      context.read<OrderProvider>().loadOrders(userId: userId);
      context.read<WishlistProvider>().init(userId: userId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final store = context.watch<StoreProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final orderProv = context.watch<OrderProvider>();

    // Full-screen Maintenance Mode Lockout (if browsing is not allowed)
    if (store.settings.isMaintenanceMode && !store.settings.maintenanceAllowBrowsing) {
      return Scaffold(
        backgroundColor: AppTheme.bgMain,
        appBar: AppBar(
          title: Text(store.settings.name),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => store.loadSettings(),
              tooltip: 'Refresh Status',
            )
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                    ),
                    child: const Icon(Icons.construction_rounded,
                        size: 36, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Text(
                      'STORE UNDER MAINTENANCE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    store.settings.maintenanceTitle.isNotEmpty
                        ? store.settings.maintenanceTitle
                        : 'Store Under Maintenance',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    store.settings.maintenanceMessage.isNotEmpty
                        ? store.settings.maintenanceMessage
                        : 'We are restocking fresh vegetables and upgrading our systems to serve you better. We will be right back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  if (store.settings.formattedMaintenanceResume.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated Reopening',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                Text(
                                  store.settings.formattedMaintenanceResume,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await store.loadSettings();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Store status refreshed!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Check If Reopened'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final products = catalog.filteredProducts;

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  catalog.loadCatalog(),
                  store.loadSettings(),
                ]);
              },
              child: CustomScrollView(
                slivers: [
                  // Hero Header with Brand & Action Icons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          // Brand Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/logo/fresh_kart_icon.jpg',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primary, AppTheme.primaryDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.shopping_basket_rounded,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Brand Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.settings.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                Text(
                                  store.settings.tagline,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons: Wishlist, Orders, Store Info
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WishlistScreen(),
                                ),
                              );
                            },
                            icon: Badge(
                              isLabelVisible: wishlist.wishlistIds.isNotEmpty,
                              label: Text('${wishlist.wishlistIds.length}'),
                              backgroundColor: AppTheme.danger,
                              child: const Icon(Icons.favorite_outline_rounded,
                                  size: 22),
                            ),
                            tooltip: 'Wishlist',
                          ),

                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrdersScreen(),
                                ),
                              );
                            },
                            icon: Badge(
                              isLabelVisible: orderProv.orders.isNotEmpty,
                              label: Text('${orderProv.orders.length}'),
                              backgroundColor: AppTheme.primary,
                              child: const Icon(Icons.receipt_long_outlined,
                                  size: 22),
                            ),
                            tooltip: 'My Orders',
                          ),

                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StoreInfoScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline_rounded,
                                size: 22),
                            tooltip: 'About Green Basket',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Maintenance Announcement Banner (Browsing Allowed Mode)
                  if (store.settings.isMaintenanceMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFDE68A), width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.construction_rounded,
                                  color: Color(0xFFD97706), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            store.settings.maintenanceTitle
                                                    .isNotEmpty
                                                ? store.settings.maintenanceTitle
                                                : 'Ordering Temporarily Paused',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF92400E),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFDE68A),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'CATALOG ONLY',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF78350F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      store.settings.maintenanceMessage
                                              .isNotEmpty
                                          ? store.settings.maintenanceMessage
                                          : 'You can explore our fresh produce catalog. WhatsApp checkout will resume shortly.',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFB45309),
                                        height: 1.3,
                                      ),
                                    ),
                                    if (store.settings
                                        .formattedMaintenanceResume.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Estimated resumption: ${store.settings.formattedMaintenanceResume}',
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
                      ),
                    ),

                  // APMC Mandi Trust Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Direct from APMC Mandi • 4 AM Harvest • Free Delivery > ₹${store.freeDeliveryThreshold.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => catalog.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search fresh vegetables, fruits, herbs...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppTheme.textLight),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    catalog.clearSearch();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Category Chips Bar (Sticky horizontal scrollspy)
                  SliverToBoxAdapter(
                    child: CategoryChipsBar(
                      categories: catalog.categories,
                      selectedCategoryId: catalog.selectedCategoryId,
                      onSelectCategory: (catId) => catalog.selectCategory(catId),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                  // Results Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            catalog.selectedCategoryId == 'ALL'
                                ? 'All Fresh Produce (${products.length})'
                                : '${catalog.categories.firstWhere((c) => c.id == catalog.selectedCategoryId, orElse: () => catalog.categories.first).name} (${products.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMain,
                            ),
                          ),
                          if (catalog.searchQuery.isNotEmpty)
                            Text(
                              'Filter: "${catalog.searchQuery}"',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // 2-Column Product Grid
                  catalog.isLoading
                      ? const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : products.isEmpty
                          ? SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_off_rounded,
                                        size: 48, color: AppTheme.textLight),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No produce found matching "${catalog.searchQuery}"',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        catalog.clearSearch();
                                        catalog.selectCategory('ALL');
                                      },
                                      child: const Text('Show All Items'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final product = products[index];
                                    return ProductCard(
                                      product: product,
                                      onTap: () {
                                        ProductDetailSheet.show(
                                            context, product);
                                      },
                                    );
                                  },
                                  childCount: products.length,
                                ),
                              ),
                            ),
                ],
              ),
            ),
          ),

          // Floating Persistent Cart Bar
          FloatingCartBar(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CartScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
