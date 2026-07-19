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
