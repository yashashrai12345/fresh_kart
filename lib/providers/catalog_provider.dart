import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';

class CatalogProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  String _selectedCategoryId = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> loadCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cats = await SupabaseService.getCategories();
      final prods = await SupabaseService.getProducts();
      _categories = cats;
      _products = prods;

      // Subscribe to live product changes (admin toggles stock, edits price, etc.)
      _startProductsSubscription();
    } catch (e) {
      debugPrint('Error loading catalog: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribes to Supabase Realtime for the products table.
  /// When the admin panel changes a product (price, in_stock, etc.),
  /// this fires and immediately updates the UI in the Flutter app.
  void _startProductsSubscription() {
    _productsSubscription?.cancel();
    final stream = SupabaseService.subscribeToProducts();
    if (stream != null) {
      _productsSubscription = stream.listen((updatedProducts) {
        _products = updatedProducts;
        notifyListeners();
        debugPrint('Catalog updated via Supabase Realtime (${updatedProducts.length} products)');
      });
    }
  }

  void selectCategory(String categoryId) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    return _products.where((p) {
      final matchesCategory =
          _selectedCategoryId == 'ALL' || p.categoryId == _selectedCategoryId;

      final matchesSearch = _searchQuery.trim().isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase().trim()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase().trim());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<ProductModel> getSimilarProducts(ProductModel currentProduct) {
    return _products
        .where((p) =>
            p.categoryId == currentProduct.categoryId && p.id != currentProduct.id)
        .take(6)
        .toList();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
