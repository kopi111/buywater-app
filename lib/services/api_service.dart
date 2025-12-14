import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token expiration
          _storage.delete(key: 'auth_token');
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Generic GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic DELETE request
  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    String message = 'An error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (responseData is Map && responseData.containsKey('message')) {
          message = responseData['message'];
        } else {
          switch (statusCode) {
            case 400:
              message = 'Bad request';
              break;
            case 401:
              message = 'Unauthorized. Please login again.';
              break;
            case 403:
              message = 'Access denied';
              break;
            case 404:
              message = 'Resource not found';
              break;
            case 500:
              message = 'Server error. Please try again later.';
              break;
            default:
              message = 'Something went wrong';
          }
        }
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection';
        break;
      default:
        message = 'Something went wrong';
    }

    return Exception(message);
  }
}
