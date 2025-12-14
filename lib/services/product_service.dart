import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // Get all products with pagination
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (categoryId != null) 'category_id': categoryId,
      if (sortBy != null) 'sort_by': sortBy,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
    };

    final response = await _apiService.get('/products', queryParameters: queryParams);
    final List<dynamic> data = response.data['products'] ?? response.data;

    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    final response = await _apiService.get('/products/featured',
      queryParameters: {'limit': limit});
    final List<dynamic> data = response.data['products'] ?? response.data;

    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Get product by ID
  Future<Product> getProductById(String productId) async {
    final response = await _apiService.get('/products/$productId');
    return Product.fromJson(response.data['product'] ?? response.data);
  }

  // Search products
  Future<List<Product>> searchProducts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get('/products/search',
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      });
    final List<dynamic> data = response.data['products'] ?? response.data;

    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Get all categories
  Future<List<Category>> getCategories() async {
    final response = await _apiService.get('/categories');
    final List<dynamic> data = response.data['categories'] ?? response.data;

    return data.map((json) => Category.fromJson(json)).toList();
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory({
    required String categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get('/categories/$categoryId/products',
      queryParameters: {
        'page': page,
        'limit': limit,
      });
    final List<dynamic> data = response.data['products'] ?? response.data;

    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Get product reviews
  Future<List<ProductReview>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.get('/products/$productId/reviews',
      queryParameters: {
        'page': page,
        'limit': limit,
      });
    final List<dynamic> data = response.data['reviews'] ?? response.data;

    return data.map((json) => ProductReview.fromJson(json)).toList();
  }

  // Add product review
  Future<ProductReview> addProductReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    final response = await _apiService.post('/products/$productId/reviews',
      data: {
        'rating': rating,
        'comment': comment,
      });

    return ProductReview.fromJson(response.data['review'] ?? response.data);
  }

  // Get wishlist
  Future<List<Product>> getWishlist() async {
    final response = await _apiService.get('/wishlist');
    final List<dynamic> data = response.data['products'] ?? response.data;

    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Add to wishlist
  Future<void> addToWishlist(String productId) async {
    await _apiService.post('/wishlist', data: {'product_id': productId});
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String productId) async {
    await _apiService.delete('/wishlist/$productId');
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    try {
      final response = await _apiService.get('/wishlist/$productId');
      return response.data['in_wishlist'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
