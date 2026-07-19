import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/repositories/marketplace_repository.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl(ref.watch(dioProvider));
});

final productsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Product>, String>((ref, search) async {
  return ref.watch(marketplaceRepositoryProvider).getProducts(
        searchTerm: search.isEmpty ? null : search,
        limit: 40,
      );
});

final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) {
  return ref.watch(marketplaceRepositoryProvider).getProductById(id);
});

final shopDetailProvider =
    FutureProvider.autoDispose.family<ShopSummary, String>((ref, id) {
  return ref.watch(marketplaceRepositoryProvider).getShopById(id);
});

final shopProductsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Product>, String>((ref, shopId) {
  return ref.watch(marketplaceRepositoryProvider).getShopProducts(shopId);
});

final highlightProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final page =
      await ref.watch(marketplaceRepositoryProvider).getProducts(limit: 8);
  return page.items;
});
