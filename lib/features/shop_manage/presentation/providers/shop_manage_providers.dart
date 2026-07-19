import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/data/repositories/shop_manage_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/domain/repositories/shop_manage_repository.dart';

final shopManageRepositoryProvider = Provider<ShopManageRepository>((ref) {
  return ShopManageRepositoryImpl(ref.watch(dioProvider));
});

final myShopsProvider = FutureProvider.autoDispose<List<ShopSummary>>((ref) {
  return ref.watch(shopManageRepositoryProvider).getMyShops();
});

final availableSaleUnitsProvider = FutureProvider.autoDispose
    .family<List<AvailableSaleUnit>, String>((ref, shopId) {
  return ref.watch(shopManageRepositoryProvider).getAvailableSaleUnits(shopId);
});

final managedShopProvider =
    FutureProvider.autoDispose.family<ShopSummary, String>((ref, shopId) {
  return ref.watch(shopManageRepositoryProvider).getShop(shopId);
});

final managedShopProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, shopId) {
  return ref.watch(shopManageRepositoryProvider).getShopProducts(shopId);
});
