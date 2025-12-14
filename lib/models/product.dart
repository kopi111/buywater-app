class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final List<String> images;
  final String categoryId;
  final String categoryName;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final Map<String, dynamic>? specifications;
  final bool isFeatured;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.images,
    required this.categoryId,
    required this.categoryName,
    required this.stockQuantity,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.specifications,
    this.isFeatured = false,
    required this.createdAt,
  });

  bool get isInStock => stockQuantity > 0;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double get effectivePrice => discountPrice ?? price;
  double get discountPercentage => hasDiscount
      ? ((price - discountPrice!) / price * 100)
      : 0;

  String get mainImage => images.isNotEmpty ? images.first : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      images: List<String>.from(json['images'] ?? []),
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      specifications: json['specifications'],
      isFeatured: json['is_featured'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'images': images,
      'category_id': categoryId,
      'category_name': categoryName,
      'stock_quantity': stockQuantity,
      'rating': rating,
      'review_count': reviewCount,
      'specifications': specifications,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? icon;
  final String? image;
  final int productCount;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.image,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      image: json['image'],
      productCount: json['product_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'image': image,
      'product_count': productCount,
    };
  }
}

class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
