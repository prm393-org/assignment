/// Deployed API host (no /v1/api suffix).
class ApiConfig {
  static const String apiHost = 'http://178.128.98.214:8001';
  static const String apiPrefix = '/v1/api';
  static String get baseUrl => '$apiHost$apiPrefix';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(seconds: 120);
  static const double shippingFeePerShop = 15000;
}
