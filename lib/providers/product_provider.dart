import 'package:flutter/foundation.dart' hide Category;
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/demo_data_service.dart';
import '../config/app_config.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _searchResults = [];
  List<Category> _categories = [];
  List<Product> _wishlist = [];
  Product? _selectedProduct;
  List<ProductReview> _productReviews = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreProducts = true;

  // Search state
  String _searchQuery = '';
  bool _isSearching = false;

  // Filter state
  String? _selectedCategoryId;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  double? _minPrice;
  double? _maxPrice;

  // Getters
  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get searchResults => _searchResults;
  List<Category> get categories => _categories;
  List<Product> get wishlist => _wishlist;
  Product? get selectedProduct => _selectedProduct;
  List<ProductReview> get productReviews => _productReviews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreProducts => _hasMoreProducts;
  String? get selectedCategoryId => _selectedCategoryId;
  String get sortBy => _sortBy;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  // Initialize
  Future<void> initialize() async {
    await Future.wait([
      loadCategories(),
      loadFeaturedProducts(),
      loadProducts(),
      loadWishlist(),
    ]);
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      _featuredProducts = await _productService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured products: $e');
    }
  }

  // Load products
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
    }

    if (!_hasMoreProducts && !refresh) return;

    _isLoading = refresh || _currentPage == 1;
    _error = null;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage,
        categoryId: _selectedCategoryId,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      if (refresh || _currentPage == 1) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _hasMoreProducts = newProducts.length >= 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage,
        categoryId: _selectedCategoryId,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      _products.addAll(newProducts);
      _hasMoreProducts = newProducts.length >= 20;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _productService.searchProducts(query: query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    _searchQuery = '';
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  // Set sort options
  void setSortOptions({String? sortBy, String? sortOrder}) {
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;
    loadProducts(refresh: true);
  }

  // Set price range
  void setPriceRange({double? min, double? max}) {
    _minPrice = min;
    _maxPrice = max;
    loadProducts(refresh: true);
  }

  // Clear filters
  void clearFilters() {
    _selectedCategoryId = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
    _minPrice = null;
    _maxPrice = null;
    loadProducts(refresh: true);
  }

  // Get product details
  Future<void> getProductDetails(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _productService.getProductById(productId);
      await loadProductReviews(productId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load product reviews
  Future<void> loadProductReviews(String productId) async {
    try {
      _productReviews = await _productService.getProductReviews(productId: productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  // Add product review
  Future<bool> addProductReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    try {
      final review = await _productService.addProductReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
      _productReviews.insert(0, review);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load wishlist
  Future<void> loadWishlist() async {
    try {
      _wishlist = await _productService.getWishlist();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  // Add to wishlist
  Future<bool> addToWishlist(Product product) async {
    try {
      await _productService.addToWishlist(product.id);
      _wishlist.add(product);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Remove from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      await _productService.removeFromWishlist(productId);
      _wishlist.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Toggle wishlist
  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  // Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlist.any((p) => p.id == productId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    _productReviews = [];
    notifyListeners();
  }

  // Load demo data for demo mode
  void loadDemoData() {
    _categories = DemoDataService.categories;
    _products = DemoDataService.products;
    _featuredProducts = DemoDataService.featuredProducts;
    _isLoading = false;
    _hasMoreProducts = false;
    notifyListeners();
  }

  // Get product by ID (supports demo mode)
  Product? getProductById(String productId) {
    if (AppConfig.isDemoMode) {
      try {
        return _products.firstWhere((p) => p.id == productId);
      } catch (e) {
        return null;
      }
    }
    return _selectedProduct;
  }

  // Get demo product reviews
  List<ProductReview> getDemoProductReviews(String productId) {
    return DemoDataService.getProductReviews(productId);
  }
}
