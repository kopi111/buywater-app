import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/order.dart';

enum PaymentMethod {
  card,
  nfc,
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorCode;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorCode,
  });
}

class PaymentService {
  final Dio _dio = Dio();

  // Process card payment through NCB Gateway
  Future<PaymentResult> processCardPayment({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
    required String cardHolderName,
    required double amount,
    required String orderId,
    required String customerEmail,
  }) async {
    try {
      // NCB Payment Gateway Integration
      // This is a placeholder - replace with actual NCB API implementation
      final response = await _dio.post(
        '${AppConfig.ncbPaymentUrl}/process',
        data: {
          'merchant_id': AppConfig.ncbMerchantId,
          'api_key': AppConfig.ncbApiKey,
          'card_number': cardNumber,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'cvv': cvv,
          'card_holder_name': cardHolderName,
          'amount': amount,
          'currency': AppConfig.currencyCode,
          'order_id': orderId,
          'customer_email': customerEmail,
          'description': 'NCB Shop Order #$orderId',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.ncbApiKey}',
          },
        ),
      );

      final data = response.data;

      if (data['status'] == 'success' || data['status'] == 'approved') {
        return PaymentResult(
          success: true,
          transactionId: data['transaction_id'],
          message: 'Payment successful',
        );
      } else {
        return PaymentResult(
          success: false,
          message: data['message'] ?? 'Payment failed',
          errorCode: data['error_code'],
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment processing error: ${e.toString()}',
      );
    }
  }

  // Validate card number using Luhn algorithm
  bool validateCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;

    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Get card type from number
  String getCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanNumber.startsWith('4')) {
      return 'Visa';
    } else if (cleanNumber.startsWith('5') ||
               (int.tryParse(cleanNumber.substring(0, 2)) ?? 0) >= 51 &&
               (int.tryParse(cleanNumber.substring(0, 2)) ?? 0) <= 55) {
      return 'Mastercard';
    } else if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return 'American Express';
    } else if (cleanNumber.startsWith('6011') || cleanNumber.startsWith('65')) {
      return 'Discover';
    }

    return 'Unknown';
  }

  // Validate expiry date
  bool validateExpiryDate(String month, String year) {
    try {
      final now = DateTime.now();
      final expiryMonth = int.parse(month);
      int expiryYear = int.parse(year);

      // Handle 2-digit year
      if (expiryYear < 100) {
        expiryYear += 2000;
      }

      if (expiryMonth < 1 || expiryMonth > 12) {
        return false;
      }

      final expiry = DateTime(expiryYear, expiryMonth + 1, 0);
      return expiry.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // Validate CVV
  bool validateCVV(String cvv, String cardType) {
    final cleanCVV = cvv.replaceAll(RegExp(r'\D'), '');

    if (cardType == 'American Express') {
      return cleanCVV.length == 4;
    }

    return cleanCVV.length == 3;
  }

  // Refund payment
  Future<PaymentResult> refundPayment({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConfig.ncbPaymentUrl}/refund',
        data: {
          'merchant_id': AppConfig.ncbMerchantId,
          'api_key': AppConfig.ncbApiKey,
          'transaction_id': transactionId,
          'amount': amount,
          'reason': reason,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${AppConfig.ncbApiKey}',
          },
        ),
      );

      final data = response.data;

      return PaymentResult(
        success: data['status'] == 'success',
        transactionId: data['refund_id'],
        message: data['message'],
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Refund processing error: ${e.toString()}',
      );
    }
  }

  // Get transaction status
  Future<Map<String, dynamic>?> getTransactionStatus(String transactionId) async {
    try {
      final response = await _dio.get(
        '${AppConfig.ncbPaymentUrl}/transaction/$transactionId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.ncbApiKey}',
          },
        ),
      );

      return response.data;
    } catch (e) {
      return null;
    }
  }
}
