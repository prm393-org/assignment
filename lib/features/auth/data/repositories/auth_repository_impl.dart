import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/network/auth_token_holder.dart';
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
      await _ensureFirebaseShadowAccount(email: email, password: password);
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
      final idToken = await firebaseUser?.getIdToken();
      if (firebaseUser == null || idToken == null || idToken.isEmpty) {
        throw const AuthFailure('Không nhận được thông tin từ Google');
      }

      final session = AuthSession(
        accessToken: idToken,
        user: AuthUser(
          id: firebaseUser.uid,
          fullName:
              firebaseUser.displayName ??
              firebaseUser.email?.split('@').first ??
              'Người dùng Google',
          email: firebaseUser.email ?? '',
          phone: firebaseUser.phoneNumber ?? '',
          role: 'consumer',
          status: 'active',
          avatarUrl: firebaseUser.photoURL,
        ),
      );
      await persistSession(session);
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
      await _ensureFirebaseShadowAccount(email: email, password: password);
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
    var session = await _local.read();
    final firebaseUser = _firebaseAuth?.currentUser;
    if (session?.user?.id == firebaseUser?.uid) {
      final refreshedToken = await firebaseUser?.getIdToken();
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        session = session!.copyWith(accessToken: refreshedToken);
        await _local.save(session);
      }
    }
    if (session != null) {
      authTokenHolder.accessToken = session.accessToken;
    }
    return session;
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

  /// Backend email/password logins never touch Firebase Auth, so
  /// `FirebaseAuth.instance.currentUser` stays null for them and Firestore
  /// security rules (keyed on `request.auth.uid`) can't recognize them.
  /// This mirrors every successful backend login/register into a Firebase
  /// Auth account with the same email/password, giving these users a real,
  /// stable uid too. Never throws — Firestore sync is best-effort and must
  /// not block the real REST login/register.
  Future<void> _ensureFirebaseShadowAccount({
    required String email,
    required String password,
  }) async {
    final firebaseAuth = _firebaseAuth;
    if (firebaseAuth == null) return;
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        try {
          await firebaseAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          // Shadow account creation failed; Firestore-backed features for
          // this user simply stay unsynced until the next successful login.
        }
      }
      // Other codes (wrong-password/invalid-credential) mean the shadow
      // account's password drifted from the backend's — leave it stale
      // rather than fail the real login.
    } catch (_) {
      // Best-effort; never block the real REST login/register.
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
