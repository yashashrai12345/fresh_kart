import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/wishlist_provider.dart';
import 'product_detail_sheet.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final catalog = context.watch<CatalogProvider>();
    final cart = context.watch<CartProvider>();

    final savedProducts = catalog.products
        .where((p) => wishlist.isInWishlist(p.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
      ),
      body: savedProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.dangerLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_outline_rounded,
                        size: 40, color: AppTheme.danger),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Wishlist Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the heart icon on any produce item to save it here.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: savedProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final product = savedProducts[idx];
                return GestureDetector(
                  onTap: () => ProductDetailSheet.show(context, product),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: product.photoUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                            fadeInDuration: const Duration(milliseconds: 100),
                            placeholder: (_, __) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.image_outlined,
                                  size: 20, color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${product.price.toStringAsFixed(0)} ${product.unit}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => wishlist.toggle(product.id),
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.danger),
                          tooltip: 'Remove from wishlist',
                        ),
                        ElevatedButton(
                          onPressed: () {
                            cart.addItem(
                              product: product,
                              portionLabel:
                                  product.isKgUnit ? '1 kg' : '1 unit',
                              portionMultiplier: 1.0,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${product.name} to cart!'),
                                backgroundColor: AppTheme.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Add',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
