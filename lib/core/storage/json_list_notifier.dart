import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

/// Base for a StateNotifier whose entire state is a `List<T>` mirrored to
/// SharedPreferences as JSON — the same persistence shape as
/// `CartNotifier`. Used for local offline queues (pending diary entries,
/// pending product drafts) that must survive an app restart until synced.
abstract class JsonListNotifier<T> extends StateNotifier<List<T>> {
  JsonListNotifier() : super(const []) {
    _hydrate();
  }

  String get storageKey;
  Map<String, dynamic> toJson(T item);
  T fromJson(Map<String, dynamic> json);

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return;
    final list = asList(jsonDecode(raw));
    state = list.whereType<Map>().map((e) => fromJson(asMap(e))).toList();
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(state.map(toJson).toList()));
  }
}
