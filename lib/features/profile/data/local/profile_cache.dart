import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_user.dart';

/// Mirrors the logged-in `AuthUser` into SharedPreferences so profile data
/// is available instantly on app start, before the API/session restore
/// completes. The backend (`PATCH /auth/me`) stays the only write path —
/// this cache is read-through only, refreshed by `AuthNotifier` whenever
/// the session's user changes.
class ProfileCache {
  static const _key = 'profile_cache';

  Future<AuthUser?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return AuthUser.fromJson(asMap(jsonDecode(raw)));
  }

  Future<void> write(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
