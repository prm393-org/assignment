import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/data/local/order_cache.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';
import 'package:chuoi_xanh_viet/features/order/domain/repositories/order_repository.dart';

/// Decorates the REST [OrderRepository] with a read-through SharedPreferences
/// cache. Only the four read methods fall back to a cached snapshot, and
/// only on [NetworkFailure] (a real offline signal) — validation/auth
/// errors are real errors and are never masked by stale data. Checkout
/// (`createOrder`) and the write methods pass straight through, untouched.
class CachedOrderRepository implements OrderRepository {
  CachedOrderRepository(this._inner, [OrderCache? cache])
      : _cache = cache ?? OrderCache();

  final OrderRepository _inner;
  final OrderCache _cache;

  @override
  Future<OrderEntity> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    String paymentMethod = 'cod',
    String? note,
  }) async {
    final order = await _inner.createOrder(
      shopId: shopId,
      items: items,
      shippingName: shippingName,
      shippingPhone: shippingPhone,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      note: note,
    );
    // Drop stale list snapshots so the next read hits the API.
    await _cache.clearMine();
    await _cache.clearShop();
    return order;
  }

  @override
  Future<PaginatedResult<OrderEntity>> getMyOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final result = await _inner.getMyOrders(page: page, status: status);
      await _cache.writeMine(result);
      return result;
    } on NetworkFailure {
      final cached = await _cache.readMine();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<PaginatedResult<OrderEntity>> getShopOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final result = await _inner.getShopOrders(page: page, status: status);
      await _cache.writeShop(result);
      return result;
    } on NetworkFailure {
      final cached = await _cache.readShop();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    try {
      final result = await _inner.getOrderById(orderId);
      await _cache.writeDetail(orderId, result);
      return result;
    } on NetworkFailure {
      final cached = await _cache.readDetail(orderId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<ShopEarnings> getShopEarnings() async {
    try {
      final result = await _inner.getShopEarnings();
      await _cache.writeEarnings(result);
      return result;
    } on NetworkFailure {
      final cached = await _cache.readEarnings();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) async {
    final order = await _inner.cancelOrder(orderId);
    await _cache.clearMine();
    await _cache.clearShop();
    return order;
  }

  @override
  Future<OrderEntity> updateOrderStatus(String orderId, String status) async {
    final order = await _inner.updateOrderStatus(orderId, status);
    await _cache.clearMine();
    await _cache.clearShop();
    return order;
  }
}
