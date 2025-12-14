import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../models/cart.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../config/app_config.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  List<Order> _orders = [];
  Order? _currentOrder;
  Order? _selectedOrder;

  bool _isLoading = false;
  bool _isProcessingPayment = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreOrders = true;

  // Checkout state
  Address? _selectedAddress;
  String _deliveryType = 'standard';
  double _deliveryFee = AppConfig.standardDeliveryFee;
  String _paymentMethod = 'card';

  // Getters
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get error => _error;
  bool get hasMoreOrders => _hasMoreOrders;
  Address? get selectedAddress => _selectedAddress;
  String get deliveryType => _deliveryType;
  double get deliveryFee => _deliveryFee;
  String get paymentMethod => _paymentMethod;

  // Load orders
  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreOrders = true;
    }

    if (!_hasMoreOrders && !refresh) return;

    _isLoading = refresh || _currentPage == 1;
    _error = null;
    notifyListeners();

    try {
      final newOrders = await _orderService.getOrders(page: _currentPage);

      if (refresh || _currentPage == 1) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      _hasMoreOrders = newOrders.length >= 10;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more orders
  Future<void> loadMoreOrders() async {
    if (_isLoading || !_hasMoreOrders) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newOrders = await _orderService.getOrders(page: _currentPage);
      _orders.addAll(newOrders);
      _hasMoreOrders = newOrders.length >= 10;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get order details
  Future<void> getOrderDetails(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderService.getOrderById(orderId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set checkout address
  void setSelectedAddress(Address address) {
    _selectedAddress = address;
    _updateDeliveryFee();
    notifyListeners();
  }

  // Set delivery type
  void setDeliveryType(String type) {
    _deliveryType = type;
    _updateDeliveryFee();
    notifyListeners();
  }

  void _updateDeliveryFee() {
    if (_deliveryType == 'express') {
      _deliveryFee = AppConfig.expressDeliveryFee;
    } else {
      _deliveryFee = AppConfig.standardDeliveryFee;
    }
  }

  // Set payment method
  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Process payment and create order
  Future<Order?> processCheckout({
    required List<CartItem> items,
    required double subtotal,
    required double discount,
    String? promoCode,
    // Card details
    String? cardNumber,
    String? expiryMonth,
    String? expiryYear,
    String? cvv,
    String? cardHolderName,
    String? email,
  }) async {
    if (_selectedAddress == null) {
      _error = 'Please select a delivery address';
      notifyListeners();
      return null;
    }

    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final total = subtotal - discount + _deliveryFee;

      // Create order first
      final order = await _orderService.createOrder(
        items: items,
        shippingAddress: _selectedAddress!,
        paymentMethod: _paymentMethod,
        promoCode: promoCode,
        deliveryFee: _deliveryFee,
      );

      _currentOrder = order;

      // Process payment
      if (_paymentMethod == 'card' && cardNumber != null) {
        final paymentResult = await _paymentService.processCardPayment(
          cardNumber: cardNumber,
          expiryMonth: expiryMonth!,
          expiryYear: expiryYear!,
          cvv: cvv!,
          cardHolderName: cardHolderName!,
          amount: total,
          orderId: order.id,
          customerEmail: email!,
        );

        if (!paymentResult.success) {
          _error = paymentResult.message;
          _isProcessingPayment = false;
          notifyListeners();
          return null;
        }
      }

      // Refresh orders list
      await loadOrders(refresh: true);

      _isProcessingPayment = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isProcessingPayment = false;
      notifyListeners();
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderService.cancelOrder(orderId, reason: reason);

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = updatedOrder;
      }

      if (_selectedOrder?.id == orderId) {
        _selectedOrder = updatedOrder;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Track order
  Future<Map<String, dynamic>?> trackOrder(String orderId) async {
    try {
      return await _orderService.trackOrder(orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Reorder
  Future<List<CartItem>?> reorder(String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await _orderService.reorder(orderId);
      _isLoading = false;
      notifyListeners();
      return items;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Apply promo code
  Future<Map<String, dynamic>?> applyPromoCode(String code, double subtotal) async {
    try {
      return await _orderService.applyPromoCode(code: code, subtotal: subtotal);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Request refund
  Future<bool> requestRefund({
    required String orderId,
    required String reason,
    List<String>? itemIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _orderService.requestRefund(
        orderId: orderId,
        reason: reason,
        itemIds: itemIds,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset checkout state
  void resetCheckout() {
    _selectedAddress = null;
    _deliveryType = 'standard';
    _deliveryFee = AppConfig.standardDeliveryFee;
    _paymentMethod = 'card';
    _currentOrder = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }
}
