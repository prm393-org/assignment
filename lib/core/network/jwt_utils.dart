import 'dart:convert';

/// Decode JWT `exp` without verifying signature (client-side UX only).
bool isJwtExpired(
  String token, {
  Duration skew = const Duration(seconds: 60),
}) {
  final exp = readJwtExpiry(token);
  if (exp == null) return false;
  return DateTime.now().isAfter(exp.subtract(skew));
}

DateTime? readJwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final normalized = base64Url.normalize(parts[1]);
    final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (payload is! Map) return null;
    final exp = payload['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    if (exp is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (exp * 1000).round(),
        isUtc: true,
      );
    }
    return null;
  } catch (_) {
    return null;
  }
}

bool looksLikeAuthExpiredMessage(String? message) {
  if (message == null || message.isEmpty) return false;
  final m = message.toLowerCase();
  return m.contains('jwt expired') ||
      m.contains('token expired') ||
      m.contains('jwt malformed') ||
      m.contains('invalid token') ||
      m.contains('unauthorized') ||
      m.contains('phiên đăng nhập');
}
