import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';

abstract class OrderRepository {
  Future<OrderEntity> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    String paymentMethod = 'cod',
    String? note,
  });

  Future<PaginatedResult<OrderEntity>> getMyOrders({int page = 1, String? status});
  Future<PaginatedResult<OrderEntity>> getShopOrders({int page = 1, String? status});
  Future<OrderEntity> getOrderById(String orderId);
  Future<OrderEntity> cancelOrder(String orderId);
  Future<OrderEntity> updateOrderStatus(String orderId, String status);
  Future<ShopEarnings> getShopEarnings();
}
