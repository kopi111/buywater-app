import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _proceedToCheckout() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () async {
                  final confirm = await Helpers.showConfirmDialog(
                    context,
                    title: 'Clear Cart',
                    message: 'Are you sure you want to remove all items?',
                    confirmText: 'Clear',
                    isDestructive: true,
                  );
                  if (confirm) {
                    cart.clearCart();
                  }
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add some items to get started',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Cart items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(cart, item);
                  },
                ),
              ),

              // Promo code & summary
              Container(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Promo code
                      if (cart.promoCode == null)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoController,
                                decoration: const InputDecoration(
                                  hintText: 'Promo code',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: cart.isLoading
                                  ? null
                                  : () async {
                                      if (_promoController.text.isNotEmpty) {
                                        final success = await cart.applyPromoCode(
                                          _promoController.text,
                                        );
                                        if (!mounted) return;
                                        if (success) {
                                          Helpers.showSnackBar(
                                            context,
                                            'Promo code applied!',
                                          );
                                          _promoController.clear();
                                        } else {
                                          Helpers.showSnackBar(
                                            context,
                                            cart.error ?? 'Invalid promo code',
                                            isError: true,
                                          );
                                        }
                                      }
                                    },
                              child: cart.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Apply'),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 16,
                                    color: AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cart.promoCode!,
                                    style: const TextStyle(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-${Helpers.formatCurrency(cart.discount)}',
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => cart.removePromoCode(),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(Helpers.formatCurrency(cart.subtotal)),
                        ],
                      ),
                      if (cart.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount'),
                            Text(
                              '-${Helpers.formatCurrency(cart.discount)}',
                              style: const TextStyle(color: AppTheme.successColor),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery'),
                          Text(
                            cart.deliveryFee > 0
                                ? Helpers.formatCurrency(cart.deliveryFee)
                                : 'FREE',
                            style: TextStyle(
                              color: cart.deliveryFee == 0
                                  ? AppTheme.successColor
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            Helpers.formatCurrency(cart.grandTotal),
                            style: AppTheme.priceLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Checkout button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _proceedToCheckout,
                          child: Text(
                            'Checkout (${cart.itemCount} items)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartProvider cart, cartItem) {
    final product = cartItem.product;

    return Dismissible(
      key: Key(cartItem.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        cart.removeFromCart(product.id);
        Helpers.showSnackBar(context, '${product.name} removed from cart');
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.mainImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.hasDiscount)
                      Text(
                        Helpers.formatCurrency(product.price),
                        style: AppTheme.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      Helpers.formatCurrency(product.effectivePrice),
                      style: AppTheme.priceStyle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // Quantity controls
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  cart.decrementQuantity(product.id);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.remove, size: 16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '${cartItem.quantity}',
                                  style: AppTheme.bodyMedium,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (cartItem.quantity < product.stockQuantity) {
                                    cart.incrementQuantity(product.id);
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          Helpers.formatCurrency(cartItem.totalPrice),
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
