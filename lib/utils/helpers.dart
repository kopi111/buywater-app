import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

class Helpers {
  // Format currency (JMD)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '${AppConfig.currencySymbol} ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Format date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  // Format relative date
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number (Jamaica format)
  static bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(\+1)?876\d{7}$').hasMatch(cleanPhone) ||
           RegExp(r'^\d{7}$').hasMatch(cleanPhone) ||
           RegExp(r'^\d{10}$').hasMatch(cleanPhone);
  }

  // Format phone number
  static String formatPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 7) {
      return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3)}';
    } else if (cleanPhone.length == 10) {
      return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 11 && cleanPhone.startsWith('1')) {
      return '+1 (${cleanPhone.substring(1, 4)}) ${cleanPhone.substring(4, 7)}-${cleanPhone.substring(7)}';
    }
    return phone;
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  // Calculate discount percentage
  static int calculateDiscountPercentage(double originalPrice, double discountPrice) {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - discountPrice) / originalPrice * 100).round();
  }

  // Generate order number
  static String generateOrderNumber() {
    final now = DateTime.now();
    return 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
  }
}
