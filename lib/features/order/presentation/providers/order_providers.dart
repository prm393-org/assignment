import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/data/repositories/cached_order_repository.dart';
import 'package:chuoi_xanh_viet/features/order/data/repositories/order_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';
import 'package:chuoi_xanh_viet/features/order/domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return CachedOrderRepository(OrderRepositoryImpl(ref.watch(dioProvider)));
});

final myOrdersProvider =
    FutureProvider.autoDispose<PaginatedResult<OrderEntity>>((ref) {
  return ref.watch(orderRepositoryProvider).getMyOrders();
});

final shopOrdersProvider =
    FutureProvider.autoDispose<PaginatedResult<OrderEntity>>((ref) {
  return ref.watch(orderRepositoryProvider).getShopOrders();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderEntity, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrderById(id);
});

final shopEarningsProvider =
    FutureProvider.autoDispose<ShopEarnings>((ref) {
  return ref.watch(orderRepositoryProvider).getShopEarnings();
});
