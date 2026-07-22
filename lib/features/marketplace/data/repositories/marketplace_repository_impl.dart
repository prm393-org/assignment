import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  MarketplaceRepositoryImpl(this._dio);
  final Dio _dio;

  Map<String, dynamic> _params(MarketplaceFilter f) => {
        'page': f.page,
        'limit': f.limit,
        if (f.searchTerm != null && f.searchTerm!.isNotEmpty)
          'searchTerm': f.searchTerm,
        if (f.province != null && f.province!.isNotEmpty) 'province': f.province,
        if (f.shopId != null && f.shopId!.isNotEmpty) 'shopId': f.shopId,
        if (f.sort != null && f.sort!.isNotEmpty) 'sort': f.sort,
        if (f.minPrice != null) 'minPrice': f.minPrice,
        if (f.maxPrice != null) 'maxPrice': f.maxPrice,
      };

  @override
  Future<PaginatedResult<Product>> getProducts({
    MarketplaceFilter filter = const MarketplaceFilter(),
  }) async {
    try {
      final res = await _dio.get(
        '/shop/products',
        queryParameters: _params(filter),
      );
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
  Future<PaginatedResult<ShopSummary>> getShops({
    MarketplaceFilter filter = const MarketplaceFilter(),
  }) async {
    try {
      final res = await _dio.get('/shop', queryParameters: _params(filter));
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        ShopSummary.fromJson,
      );
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
