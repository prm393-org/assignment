class AuthTokenHolder {
  String? accessToken;
}

/// Mutable token holder shared by Dio interceptor (avoids circular Riverpod deps).
final authTokenHolder = AuthTokenHolder();
