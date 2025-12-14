import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../config/theme.dart';
import '../utils/helpers.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddToCart = true,
  });

  Widget _buildProductImage() {
    final imageUrl = product.mainImage;

    // Check if it's a local asset
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, size: 40, color: Colors.grey),
        ),
      );
    }

    // Network image
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _buildProductImage(),
                ),
                // Discount badge
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${product.discountPercentage.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<ProductProvider>(
                    builder: (context, provider, _) {
                      final isWishlisted = provider.isInWishlist(product.id);
                      return GestureDetector(
                        onTap: () {
                          provider.toggleWishlist(product);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Out of stock overlay
                if (!product.isInStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Flexible(
                      child: Text(
                        product.name,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Rating
                    if (product.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: AppTheme.bodySmall.copyWith(fontSize: 11),
                          ),
                          Text(
                            ' (${product.reviewCount})',
                            style: AppTheme.bodySmall.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Price
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (product.hasDiscount)
                                Text(
                                  Helpers.formatCurrency(product.price),
                                  style: AppTheme.bodySmall.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              Text(
                                Helpers.formatCurrency(product.effectivePrice),
                                style: AppTheme.priceStyle.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (showAddToCart && product.isInStock)
                          Consumer<CartProvider>(
                            builder: (context, cart, _) {
                              final isInCart = cart.isInCart(product.id);
                              return GestureDetector(
                                onTap: () {
                                  if (!isInCart) {
                                    cart.addToCart(product);
                                    Helpers.showSnackBar(
                                      context,
                                      'Added to cart',
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: isInCart
                                        ? AppTheme.successColor
                                        : AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    isInCart ? Icons.check : Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
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
