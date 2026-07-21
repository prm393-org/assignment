import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/repositories/marketplace_repository.dart';

const marketplaceRegions = <String>[
  'Tất cả',
  'TP. Hồ Chí Minh',
  'Hà Nội',
  'Đà Nẵng',
  'Đồng Nai',
  'Long An',
];

const _regionPrefsKey = 'marketplace_region';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepositoryImpl(ref.watch(dioProvider));
});

final marketplaceRegionProvider =
    StateNotifierProvider<MarketplaceRegionNotifier, String>((ref) {
  return MarketplaceRegionNotifier();
});

class MarketplaceRegionNotifier extends StateNotifier<String> {
  MarketplaceRegionNotifier() : super('Tất cả') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_regionPrefsKey);
    if (stored != null && marketplaceRegions.contains(stored)) {
      state = stored;
    }
  }

  Future<void> setRegion(String region) async {
    state = region;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionPrefsKey, region);
  }
}

final productsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Product>, MarketplaceFilter>((ref, filter) {
  return ref.watch(marketplaceRepositoryProvider).getProducts(filter: filter);
});

final shopsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ShopSummary>, MarketplaceFilter>((ref, filter) {
  return ref.watch(marketplaceRepositoryProvider).getShops(filter: filter);
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
    .family<PaginatedResult<Product>, ({String shopId, int page})>((ref, args) {
  return ref.watch(marketplaceRepositoryProvider).getShopProducts(
        args.shopId,
        page: args.page,
        limit: 12,
      );
});

/// Back-compat for call sites that only pass shopId.
final shopProductsSimpleProvider = FutureProvider.autoDispose
    .family<PaginatedResult<Product>, String>((ref, shopId) {
  return ref.watch(shopProductsProvider((shopId: shopId, page: 1)).future);
});

final highlightProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final region = ref.watch(marketplaceRegionProvider);
  final page = await ref.watch(marketplaceRepositoryProvider).getProducts(
        filter: MarketplaceFilter(
          limit: 12,
          province: region == 'Tất cả' ? null : region,
          sort: 'newest',
        ),
      );
  final items = [...page.items];
  items.sort((a, b) {
    final aStock = (a.stockQty ?? 1) > 0 ? 1 : 0;
    final bStock = (b.stockQty ?? 1) > 0 ? 1 : 0;
    if (aStock != bStock) return bStock.compareTo(aStock);
    final aVer = a.shop?.isVerified == true ? 1 : 0;
    final bVer = b.shop?.isVerified == true ? 1 : 0;
    return bVer.compareTo(aVer);
  });
  return items.take(8).toList();
});

final highlightShopsProvider =
    FutureProvider.autoDispose<List<ShopSummary>>((ref) async {
  final region = ref.watch(marketplaceRegionProvider);
  final page = await ref.watch(marketplaceRepositoryProvider).getShops(
        filter: MarketplaceFilter(
          limit: 8,
          province: region == 'Tất cả' ? null : region,
        ),
      );
  final items = [...page.items];
  items.sort((a, b) {
    final aVer = a.isVerified ? 1 : 0;
    final bVer = b.isVerified ? 1 : 0;
    if (aVer != bVer) return bVer.compareTo(aVer);
    return (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
  });
  return items;
});
