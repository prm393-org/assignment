import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Thin Crashlytics facade — safe no-ops when Firebase isn't ready.
abstract final class CrashlyticsService {
  static FirebaseCrashlytics get _c => FirebaseCrashlytics.instance;

  static Future<void> bootstrap({
    required String appVersion,
    required String buildNumber,
  }) async {
    try {
      // Collect in release; keep on in debug so the assignment can be verified.
      await _c.setCrashlyticsCollectionEnabled(true);
      await _c.setCustomKey('app_version', appVersion);
      await _c.setCustomKey('build_number', buildNumber);
      await _c.setCustomKey('platform', defaultTargetPlatform.name);
      if (!kIsWeb) {
        await _c.setCustomKey('os', Platform.operatingSystem);
        await _c.setCustomKey('os_version', Platform.operatingSystemVersion);
      }
      await _c.log('app_start version=$appVersion+$buildNumber');
    } catch (_) {}
  }

  static Future<void> setUser({
    String? firebaseUid,
    String? backendUserId,
    String? email,
    String? role,
  }) async {
    try {
      final id = firebaseUid ?? backendUserId;
      if (id != null && id.isNotEmpty) {
        await _c.setUserIdentifier(id);
      }
      if (backendUserId != null) {
        await _c.setCustomKey('backend_user_id', backendUserId);
      }
      if (firebaseUid != null) {
        await _c.setCustomKey('firebase_uid', firebaseUid);
      }
      if (email != null) await _c.setCustomKey('user_email', email);
      if (role != null) await _c.setCustomKey('user_role', role);
    } catch (_) {}
  }

  static Future<void> clearUser() async {
    try {
      await _c.setUserIdentifier('');
    } catch (_) {}
  }

  static Future<void> breadcrumb(String message) async {
    try {
      await _c.log(message);
    } catch (_) {}
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object>? keys,
  }) async {
    try {
      if (keys != null) {
        for (final e in keys.entries) {
          await _c.setCustomKey(e.key, e.value);
        }
      }
      await _c.recordError(
        error,
        stack ?? StackTrace.current,
        reason: reason,
        fatal: false,
      );
    } catch (_) {}
  }

  static void bindFlutterFatals() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(_c.recordFlutterFatalError(details));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(_c.recordError(error, stack, fatal: true));
      return true;
    };
  }
}
