import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Order Placed!',
                style: AppTheme.heading1,
              ),
              const SizedBox(height: 8),
              Text(
                'Your order #${order.id.substring(0, 8).toUpperCase()} has been confirmed',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Order details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Details', style: AppTheme.heading3),
                      const Divider(),
                      _buildDetailRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                      _buildDetailRow('Date', Helpers.formatDateTime(order.createdAt)),
                      _buildDetailRow('Items', '${order.itemCount} items'),
                      _buildDetailRow('Payment', order.paymentMethod.toUpperCase()),
                      const Divider(),
                      _buildDetailRow('Subtotal', Helpers.formatCurrency(order.subtotal)),
                      if (order.discount > 0)
                        _buildDetailRow(
                          'Discount',
                          '-${Helpers.formatCurrency(order.discount)}',
                          valueColor: AppTheme.successColor,
                        ),
                      _buildDetailRow('Delivery', Helpers.formatCurrency(order.deliveryFee)),
                      const Divider(),
                      _buildDetailRow(
                        'Total',
                        Helpers.formatCurrency(order.total),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery address card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text('Delivery Address', style: AppTheme.heading3),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        order.shippingAddress.fullName,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingAddress.formattedAddress,
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingAddress.phone,
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // What's next
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'What\'s Next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildNextStep('1', 'You\'ll receive a confirmation email shortly'),
                      _buildNextStep('2', 'We\'ll notify you when your order ships'),
                      _buildNextStep('3', 'Track your order in the Orders section'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/orders',
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('View Order'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text('Continue Shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: isBold
                ? TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: valueColor ?? AppTheme.primaryColor,
                  )
                : TextStyle(color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
