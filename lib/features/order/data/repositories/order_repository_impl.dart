import 'dart:async';

import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/firebase/fcm_topics.dart';
import 'package:chuoi_xanh_viet/core/firebase/order_live_sync.dart';
import 'package:chuoi_xanh_viet/core/firebase/push_sender.dart';
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
      final order = OrderEntity.fromJson(data);
      // Push "new order" to the shop's owner (subscribed to shop_<id>).
      unawaited(PushSender.sendToTopic(
        topic: FcmTopics.shop(shopId),
        title: 'Đơn hàng mới',
        body: 'Bạn có một đơn hàng mới cần xử lý.',
        link: '/farmer/orders/${order.id}',
      ));
      return order;
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
        'status': ?status,
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
        'status': ?status,
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
  Future<OrderEntity> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await _dio.patch('/order/$orderId/status', data: {'status': status});
      final order = OrderEntity.fromJson(asMap(unwrapData(res.data)));
      final id = order.id.isNotEmpty ? order.id : orderId;
      final newStatus = order.status.isNotEmpty ? order.status : status;
      await OrderLiveSync.publishStatus(orderId: id, status: newStatus);
      // Push status change to the buyer (subscribed to order_<id> at checkout).
      unawaited(PushSender.sendToTopic(
        topic: FcmTopics.order(id),
        title: 'Cập nhật đơn hàng',
        body: 'Trạng thái đơn hàng của bạn: $newStatus',
        link: '/consumer/orders/$id',
      ));
      return order;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) async {
    try {
      final res = await _dio.patch('/order/$orderId/cancel');
      final order = OrderEntity.fromJson(asMap(unwrapData(res.data)));
      final id = order.id.isNotEmpty ? order.id : orderId;
      final newStatus = order.status.isNotEmpty ? order.status : 'cancelled';
      await OrderLiveSync.publishStatus(orderId: id, status: newStatus);
      unawaited(PushSender.sendToTopic(
        topic: FcmTopics.order(id),
        title: 'Đơn hàng đã huỷ',
        body: 'Đơn hàng của bạn đã được huỷ.',
        link: '/consumer/orders/$id',
      ));
      return order;
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
