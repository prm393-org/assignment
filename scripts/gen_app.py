# -*- coding: utf-8 -*-
"""Generate remaining Flutter Clean Architecture app files."""
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')
TEST = Path(r'd:\fpt\ky8\PRM393\assignment\test')


def w(rel: str, content: str, root: Path = ROOT) -> None:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print('wrote', p.relative_to(root.parent if root == ROOT else root))


FILES: dict[str, str] = {}

# ---------------------------------------------------------------------------
# MARKETPLACE
# ---------------------------------------------------------------------------
FILES['features/marketplace/domain/entities/product.dart'] = r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class ProductShopInfo extends Equatable {
  const ProductShopInfo({
    required this.id,
    required this.name,
    this.description,
    this.isVerified = false,
    this.averageRating,
    this.reviewCount = 0,
    this.farmName,
    this.province,
  });

  final String id;
  final String name;
  final String? description;
  final bool isVerified;
  final double? averageRating;
  final int reviewCount;
  final String? farmName;
  final String? province;

  factory ProductShopInfo.fromJson(Map<String, dynamic> json) {
    final farms = asMap(json['farms'] ?? json['farm']);
    return ProductShopInfo(
      id: readString(json, ['id']),
      name: readString(json, ['name'], 'Gian hàng'),
      description: readStringOrNull(json, ['description']),
      isVerified: readBool(json, ['isVerified', 'is_verified']),
      averageRating: readNum(json, ['averageRating', 'average_rating'])?.toDouble(),
      reviewCount: readInt(json, ['reviewCount', 'review_count']),
      farmName: readStringOrNull(farms, ['name']),
      province: readStringOrNull(farms, ['province']),
    );
  }

  @override
  List<Object?> get props => [id, name];
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    this.description,
    this.unit,
    this.stockQty,
    this.imageUrl,
    this.isActive = true,
    this.shop,
    this.averageRating,
    this.reviewCount = 0,
    this.seasonId,
    this.seasonCode,
    this.cropName,
  });

  final String id;
  final String shopId;
  final String name;
  final double price;
  final String? description;
  final String? unit;
  final double? stockQty;
  final String? imageUrl;
  final bool isActive;
  final ProductShopInfo? shop;
  final double? averageRating;
  final int reviewCount;
  final String? seasonId;
  final String? seasonCode;
  final String? cropName;

  factory Product.fromJson(Map<String, dynamic> json) {
    final shops = asMap(json['shops'] ?? json['shop']);
    final seasons = asMap(json['seasons'] ?? json['season']);
    return Product(
      id: readString(json, ['id']),
      shopId: readString(json, ['shopId', 'shop_id']),
      name: readString(json, ['name']),
      price: readDouble(json, ['price']),
      description: readStringOrNull(json, ['description']),
      unit: readStringOrNull(json, ['unit']),
      stockQty: readNum(json, ['stockQty', 'stock_qty'])?.toDouble(),
      imageUrl: resolveMediaUrl(readStringOrNull(json, ['imageUrl', 'image_url'])),
      isActive: readBool(json, ['isActive', 'is_active'], true),
      shop: shops.isEmpty ? null : ProductShopInfo.fromJson(shops),
      averageRating: readNum(json, ['averageRating', 'average_rating'])?.toDouble(),
      reviewCount: readInt(json, ['reviewCount', 'review_count']),
      seasonId: readStringOrNull(seasons, ['id']) ??
          readStringOrNull(json, ['seasonId', 'season_id']),
      seasonCode: readStringOrNull(seasons, ['code']),
      cropName: readStringOrNull(seasons, ['cropName', 'crop_name']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class ShopSummary extends Equatable {
  const ShopSummary({
    required this.id,
    required this.name,
    required this.farmId,
    this.description,
    this.isVerified = false,
    this.status = '',
    this.averageRating,
    this.reviewCount = 0,
    this.farmName,
    this.province,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String farmId;
  final String? description;
  final bool isVerified;
  final String status;
  final double? averageRating;
  final int reviewCount;
  final String? farmName;
  final String? province;
  final String? avatarUrl;

  factory ShopSummary.fromJson(Map<String, dynamic> json) {
    final farms = asMap(json['farms'] ?? json['farm']);
    return ShopSummary(
      id: readString(json, ['id']),
      name: readString(json, ['name']),
      farmId: readString(json, ['farmId', 'farm_id']).isNotEmpty
          ? readString(json, ['farmId', 'farm_id'])
          : readString(farms, ['id']),
      description: readStringOrNull(json, ['description']),
      isVerified: readBool(json, ['isVerified', 'is_verified']),
      status: readString(json, ['status']),
      averageRating: readNum(json, ['averageRating', 'average_rating'])?.toDouble(),
      reviewCount: readInt(json, ['reviewCount', 'review_count']),
      farmName: readStringOrNull(farms, ['name']),
      province: readStringOrNull(farms, ['province']),
      avatarUrl: resolveMediaUrl(readStringOrNull(json, ['avatarUrl', 'avatar_url'])),
    );
  }

  @override
  List<Object?> get props => [id];
}
'''

FILES['features/marketplace/domain/repositories/marketplace_repository.dart'] = r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';

abstract class MarketplaceRepository {
  Future<PaginatedResult<Product>> getProducts({
    int page = 1,
    int limit = 20,
    String? searchTerm,
    String? shopId,
    String? sort,
  });

  Future<Product> getProductById(String productId);

  Future<ShopSummary> getShopById(String shopId);

  Future<PaginatedResult<Product>> getShopProducts(
    String shopId, {
    int page = 1,
    int limit = 20,
  });
}
'''

FILES['features/marketplace/data/repositories/marketplace_repository_impl.dart'] = r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  MarketplaceRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<Product>> getProducts({
    int page = 1,
    int limit = 20,
    String? searchTerm,
    String? shopId,
    String? sort,
  }) async {
    try {
      final res = await _dio.get('/shop/products', queryParameters: {
        'page': page,
        'limit': limit,
        if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
        if (shopId != null) 'shopId': shopId,
        if (sort != null) 'sort': sort,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), Product.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Product> getProductById(String productId) async {
    try {
      final res = await _dio.get('/shop/products/$productId');
      return Product.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopSummary> getShopById(String shopId) async {
    try {
      final res = await _dio.get('/shop/$shopId');
      return ShopSummary.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<Product>> getShopProducts(
    String shopId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/shop/$shopId/products',
        queryParameters: {'page': page, 'limit': limit},
      );
      return PaginatedResult.fromJson(unwrapData(res.data), Product.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
'''

FILES['features/marketplace/presentation/providers/marketplace_providers.dart'] = r'''
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
'''

print(f'Prepared {len(FILES)} files so far (part1)')
# Write part1 then continue in same script with more FILES
for rel, content in list(FILES.items()):
    w(rel, content)
print('part1 written', len(FILES))
