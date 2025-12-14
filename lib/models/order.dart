import 'address.dart';
import 'cart.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final Address shippingAddress;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? promoCode;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final String? transactionId;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    this.discount = 0,
    required this.deliveryFee,
    required this.total,
    this.promoCode,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    required this.paymentMethod,
    this.transactionId,
    this.trackingNumber,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      shippingAddress: Address.fromJson(json['shipping_address'] ?? {}),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      promoCode: json['promo_code'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: json['payment_method'] ?? '',
      transactionId: json['transaction_id'],
      trackingNumber: json['tracking_number'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress.toJson(),
      'subtotal': subtotal,
      'discount': discount,
      'delivery_fee': deliveryFee,
      'total': total,
      'promo_code': promoCode,
      'status': status.name,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'tracking_number': trackingNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}
