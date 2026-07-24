import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/firebase/analytics_service.dart';
import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
import 'package:chuoi_xanh_viet/core/network/auth_session_coordinator.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_user.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/repositories/auth_repository.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_providers.dart';
import 'package:chuoi_xanh_viet/features/profile/data/local/profile_cache.dart';

class AuthState {
  const AuthState({
    this.accessToken,
    this.user,
    this.isBootstrapping = true,
    this.isLoading = false,
    this.errorMessage,
  });

  final String? accessToken;
  final AuthUser? user;
  final bool isBootstrapping;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated =>
      accessToken != null && accessToken!.isNotEmpty && user != null;

  AuthRole? get role => user?.authRole;

  AuthState copyWith({
    String? accessToken,
    AuthUser? user,
    bool? isBootstrapping,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      accessToken: clearSession ? null : (accessToken ?? this.accessToken),
      user: clearSession ? null : (user ?? this.user),
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    bootstrap();
  }

  final AuthRepository _repo;
  final _profileCache = ProfileCache();

  /// Sets [state] from a session and mirrors its user into the
  /// SharedPreferences profile cache (API stays the source of truth; this
  /// cache only makes it available before the API call resolves).
  Future<void> _applySession(AuthSession session) async {
    state = AuthState(
      accessToken: session.accessToken,
      user: session.user,
      isBootstrapping: false,
    );
    final user = session.user;
    if (user != null) await _profileCache.write(user);
    if (user != null) {
      await AnalyticsService.setUser(
        userId: user.id,
        role: user.authRole?.name ?? user.role.toLowerCase(),
      );
    }
    unawaited(CrashlyticsService.breadcrumb(
      'auth_session_applied role=${user?.role ?? 'unknown'}',
    ));
  }

  Future<void> bootstrap() async {
    unawaited(CrashlyticsService.breadcrumb('auth_bootstrap_start'));
    final session = await _repo.restoreSession();
    if (session != null) {
      await _applySession(session);
      unawaited(CrashlyticsService.breadcrumb('auth_bootstrap_restored'));
    } else {
      state = const AuthState(isBootstrapping: false);
      unawaited(AnalyticsService.clearUser());
      unawaited(CrashlyticsService.breadcrumb('auth_bootstrap_guest'));
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    unawaited(CrashlyticsService.breadcrumb('auth_login_email_start'));
    try {
      final session = await _repo.login(email: email, password: password);
      await _applySession(session);
      unawaited(AnalyticsService.logLogin('email'));
      unawaited(CrashlyticsService.breadcrumb('auth_login_email_ok'));
      return true;
    } catch (e) {
      unawaited(CrashlyticsService.breadcrumb('auth_login_email_fail'));
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    unawaited(CrashlyticsService.breadcrumb('auth_login_google_start'));
    try {
      final session = await _repo.loginWithGoogle();
      if (session == null) {
        state = state.copyWith(isLoading: false, clearError: true);
        unawaited(CrashlyticsService.breadcrumb('auth_login_google_cancel'));
        return false;
      }
      await _applySession(session);
      unawaited(AnalyticsService.logLogin('google'));
      unawaited(CrashlyticsService.breadcrumb('auth_login_google_ok'));
      return true;
    } catch (e) {
      unawaited(CrashlyticsService.breadcrumb('auth_login_google_fail'));
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    unawaited(CrashlyticsService.breadcrumb('auth_register_start role=$role'));
    try {
      final session = await _repo.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      await _applySession(session);
      unawaited(CrashlyticsService.breadcrumb('auth_register_ok'));
      return true;
    } catch (e) {
      unawaited(CrashlyticsService.breadcrumb('auth_register_fail'));
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is Failure ? e.message : e.toString(),
      );
      return false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _repo.forgotPassword(email);
      return null;
    } catch (e) {
      return e is Failure ? e.message : e.toString();
    }
  }

  Future<String?> verifyForgotPassword(String token) async {
    try {
      await _repo.verifyForgotPassword(token);
      return null;
    } catch (e) {
      return e is Failure ? e.message : e.toString();
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _repo.resetPassword(
        token: token,
        password: password,
        confirmPassword: confirmPassword,
      );
      return null;
    } catch (e) {
      return e is Failure ? e.message : e.toString();
    }
  }

  Future<void> applySession(AuthSession session) async {
    await _repo.persistSession(session);
    await _applySession(session);
  }

  /// Used by Dio when backend JWT cannot be refreshed.
  Future<void> forceLogoutExpired() async {
    if (!state.isAuthenticated && state.accessToken == null) return;
    unawaited(CrashlyticsService.breadcrumb('auth_session_expired'));
    await _repo.clearSession();
    state = const AuthState(
      isBootstrapping: false,
      errorMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    );
    await _profileCache.clear();
    unawaited(CrashlyticsService.clearUser());
  }

  Future<void> logout() async {
    unawaited(CrashlyticsService.breadcrumb('auth_logout'));
    await _repo.clearSession();
    state = const AuthState(isBootstrapping: false);
    await _profileCache.clear();
    unawaited(AnalyticsService.clearUser());
    unawaited(CrashlyticsService.clearUser());
  }

  void setUser(AuthUser user) {
    state = state.copyWith(user: user);
    unawaited(_profileCache.write(user));
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final notifier = AuthNotifier(repo);

  authSessionCoordinator.refresher = () async {
    final session = await repo.refreshBackendJwt();
    if (session == null) return null;
    await notifier.applySession(session);
    return session.accessToken;
  };
  authSessionCoordinator.onExpired = () => notifier.forceLogoutExpired();

  ref.onDispose(() {
    authSessionCoordinator.refresher = null;
    authSessionCoordinator.onExpired = null;
  });

  return notifier;
});
