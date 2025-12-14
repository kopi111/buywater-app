import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Register new user
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final response = await _apiService.post('/auth/register', data: {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    });

    final data = response.data;
    if (data['token'] != null) {
      await _apiService.setAuthToken(data['token']);
    }

    return User.fromJson(data['user']);
  }

  // Login user
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data;
    if (data['token'] != null) {
      await _apiService.setAuthToken(data['token']);
      await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
    }

    return User.fromJson(data['user']);
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (_) {
      // Continue with local logout even if API call fails
    }

    await _apiService.clearAuthToken();
    await _storage.delete(key: 'user_data');
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiService.getAuthToken();
    return token != null;
  }

  // Update user profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
  }) async {
    final response = await _apiService.put('/auth/profile', data: {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profile_image': profileImage,
    });

    final user = User.fromJson(response.data['user']);
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));

    return user;
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiService.put('/auth/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    await _apiService.post('/auth/password/reset', data: {
      'email': email,
    });
  }

  // Verify password reset code
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _apiService.post('/auth/password/verify', data: {
      'email': email,
      'code': code,
    });
  }

  // Reset password with code
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _apiService.post('/auth/password/confirm', data: {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }
}
