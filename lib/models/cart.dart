import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.effectivePrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Cart {
  final List<CartItem> items;
  String? promoCode;
  double? promoDiscount;

  Cart({
    List<CartItem>? items,
    this.promoCode,
    this.promoDiscount,
  }) : items = items ?? [];

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  double get discount => promoDiscount ?? 0;

  double get total => subtotal - discount;

  bool get isEmpty => items.isEmpty;

  void addItem(CartItem item) {
    final existingIndex = items.indexWhere((i) => i.product.id == item.product.id);
    if (existingIndex >= 0) {
      items[existingIndex].quantity += item.quantity;
    } else {
      items.add(item);
    }
  }

  void removeItem(String productId) {
    items.removeWhere((item) => item.product.id == productId);
  }

  void updateQuantity(String productId, int quantity) {
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = quantity;
      }
    }
  }

  void clear() {
    items.clear();
    promoCode = null;
    promoDiscount = null;
  }

  void applyPromoCode(String code, double discount) {
    promoCode = code;
    promoDiscount = discount;
  }

  void removePromoCode() {
    promoCode = null;
    promoDiscount = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'promo_code': promoCode,
      'promo_discount': promoDiscount,
    };
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List?)
          ?.map((item) => CartItem.fromJson(item))
          .toList(),
      promoCode: json['promo_code'],
      promoDiscount: json['promo_discount']?.toDouble(),
    );
  }
}
