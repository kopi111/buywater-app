import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';
import '../../services/nfc_service.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  final PaymentService _paymentService = PaymentService();
  final NFCService _nfcService = NFCService();

  String _paymentMethod = 'card';
  String _cardType = '';
  bool _isNFCAvailable = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkNFCAvailability();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _nfcService.stopNFCSession();
    super.dispose();
  }

  Future<void> _checkNFCAvailability() async {
    final status = await _nfcService.checkNFCAvailability();
    setState(() {
      _isNFCAvailable = status == NFCStatus.available;
    });
  }

  void _onCardNumberChanged(String value) {
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _cardType = _paymentService.getCardType(cleanNumber);
    });
  }

  Future<void> _processPayment() async {
    if (_paymentMethod == 'card') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cart = context.read<CartProvider>();
      final auth = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();

      // Parse expiry date
      String expiryMonth = '';
      String expiryYear = '';
      if (_paymentMethod == 'card') {
        final expiryParts = _expiryController.text.split('/');
        expiryMonth = expiryParts[0];
        expiryYear = expiryParts.length > 1 ? expiryParts[1] : '';
      }

      final order = await orderProvider.processCheckout(
        items: cart.items,
        subtotal: cart.subtotal,
        discount: cart.discount,
        promoCode: cart.promoCode,
        cardNumber: _paymentMethod == 'card' ? _cardNumberController.text : null,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: _cvvController.text,
        cardHolderName: _cardHolderController.text,
        email: auth.user?.email,
      );

      if (!mounted) return;

      if (order != null) {
        // Clear cart after successful order
        cart.clearCart();

        // Navigate to confirmation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(order: order),
          ),
          (route) => route.isFirst,
        );
      } else {
        Helpers.showSnackBar(
          context,
          orderProvider.error ?? 'Payment failed',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Payment failed: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processNFCPayment() async {
    setState(() {
      _isProcessing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.contactless,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap your card',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 8),
            const Text(
              'Hold your card near the phone to pay',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nfcService.stopNFCSession();
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    final cart = context.read<CartProvider>();

    final result = await _nfcService.processNFCPayment(
      amount: cart.total,
      orderId: Helpers.generateOrderNumber(),
      onStatusUpdate: (status) {
        // Update UI with status
      },
      onError: (error) {
        if (mounted) {
          Navigator.pop(context);
          Helpers.showSnackBar(context, error, isError: true);
        }
      },
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (result != null) {
      // Process the order with NFC payment data
      _processPayment();
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment method selection
            const Text('Payment Method', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        const Icon(Icons.credit_card),
                        const SizedBox(width: 12),
                        const Text('Credit/Debit Card'),
                      ],
                    ),
                    value: 'card',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                      context.read<OrderProvider>().setPaymentMethod(value!);
                    },
                  ),
                  if (_isNFCAvailable) ...[
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          const Icon(Icons.contactless),
                          const SizedBox(width: 12),
                          const Text('Tap to Pay (NFC)'),
                        ],
                      ),
                      value: 'nfc',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                        context.read<OrderProvider>().setPaymentMethod(value!);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card form
            if (_paymentMethod == 'card') ...[
              const Text('Card Details', style: AppTheme.heading3),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Card number
                        TextFormField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(19),
                            _CardNumberFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Card Number',
                            hintText: '1234 5678 9012 3456',
                            prefixIcon: const Icon(Icons.credit_card),
                            suffixIcon: _cardType.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _cardType,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: _onCardNumberChanged,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card number';
                            }
                            final cleanNumber = value.replaceAll(' ', '');
                            if (!_paymentService.validateCardNumber(cleanNumber)) {
                              return 'Invalid card number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Expiry and CVV
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expiryController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                  _ExpiryDateFormatter(),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Expiry',
                                  hintText: 'MM/YY',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final parts = value.split('/');
                                  if (parts.length != 2) {
                                    return 'Invalid';
                                  }
                                  if (!_paymentService.validateExpiryDate(
                                    parts[0],
                                    parts[1],
                                  )) {
                                    return 'Expired';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  hintText: '123',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (!_paymentService.validateCVV(
                                    value,
                                    _cardType,
                                  )) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card holder name
                        TextFormField(
                          controller: _cardHolderController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Card Holder Name',
                            hintText: 'JOHN DOE',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter card holder name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // NFC instructions
            if (_paymentMethod == 'nfc') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.contactless,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to Pay',
                        style: AppTheme.heading3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'When you\'re ready, tap the pay button below and hold your contactless card near the back of your phone.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Order total
            Consumer2<CartProvider, OrderProvider>(
              builder: (context, cart, order, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total to Pay',
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
                  ),
                );
              },
            ),

            // Security notice
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Secured by NCB Payment Gateway',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
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
            onPressed: _isProcessing
                ? null
                : (_paymentMethod == 'nfc'
                    ? _processNFCPayment
                    : _processPayment),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(_paymentMethod == 'nfc' ? 'Tap to Pay' : 'Pay Now'),
          ),
        ),
      ),
    );
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry date formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length == 2 && !text.contains('/')) {
      return newValue.copyWith(
        text: '$text/',
        selection: const TextSelection.collapsed(offset: 3),
      );
    }

    return newValue;
  }
}
