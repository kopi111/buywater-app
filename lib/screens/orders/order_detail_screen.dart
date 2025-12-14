import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/order_provider.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import '../../models/order.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().getOrderDetails(widget.orderId);
    });
  }

  @override
  void dispose() {
    context.read<OrderProvider>().clearSelectedOrder();
    super.dispose();
  }

  Future<void> _cancelOrder() async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Cancel Order',
      message: 'Are you sure you want to cancel this order?',
      confirmText: 'Cancel Order',
      isDestructive: true,
    );

    if (confirm) {
      final success = await context.read<OrderProvider>().cancelOrder(
            widget.orderId,
            reason: 'Customer requested cancellation',
          );

      if (!mounted) return;

      if (success) {
        Helpers.showSnackBar(context, 'Order cancelled');
      } else {
        Helpers.showSnackBar(
          context,
          context.read<OrderProvider>().error ?? 'Failed to cancel order',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order status card
                _buildStatusCard(order),
                const SizedBox(height: 16),

                // Order items
                _buildItemsCard(order),
                const SizedBox(height: 16),

                // Delivery address
                _buildAddressCard(order),
                const SizedBox(height: 16),

                // Payment summary
                _buildPaymentCard(order),
                const SizedBox(height: 24),

                // Actions
                if (order.status == OrderStatus.pending ||
                    order.status == OrderStatus.confirmed)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelOrder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),

                if (order.status == OrderStatus.delivered) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Reorder
                      },
                      child: const Text('Reorder'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Request refund
                      },
                      child: const Text('Request Refund'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: AppTheme.heading3,
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on ${Helpers.formatDateTime(order.createdAt)}',
              style: AppTheme.bodySmall,
            ),
            const Divider(height: 24),

            // Order timeline
            _buildTimeline(order),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Order order) {
    final steps = [
      {'status': OrderStatus.pending, 'label': 'Order Placed'},
      {'status': OrderStatus.confirmed, 'label': 'Confirmed'},
      {'status': OrderStatus.processing, 'label': 'Processing'},
      {'status': OrderStatus.shipped, 'label': 'Shipped'},
      {'status': OrderStatus.delivered, 'label': 'Delivered'},
    ];

    final currentIndex = steps.indexWhere((s) => s['status'] == order.status);

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (steps[index]['label'] as String).split(' ').first,
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted && index < currentIndex
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Items', style: AppTheme.heading3),
            const Divider(),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.product.mainImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${item.quantity}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Helpers.formatCurrency(item.totalPrice),
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 20),
                const SizedBox(width: 8),
                const Text('Delivery Address', style: AppTheme.heading3),
              ],
            ),
            const Divider(),
            Text(
              order.shippingAddress.fullName,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
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
            if (order.trackingNumber != null) ...[
              const Divider(),
              Row(
                children: [
                  const Text('Tracking: ', style: AppTheme.bodySmall),
                  Text(
                    order.trackingNumber!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Summary', style: AppTheme.heading3),
            const Divider(),
            _buildPaymentRow('Subtotal', Helpers.formatCurrency(order.subtotal)),
            if (order.discount > 0)
              _buildPaymentRow(
                'Discount',
                '-${Helpers.formatCurrency(order.discount)}',
                valueColor: AppTheme.successColor,
              ),
            _buildPaymentRow(
              'Delivery',
              Helpers.formatCurrency(order.deliveryFee),
            ),
            const Divider(),
            _buildPaymentRow(
              'Total',
              Helpers.formatCurrency(order.total),
              isBold: true,
            ),
            const Divider(),
            _buildPaymentRow(
              'Payment Method',
              order.paymentMethod.toUpperCase(),
            ),
            _buildPaymentRow(
              'Payment Status',
              order.paymentStatusText,
              valueColor: order.paymentStatus == PaymentStatus.completed
                  ? AppTheme.successColor
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold)
                : AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: (isBold
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : AppTheme.bodyMedium)
                .copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        break;
      case OrderStatus.delivered:
        backgroundColor = AppTheme.successColor.withOpacity(0.1);
        textColor = AppTheme.successColor;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
