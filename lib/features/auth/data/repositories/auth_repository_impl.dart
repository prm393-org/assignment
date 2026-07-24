import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/network/auth_token_holder.dart';
import 'package:chuoi_xanh_viet/core/network/jwt_utils.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_user.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/repositories/auth_repository.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return asMap(res.data);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await _dio.post('/auth/register', data: body);
    return asMap(res.data);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> verifyForgotPassword(String token) async {
    await _dio.post('/auth/verify-forgot-password', data: {
      'forgot_password_token': token,
    });
  }

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    await _dio.post('/auth/reset-password', data: {
      'forgot_password_token': token,
      'password': password,
      'confirm_password': confirmPassword,
    });
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final res = await _dio.patch('/auth/me', data: body);
    return asMap(unwrapData(res.data));
  }
}

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'access_token';
  static const _userKey = 'auth_user';
  static const _shadowEmailKey = 'firebase_shadow_email';
  static const _shadowPasswordKey = 'firebase_shadow_password';

  Future<void> saveShadowCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _shadowEmailKey, value: email.trim());
    await _storage.write(key: _shadowPasswordKey, value: password);
  }

  Future<({String email, String password})?> readShadowCredentials() async {
    final email = await _storage.read(key: _shadowEmailKey);
    final password = await _storage.read(key: _shadowPasswordKey);
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return (email: email, password: password);
  }

  Future<void> clearShadowCredentials() async {
    await _storage.delete(key: _shadowEmailKey);
    await _storage.delete(key: _shadowPasswordKey);
  }

  Future<void> save(AuthSession session) async {
    if (session.accessToken == null || session.user == null) {
      await clear();
      return;
    }
    await _storage.write(key: _tokenKey, value: session.accessToken);
    await _storage.write(
      key: _userKey,
      value: jsonEncode(session.user!.toJson()),
    );
  }

  Future<AuthSession?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final userRaw = await _storage.read(key: _userKey);
    if (token == null || userRaw == null) return null;
    final user = AuthUser.fromJson(asMap(jsonDecode(userRaw)));
    return AuthSession(accessToken: token, user: user);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    await clearShadowCredentials();
  }
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required firebase_auth.FirebaseAuth? firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _remote = remote,
       _local = local,
       _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final firebase_auth.FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = await _remote.login(email, password);
      final session = _parseSession(body);
      await persistSession(session);
      await _local.saveShadowCredentials(email: email, password: password);
      await _ensureFirebaseShadowAccount(
        backendUserId: session.user!.id,
        legacyEmail: email,
        legacyPassword: password,
      );
      return session;
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthSession?> loginWithGoogle() async {
    try {
      final firebaseAuth = _firebaseAuth;
      if (firebaseAuth == null) {
        throw const AuthFailure('Firebase chưa được khởi tạo');
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await firebaseAuth.signInWithCredential(credential);
      final firebaseUser = result.user;
      final email = firebaseUser?.email?.trim() ?? '';
      if (firebaseUser == null || email.isEmpty) {
        throw const AuthFailure('Tài khoản Google không có email');
      }

      // Backend only accepts its own HS256 JWT. Bridge Google → REST by
      // login/register with a stable password derived from Firebase uid.
      final session = await _bridgeGoogleToBackend(
        firebaseUid: firebaseUser.uid,
        email: email,
        fullName:
            firebaseUser.displayName?.trim().isNotEmpty == true
                ? firebaseUser.displayName!.trim()
                : email.split('@').first,
        avatarUrl: firebaseUser.photoURL,
      );
      await persistSession(session);
      await _local.clearShadowCredentials();
      return session;
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError) return null;
      if (e.code == GoogleSignIn.kNetworkError) {
        throw const NetworkFailure();
      }
      throw const AuthFailure('Không thể đăng nhập bằng Google');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthFailure(e.message ?? 'Firebase không thể xác thực tài khoản');
    } catch (e) {
      if (e is Failure) rethrow;
      throw const AuthFailure('Không thể đăng nhập bằng Google');
    }
  }

  /// Exchanges a Firebase Google session for a backend JWT without a BE
  /// Google endpoint: login with a deterministic password, or register once.
  Future<AuthSession> _bridgeGoogleToBackend({
    required String firebaseUid,
    required String email,
    required String fullName,
    String? avatarUrl,
  }) async {
    final password = _googleBridgePassword(firebaseUid);

    try {
      final body = await _remote.login(email, password);
      return _parseSession(body);
    } catch (_) {
      // Fall through to register when login fails (new Google user).
    }

    Failure? lastFailure;
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final body = await _remote.register({
          'email': email,
          'password': password,
          'confirm_password': password,
          'full_name': fullName,
          'phone': _googleBridgePhone(firebaseUid, attempt),
          'role': 'consumer',
        });
        var session = _parseSession(body);
        authTokenHolder.accessToken = session.accessToken;
        if (avatarUrl != null &&
            avatarUrl.isNotEmpty &&
            (session.user?.avatarUrl == null ||
                session.user!.avatarUrl!.isEmpty)) {
          try {
            final raw = await _remote.updateMe({'avatarUrl': avatarUrl});
            session = AuthSession(
              accessToken: session.accessToken,
              user: AuthUser.fromJson(raw),
            );
          } catch (_) {
            // Avatar sync is best-effort.
          }
        }
        return session;
      } catch (e) {
        final failure = e is Failure ? e : mapDioException(e);
        lastFailure = failure;
        final msg = failure.message.toLowerCase();
        if (msg.contains('email') &&
            (msg.contains('exist') || msg.contains('sử dụng'))) {
          throw const AuthFailure(
            'Email này đã đăng ký bằng mật khẩu. '
            'Hãy đăng nhập bằng email/mật khẩu.',
          );
        }
        if ((msg.contains('phone') || msg.contains('điện thoại')) &&
            (msg.contains('exist') || msg.contains('sử dụng'))) {
          continue;
        }
        throw failure;
      }
    }

    throw lastFailure ??
        const AuthFailure('Không thể tạo tài khoản từ Google');
  }

  /// Stable backend password for a Google uid (assignment bridge only).
  static String _googleBridgePassword(String firebaseUid) =>
      'Gx_${firebaseUid}_CxV2026!';

  /// Unique synthetic phone (8–20 chars) derived from uid + attempt.
  static String _googleBridgePhone(String firebaseUid, int attempt) {
    final digits = StringBuffer();
    for (final unit in firebaseUid.codeUnits) {
      digits.write(unit % 10);
    }
    final raw = '${digits.toString()}$attempt'.padRight(9, '0');
    return '09${raw.substring(0, 9)}';
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final body = await _remote.register({
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'full_name': fullName,
        'phone': phone,
        'role': role,
      });
      final session = _parseSession(body);
      await persistSession(session);
      await _local.saveShadowCredentials(email: email, password: password);
      await _ensureFirebaseShadowAccount(
        backendUserId: session.user!.id,
        legacyEmail: email,
        legacyPassword: password,
      );
      return session;
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapDioException(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> verifyForgotPassword(String token) async {
    try {
      await _remote.verifyForgotPassword(token);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _remote.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthUser> updateProfile(Map<String, dynamic> body) async {
    try {
      final raw = await _remote.updateMe(body);
      final user = AuthUser.fromJson(raw);
      final token = authTokenHolder.accessToken;
      if (token != null) {
        await persistSession(AuthSession(accessToken: token, user: user));
      }
      return user;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    // Always restore the backend JWT. Never replace it with a Firebase
    // idToken (RS256) — the REST API only accepts HS256 tokens.
    final session = await _local.read();
    if (session == null) return null;

    final token = session.accessToken;
    if (token != null && token.isNotEmpty && isJwtExpired(token)) {
      final refreshed = await refreshBackendJwt();
      if (refreshed != null) return refreshed;
      await clearSession();
      return null;
    }

    authTokenHolder.accessToken = session.accessToken;
    await ensureFirebaseAuthHydrated();
    return session;
  }

  @override
  Future<void> ensureFirebaseAuthHydrated() async {
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null) return;
    if (firebaseAuth.currentUser != null) return;

    final session = await _local.read();
    final backendUserId = session?.user?.id;
    final creds = await _local.readShadowCredentials();

    // Email/password session — prefer shadow account, not Google silent.
    if (creds != null && backendUserId != null && backendUserId.isNotEmpty) {
      await _ensureFirebaseShadowAccount(
        backendUserId: backendUserId,
        legacyEmail: creds.email,
        legacyPassword: creds.password,
      );
      if (firebaseAuth.currentUser != null) {
        if (kDebugMode) {
          debugPrint(
            'Firebase Auth hydrated via email shadow: '
            '${firebaseAuth.currentUser?.uid}',
          );
        }
        return;
      }
    } else if (backendUserId != null && backendUserId.isNotEmpty) {
      await _ensureFirebaseShadowAccount(backendUserId: backendUserId);
      if (firebaseAuth.currentUser != null) return;
    }

    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await firebaseAuth.signInWithCredential(credential);
        if (kDebugMode) {
          debugPrint('Firebase Auth hydrated via Google silent sign-in');
        }
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Google silent sign-in failed: $e');
    }

    try {
      await firebaseAuth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 2));
      if (kDebugMode) {
        debugPrint('Firebase Auth hydrated from persisted session');
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          'Firebase Auth still null — RTDB/Firestore cần đăng xuất '
          'rồi đăng nhập lại (Email/Password phải bật trên Firebase Console).',
        );
      }
    }
  }

  @override
  Future<AuthSession?> refreshBackendJwt() async {
    final firebaseAuth = _firebaseAuth;
    final fbUser = firebaseAuth?.currentUser;
    final email = fbUser?.email?.trim() ?? '';
    if (fbUser == null || email.isEmpty) return null;

    try {
      // Keep Firebase session warm; backend still needs HS256 from /auth/login.
      await fbUser.getIdToken(true);
    } catch (_) {
      // Continue; bridge login may still work.
    }

    try {
      // Google-bridged accounts use a deterministic password from Firebase uid.
      // Email/password users cannot be refreshed without the real password.
      final body = await _remote.login(
        email,
        _googleBridgePassword(fbUser.uid),
      );
      final session = _parseSession(body);
      await persistSession(session);
      return session;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> persistSession(AuthSession session) async {
    authTokenHolder.accessToken = session.accessToken;
    await _local.save(session);
  }

  @override
  Future<void> clearSession() async {
    authTokenHolder.accessToken = null;
    await _local.clear();
    try {
      await _firebaseAuth?.signOut();
      await _googleSignIn.signOut();
    } catch (_) {
      // The local app session is already cleared; external sign-out can retry.
    }
  }

  /// Stable Firebase password for email/password backend users (RTDB rules
  /// need Firebase Auth — separate from the user's backend password).
  static String _emailBridgePassword(String backendUserId) =>
      'Em_${backendUserId}_CxV2026!';

  /// Synthetic Firebase email — avoids clashing with Google/real-email accounts.
  static String _shadowFirebaseEmail(String backendUserId) =>
      'shadow+$backendUserId@chuoi-xanh.shadow';

  /// Mirrors backend email/password login into Firebase Auth for RTDB/Firestore.
  /// Never throws — must not block REST login/register.
  Future<void> _ensureFirebaseShadowAccount({
    required String backendUserId,
    String? legacyEmail,
    String? legacyPassword,
  }) async {
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null || backendUserId.isEmpty) return;

    // Drop any stale Google session so email-shadow sign-in is not blocked.
    try {
      await _googleSignIn.signOut();
      await firebaseAuth.signOut();
    } catch (_) {}

    final shadowEmail = _shadowFirebaseEmail(backendUserId);
    final bridgePassword = _emailBridgePassword(backendUserId);

    Future<bool> trySignIn(String email, String password) async {
      try {
        await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return firebaseAuth.currentUser != null;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') return false;
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return false;
        }
        rethrow;
      }
    }

    Future<bool> tryCreate(String email, String password) async {
      try {
        await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return firebaseAuth.currentUser != null;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') return false;
        if (kDebugMode) {
          debugPrint('Firebase shadow create failed: ${e.code} ${e.message}');
        }
        return false;
      }
    }

    // Primary: synthetic email + bridge password (never conflicts with Google).
    if (await trySignIn(shadowEmail, bridgePassword)) {
      if (kDebugMode) {
        debugPrint(
          'Firebase shadow ok: ${firebaseAuth.currentUser?.uid} ($shadowEmail)',
        );
      }
      return;
    }
    if (await tryCreate(shadowEmail, bridgePassword)) {
      if (kDebugMode) {
        debugPrint(
          'Firebase shadow created: ${firebaseAuth.currentUser?.uid} ($shadowEmail)',
        );
      }
      return;
    }
    if (await trySignIn(shadowEmail, bridgePassword)) {
      return;
    }

    // Legacy fallback: real email (older builds / manual Firebase users).
    final realEmail = legacyEmail?.trim();
    final legacy = legacyPassword?.trim();
    if (realEmail != null &&
        realEmail.isNotEmpty &&
        legacy != null &&
        legacy.isNotEmpty) {
      if (await trySignIn(realEmail, bridgePassword)) {
        if (kDebugMode) debugPrint('Firebase shadow ok (legacy bridge email)');
        return;
      }
      if (await tryCreate(realEmail, bridgePassword)) {
        if (kDebugMode) debugPrint('Firebase shadow created (legacy email)');
        return;
      }
      if (await trySignIn(realEmail, legacy)) {
        if (kDebugMode) debugPrint('Firebase shadow ok (legacy user password)');
        try {
          await firebaseAuth.currentUser?.updatePassword(bridgePassword);
        } catch (_) {}
        return;
      }
    }

    if (kDebugMode) {
      debugPrint(
        'Firebase shadow failed for backendUserId=$backendUserId. '
        'Kiểm tra Email/Password đã bật trên Firebase Console.',
      );
    }
  }

  AuthSession _parseSession(Map<String, dynamic> body) {
    final data = body.containsKey('data') ? asMap(body['data']) : body;
    final token = readStringOrNull(
          data,
          ['accessToken', 'access_token', 'token'],
        ) ??
        readStringOrNull(body, ['accessToken', 'access_token', 'token']);
    final rawUser = asMap(data['user'] ?? body['user'] ?? data['profile']);
    if (token == null || token.isEmpty || rawUser.isEmpty) {
      throw const AuthFailure('Không nhận được token từ server');
    }
    return AuthSession(
      accessToken: token,
      user: AuthUser.fromJson(rawUser),
    );
  }
}
