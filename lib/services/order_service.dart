import '../models/order.dart';
import '../models/address.dart';
import '../models/cart.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Create new order
  Future<Order> createOrder({
    required List<CartItem> items,
    required Address shippingAddress,
    required String paymentMethod,
    String? promoCode,
    double deliveryFee = 0,
  }) async {
    final response = await _apiService.post('/orders', data: {
      'items': items.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'price': item.product.effectivePrice,
      }).toList(),
      'shipping_address': shippingAddress.toJson(),
      'payment_method': paymentMethod,
      'promo_code': promoCode,
      'delivery_fee': deliveryFee,
    });

    return Order.fromJson(response.data['order'] ?? response.data);
  }

  // Get user's orders
  Future<List<Order>> getOrders({
    int page = 1,
    int limit = 10,
    OrderStatus? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status.name,
    };

    final response = await _apiService.get('/orders', queryParameters: queryParams);
    final List<dynamic> data = response.data['orders'] ?? response.data;

    return data.map((json) => Order.fromJson(json)).toList();
  }

  // Get order by ID
  Future<Order> getOrderById(String orderId) async {
    final response = await _apiService.get('/orders/$orderId');
    return Order.fromJson(response.data['order'] ?? response.data);
  }

  // Cancel order
  Future<Order> cancelOrder(String orderId, {String? reason}) async {
    final response = await _apiService.post('/orders/$orderId/cancel', data: {
      if (reason != null) 'reason': reason,
    });

    return Order.fromJson(response.data['order'] ?? response.data);
  }

  // Track order
  Future<Map<String, dynamic>> trackOrder(String orderId) async {
    final response = await _apiService.get('/orders/$orderId/track');
    return response.data;
  }

  // Reorder (add items from previous order to cart)
  Future<List<CartItem>> reorder(String orderId) async {
    final response = await _apiService.post('/orders/$orderId/reorder');
    final List<dynamic> data = response.data['items'] ?? [];

    return data.map((json) => CartItem.fromJson(json)).toList();
  }

  // Apply promo code
  Future<Map<String, dynamic>> applyPromoCode({
    required String code,
    required double subtotal,
  }) async {
    final response = await _apiService.post('/promo/validate', data: {
      'code': code,
      'subtotal': subtotal,
    });

    return {
      'valid': response.data['valid'] ?? false,
      'discount': (response.data['discount'] ?? 0).toDouble(),
      'message': response.data['message'],
    };
  }

  // Calculate delivery fee
  Future<double> calculateDeliveryFee({
    required Address address,
    required double subtotal,
    required String deliveryType, // 'standard' or 'express'
  }) async {
    final response = await _apiService.post('/delivery/calculate', data: {
      'parish': address.parish,
      'city': address.city,
      'subtotal': subtotal,
      'delivery_type': deliveryType,
    });

    return (response.data['delivery_fee'] ?? 0).toDouble();
  }

  // Get delivery estimate
  Future<Map<String, dynamic>> getDeliveryEstimate({
    required Address address,
    required String deliveryType,
  }) async {
    final response = await _apiService.post('/delivery/estimate', data: {
      'parish': address.parish,
      'city': address.city,
      'delivery_type': deliveryType,
    });

    return {
      'estimated_date': response.data['estimated_date'],
      'min_days': response.data['min_days'],
      'max_days': response.data['max_days'],
    };
  }

  // Request refund
  Future<Map<String, dynamic>> requestRefund({
    required String orderId,
    required String reason,
    List<String>? itemIds,
  }) async {
    final response = await _apiService.post('/orders/$orderId/refund', data: {
      'reason': reason,
      'item_ids': itemIds,
    });

    return response.data;
  }

  // Get order invoice
  Future<String> getOrderInvoice(String orderId) async {
    final response = await _apiService.get('/orders/$orderId/invoice');
    return response.data['invoice_url'] ?? '';
  }
}
