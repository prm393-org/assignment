import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_user.dart';

class AuthSession {
  const AuthSession({this.accessToken, this.user});

  final String? accessToken;
  final AuthUser? user;

  bool get isAuthenticated =>
      accessToken != null && accessToken!.isNotEmpty && user != null;

  AuthSession copyWith({String? accessToken, AuthUser? user, bool clear = false}) {
    if (clear) return const AuthSession();
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      user: user ?? this.user,
    );
  }
}

abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession?> loginWithGoogle();

  Future<AuthSession> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String phone,
    required String role,
  });

  Future<void> forgotPassword(String email);

  Future<void> verifyForgotPassword(String token);

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  });

  Future<AuthUser> updateProfile(Map<String, dynamic> body);

  Future<AuthSession?> restoreSession();

  /// Re-issues backend HS256 JWT when Firebase session is still alive
  /// (Google bridge). Returns null if refresh is not possible.
  Future<AuthSession?> refreshBackendJwt();

  Future<void> persistSession(AuthSession session);

  Future<void> clearSession();
}
