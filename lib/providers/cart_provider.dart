import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../config/app_config.dart';

class CartProvider extends ChangeNotifier {
  Cart _cart = Cart();
  bool _isLoading = false;
  String? _error;

  Cart get cart => _cart;
  List<CartItem> get items => _cart.items;
  int get itemCount => _cart.itemCount;
  double get subtotal => _cart.subtotal;
  double get discount => _cart.discount;
  double get total => _cart.total;
  bool get isEmpty => _cart.isEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get promoCode => _cart.promoCode;

  // Calculate delivery fee based on subtotal
  double get deliveryFee {
    if (subtotal >= AppConfig.freeDeliveryThreshold) {
      return 0;
    }
    return AppConfig.standardDeliveryFee;
  }

  double get grandTotal => total + deliveryFee;

  // Initialize cart from local storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart');

      if (cartJson != null) {
        _cart = Cart.fromJson(jsonDecode(cartJson));
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
      _cart = Cart();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cart', jsonEncode(_cart.toJson()));
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // Add item to cart
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cart.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _cart.items[existingIndex].quantity += quantity;
    } else {
      _cart.items.add(CartItem(
        id: const Uuid().v4(),
        product: product,
        quantity: quantity,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  // Remove item from cart
  void removeFromCart(String productId) {
    _cart.removeItem(productId);
    _saveCart();
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String productId, int quantity) {
    _cart.updateQuantity(productId, quantity);
    _saveCart();
    notifyListeners();
  }

  // Increment item quantity
  void incrementQuantity(String productId) {
    final item = _cart.items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw Exception('Item not found'),
    );

    if (item.quantity < item.product.stockQuantity) {
      item.quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  // Decrement item quantity
  void decrementQuantity(String productId) {
    final item = _cart.items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw Exception('Item not found'),
    );

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cart.items.remove(item);
    }

    _saveCart();
    notifyListeners();
  }

  // Apply promo code
  Future<bool> applyPromoCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Validate promo code with API
      // For now, simulate validation
      await Future.delayed(const Duration(seconds: 1));

      // Mock promo code validation
      if (code.toUpperCase() == 'SAVE10') {
        final discountAmount = subtotal * 0.10;
        _cart.applyPromoCode(code.toUpperCase(), discountAmount);
        _saveCart();
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (code.toUpperCase() == 'SAVE20') {
        final discountAmount = subtotal * 0.20;
        _cart.applyPromoCode(code.toUpperCase(), discountAmount);
        _saveCart();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid promo code';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove promo code
  void removePromoCode() {
    _cart.removePromoCode();
    _saveCart();
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _cart.clear();
    _saveCart();
    notifyListeners();
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _cart.items.any((item) => item.product.id == productId);
  }

  // Get quantity of product in cart
  int getQuantity(String productId) {
    try {
      final item = _cart.items.firstWhere(
        (item) => item.product.id == productId,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
