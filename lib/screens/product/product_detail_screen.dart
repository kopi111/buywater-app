import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../utils/helpers.dart';
import '../../models/product.dart';
import '../../services/demo_data_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductProvider>().getProductDetails(widget.productId);
      });
    }
  }

  Product? _getProduct(ProductProvider provider) {
    if (AppConfig.isDemoMode) {
      return provider.getProductById(widget.productId);
    }
    return provider.selectedProduct;
  }

  List<ProductReview> _getReviews(ProductProvider provider) {
    if (AppConfig.isDemoMode) {
      return DemoDataService.getProductReviews(widget.productId);
    }
    return provider.productReviews;
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, size: 64),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 64),
      ),
    );
  }

  @override
  void dispose() {
    context.read<ProductProvider>().clearSelectedProduct();
    super.dispose();
  }

  void _addToCart(Product product) {
    context.read<CartProvider>().addToCart(product, quantity: _quantity);
    Helpers.showSnackBar(context, 'Added $_quantity item(s) to cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !AppConfig.isDemoMode) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = _getProduct(provider);
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          return CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Main image
                      PageView.builder(
                        onPageChanged: (index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        itemCount: product.images.length.clamp(1, 10),
                        itemBuilder: (context, index) {
                          final imageUrl = product.images.isNotEmpty
                              ? product.images[index]
                              : '';
                          return _buildImage(imageUrl);
                        },
                      ),
                      // Image indicators
                      if (product.images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              product.images.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedImageIndex == index
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Discount badge
                      if (product.hasDiscount)
                        Positioned(
                          top: 100,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${product.discountPercentage.toInt()}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      final isWishlisted = provider.isInWishlist(product.id);
                      return IconButton(
                        icon: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted ? Colors.red : null,
                        ),
                        onPressed: () {
                          provider.toggleWishlist(product);
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // TODO: Share product
                    },
                  ),
                ],
              ),

              // Product details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        product.categoryName,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Name
                      Text(product.name, style: AppTheme.heading2),
                      const SizedBox(height: 8),

                      // Rating
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: product.rating,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            itemCount: 5,
                            itemSize: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Helpers.formatCurrency(product.effectivePrice),
                            style: AppTheme.priceLarge,
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: 12),
                            Text(
                              Helpers.formatCurrency(product.price),
                              style: AppTheme.bodyLarge.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stock status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.isInStock
                              ? AppTheme.successColor.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.isInStock
                              ? 'In Stock (${product.stockQuantity} available)'
                              : 'Out of Stock',
                          style: TextStyle(
                            color: product.isInStock
                                ? AppTheme.successColor
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quantity selector
                      if (product.isInStock) ...[
                        const Text('Quantity', style: AppTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '$_quantity',
                                      textAlign: TextAlign.center,
                                      style: AppTheme.bodyLarge,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _quantity < product.stockQuantity
                                        ? () => setState(() => _quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      const Text('Description', style: AppTheme.heading3),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Specifications
                      if (product.specifications != null &&
                          product.specifications!.isNotEmpty) ...[
                        const Text('Specifications', style: AppTheme.heading3),
                        const SizedBox(height: 8),
                        ...product.specifications!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    entry.key,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: AppTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Reviews section
                      _buildReviewsSection(_getReviews(provider)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final product = provider.selectedProduct;
          if (product == null) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Price', style: AppTheme.bodySmall),
                        Text(
                          Helpers.formatCurrency(
                            product.effectivePrice * _quantity,
                          ),
                          style: AppTheme.priceLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: product.isInStock
                          ? () => _addToCart(product)
                          : null,
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(List<ProductReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Reviews', style: AppTheme.heading3),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all reviews
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (reviews.isEmpty)
          const Text('No reviews yet')
        else
          ...reviews.take(3).map((review) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          Helpers.getInitials(review.userName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            RatingBarIndicator(
                              rating: review.rating,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 14,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Helpers.formatRelativeDate(review.createdAt),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.comment, style: AppTheme.bodyMedium),
                ],
              ),
            );
          }),
        const SizedBox(height: 80), // Space for bottom bar
      ],
    );
  }
}
