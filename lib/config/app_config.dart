class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://api.buywater.com/v1';

  // NCB Payment Gateway Configuration
  // Replace with actual NCB merchant credentials
  static const String ncbMerchantId = 'YOUR_NCB_MERCHANT_ID';
  static const String ncbApiKey = 'YOUR_NCB_API_KEY';
  static const String ncbPaymentUrl = 'https://payment.ncb.com.jm/api';

  // App Information
  static const String appName = 'BuyWater';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@buywater.com';
  static const String supportPhone = '+1 876-XXX-XXXX';

  // Demo Mode
  static bool isDemoMode = false;

  // Currency
  static const String currencyCode = 'JMD';
  static const String currencySymbol = '\$';

  // Delivery Configuration
  static const double standardDeliveryFee = 500.0;
  static const double expressDeliveryFee = 1000.0;
  static const double freeDeliveryThreshold = 10000.0;

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Pagination
  static const int productsPerPage = 20;
  static const int ordersPerPage = 10;
}
