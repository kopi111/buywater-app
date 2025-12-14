import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../utils/helpers.dart';
import '../../models/address.dart';
import 'payment_screen.dart';
import 'add_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _deliveryType = 'standard';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.addresses.isEmpty) {
        authProvider.loadAddresses();
      }
      // Set default address
      if (authProvider.defaultAddress != null) {
        context.read<OrderProvider>().setSelectedAddress(
              authProvider.defaultAddress!,
            );
      }
    });
  }

  void _selectAddress() {
    final addresses = context.read<AuthProvider>().addresses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Address', style: AppTheme.heading3),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAddressScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: addresses.isEmpty
                    ? const Center(
                        child: Text('No addresses saved'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return _buildAddressOption(address);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressOption(Address address) {
    final orderProvider = context.read<OrderProvider>();
    final isSelected = orderProvider.selectedAddress?.id == address.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          orderProvider.setSelectedAddress(address);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) {
                  orderProvider.setSelectedAddress(address);
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.fullName,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (address.label != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              address.label!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.formattedAddress,
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.phone,
                      style: AppTheme.bodySmall,
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

  void _proceedToPayment() {
    final orderProvider = context.read<OrderProvider>();

    if (orderProvider.selectedAddress == null) {
      Helpers.showSnackBar(
        context,
        'Please select a delivery address',
        isError: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery address
            const Text('Delivery Address', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Consumer2<AuthProvider, OrderProvider>(
              builder: (context, auth, order, _) {
                final selectedAddress = order.selectedAddress;

                if (selectedAddress == null) {
                  return Card(
                    child: InkWell(
                      onTap: _selectAddress,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_location_alt,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Add delivery address',
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: InkWell(
                    onTap: _selectAddress,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      selectedAddress.fullName,
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (selectedAddress.label != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          selectedAddress.label!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedAddress.formattedAddress,
                                  style: AppTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedAddress.phone,
                                  style: AppTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Delivery options
            const Text('Delivery Options', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Standard Delivery'),
                    subtitle: Text(
                      '${Helpers.formatCurrency(AppConfig.standardDeliveryFee)} - 3-5 business days',
                    ),
                    value: 'standard',
                    groupValue: _deliveryType,
                    onChanged: (value) {
                      setState(() {
                        _deliveryType = value!;
                      });
                      context.read<OrderProvider>().setDeliveryType(value!);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Express Delivery'),
                    subtitle: Text(
                      '${Helpers.formatCurrency(AppConfig.expressDeliveryFee)} - 1-2 business days',
                    ),
                    value: 'express',
                    groupValue: _deliveryType,
                    onChanged: (value) {
                      setState(() {
                        _deliveryType = value!;
                      });
                      context.read<OrderProvider>().setDeliveryType(value!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order summary
            const Text('Order Summary', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Consumer2<CartProvider, OrderProvider>(
              builder: (context, cart, order, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items (${cart.itemCount})'),
                            Text(Helpers.formatCurrency(cart.subtotal)),
                          ],
                        ),
                        if (cart.discount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount'),
                              Text(
                                '-${Helpers.formatCurrency(cart.discount)}',
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery'),
                            Text(
                              order.deliveryFee > 0
                                  ? Helpers.formatCurrency(order.deliveryFee)
                                  : 'FREE',
                              style: TextStyle(
                                color: order.deliveryFee == 0
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
                              Helpers.formatCurrency(
                                cart.total + order.deliveryFee,
                              ),
                              style: AppTheme.priceLarge,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          child: ElevatedButton(
            onPressed: _proceedToPayment,
            child: const Text('Continue to Payment'),
          ),
        ),
      ),
    );
  }
}
