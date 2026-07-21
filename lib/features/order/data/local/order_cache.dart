import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';

/// Last-known-good snapshots of order data, read only when a live REST call
/// fails with a [NetworkFailure] — see `CachedOrderRepository`. Checkout
/// (`createOrder`) never goes through here.
class OrderCache {
  static const _mineKey = 'order_cache_mine';
  static const _shopKey = 'order_cache_shop';
  static const _detailKey = 'order_cache_detail';
  static const _earningsKey = 'order_cache_earnings';

  Future<PaginatedResult<OrderEntity>?> readMine() => _readList(_mineKey);
  Future<void> writeMine(PaginatedResult<OrderEntity> result) =>
      _writeList(_mineKey, result);

  Future<PaginatedResult<OrderEntity>?> readShop() => _readList(_shopKey);
  Future<void> writeShop(PaginatedResult<OrderEntity> result) =>
      _writeList(_shopKey, result);

  Future<OrderEntity?> readDetail(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_detailKey);
    if (raw == null || raw.isEmpty) return null;
    final map = asMap(jsonDecode(raw));
    final orderRaw = map[orderId];
    if (orderRaw == null) return null;
    return OrderEntity.fromJson(asMap(orderRaw));
  }

  Future<void> writeDetail(String orderId, OrderEntity order) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_detailKey);
    final map = raw == null || raw.isEmpty ? <String, dynamic>{} : asMap(jsonDecode(raw));
    map[orderId] = order.toJson();
    await prefs.setString(_detailKey, jsonEncode(map));
  }

  Future<ShopEarnings?> readEarnings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_earningsKey);
    if (raw == null || raw.isEmpty) return null;
    return ShopEarnings.fromJson(asMap(jsonDecode(raw)));
  }

  Future<void> writeEarnings(ShopEarnings earnings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_earningsKey, jsonEncode(earnings.toJson()));
  }

  Future<PaginatedResult<OrderEntity>?> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final map = asMap(jsonDecode(raw));
    return PaginatedResult(
      items: mapList(map['items'], OrderEntity.fromJson),
      total: readInt(map, ['total']),
      page: readInt(map, ['page'], 1),
      limit: readInt(map, ['limit'], 20),
    );
  }

  Future<void> _writeList(String key, PaginatedResult<OrderEntity> result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'items': result.items.map((e) => e.toJson()).toList(),
        'total': result.total,
        'page': result.page,
        'limit': result.limit,
      }),
    );
  }
}
