import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics events used by the app's required reports.
abstract final class AnalyticsService {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  static Future<void> setUser({
    required String userId,
    required String role,
  }) async {
    try {
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'user_role', value: role);
    } catch (_) {}
  }

  static Future<void> clearUser() async {
    try {
      await _analytics.setUserId(id: null);
      await _analytics.setUserProperty(name: 'user_role', value: 'guest');
    } catch (_) {}
  }

  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  static Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (_) {}
  }

  static Future<void> logAddToCart({
    required String productId,
    required String productName,
    required String shopName,
    required String unit,
    required double price,
    required int quantity,
  }) async {
    try {
      await _analytics.logAddToCart(
        currency: 'VND',
        value: price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productName,
            affiliation: shopName,
            itemVariant: unit,
            price: price,
            quantity: quantity,
          ),
        ],
      );
    } catch (_) {}
  }

  static Future<void> logBeginCheckout({
    required double value,
    required int itemCount,
  }) async {
    try {
      await _analytics.logBeginCheckout(
        currency: 'VND',
        value: value,
        parameters: {'item_count': itemCount},
      );
    } catch (_) {}
  }

  static Future<void> logPurchase({
    required String transactionId,
    required double value,
    required double shipping,
    required String paymentMethod,
    required int itemCount,
  }) async {
    try {
      await _analytics.logPurchase(
        transactionId: transactionId,
        currency: 'VND',
        value: value,
        shipping: shipping,
        parameters: {'payment_method': paymentMethod, 'item_count': itemCount},
      );
    } catch (_) {}
  }

  static Future<void> logScanQr(String context) async {
    try {
      await _analytics.logEvent(
        name: 'scan_QR',
        parameters: {'scan_context': context},
      );
    } catch (_) {}
  }
}
