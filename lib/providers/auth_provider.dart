import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/address.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/demo_data_service.dart';
import '../config/app_config.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  List<Address> _addresses = [];
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  User? get user => _user;
  List<Address> get addresses => _addresses;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  // Initialize - check if user is logged in
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        _user = await _authService.getCurrentUser();
        if (_user != null) {
          _status = AuthStatus.authenticated;
          await loadAddresses();
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }

    _setLoading(false);
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.login(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      await loadAddresses();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }

    _user = null;
    _addresses = [];
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: profileImage,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.requestPasswordReset(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Load user addresses
  Future<void> loadAddresses() async {
    try {
      final response = await _apiService.get('/addresses');
      final List<dynamic> data = response.data['addresses'] ?? response.data;
      _addresses = data.map((json) => Address.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    }
  }

  // Add address
  Future<bool> addAddress(Address address) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.post('/addresses', data: address.toJson());
      final newAddress = Address.fromJson(response.data['address'] ?? response.data);
      _addresses.add(newAddress);

      // If it's the default, update other addresses
      if (newAddress.isDefault) {
        for (int i = 0; i < _addresses.length - 1; i++) {
          if (_addresses[i].isDefault) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
          }
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Update address
  Future<bool> updateAddress(Address address) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.put('/addresses/${address.id}', data: address.toJson());
      final updatedAddress = Address.fromJson(response.data['address'] ?? response.data);

      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index >= 0) {
        _addresses[index] = updatedAddress;

        // If it's set as default, update other addresses
        if (updatedAddress.isDefault) {
          for (int i = 0; i < _addresses.length; i++) {
            if (i != index && _addresses[i].isDefault) {
              _addresses[i] = _addresses[i].copyWith(isDefault: false);
            }
          }
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Delete address
  Future<bool> deleteAddress(String addressId) async {
    _setLoading(true);
    _error = null;

    try {
      await _apiService.delete('/addresses/$addressId');
      _addresses.removeWhere((a) => a.id == addressId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // Set default address
  Future<bool> setDefaultAddress(String addressId) async {
    _setLoading(true);
    _error = null;

    try {
      await _apiService.put('/addresses/$addressId/default');

      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(
          isDefault: _addresses[i].id == addressId,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Load demo user for demo mode
  void loadDemoUser() {
    _user = DemoDataService.demoUser;
    _addresses = DemoDataService.demoAddresses;
    _status = AuthStatus.authenticated;
    _isLoading = false;
    notifyListeners();
  }
}
