import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';
import 'package:chuoi_xanh_viet/features/order/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._dio);
  final Dio _dio;

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
    try {
      final res = await _dio.post('/order', data: {
        'shop_id': shopId,
        'items': items,
        'shipping_name': shippingName,
        'shipping_phone': shippingPhone,
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      final data = asMap(unwrapData(res.data));
      return OrderEntity.fromJson(data);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<OrderEntity>> getMyOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final res = await _dio.get('/order/mine', queryParameters: {
        'page': page,
        'limit': 20,
        if (status != null) 'status': status,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), OrderEntity.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<OrderEntity>> getShopOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final res = await _dio.get('/order/shop', queryParameters: {
        'page': page,
        'limit': 20,
        if (status != null) 'status': status,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), OrderEntity.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    try {
      final res = await _dio.get('/order/$orderId');
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) async {
    try {
      final res = await _dio.patch('/order/$orderId/cancel');
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await _dio.patch('/order/$orderId/status', data: {'status': status});
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopEarnings> getShopEarnings() async {
    try {
      final res = await _dio.get('/order/shop/earnings');
      return ShopEarnings.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
