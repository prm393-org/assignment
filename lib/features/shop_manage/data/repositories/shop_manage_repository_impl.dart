import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/domain/repositories/shop_manage_repository.dart';

class ShopManageRepositoryImpl implements ShopManageRepository {
  ShopManageRepositoryImpl(this._dio);
  final Dio _dio;

  Failure _mapProductMutationError(Object e) {
    if (e is DioException && e.response?.statusCode == 404) {
      return const ValidationFailure('API chưa hỗ trợ sửa/xóa sản phẩm');
    }
    return mapDioException(e);
  }

  @override
  Future<List<ShopSummary>> getMyShops() async {
    try {
      final res = await _dio.get('/shop/mine');
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, ShopSummary.fromJson);
      return PaginatedResult.fromJson(data, ShopSummary.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopSummary> getShop(String id) async {
    try {
      final res = await _dio.get('/shop/$id');
      return ShopSummary.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopSummary> createShop({
    required String farmId,
    required String name,
    String? description,
  }) async {
    try {
      final res = await _dio.post('/shop', data: {
        'farm_id': farmId,
        'name': name,
        'description': ?description,
      });
      return ShopSummary.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopSummary> updateShop(String id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch('/shop/$id', data: body);
      return ShopSummary.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<AvailableSaleUnit>> getAvailableSaleUnits(String shopId) async {
    try {
      final res = await _dio.get('/shop/$shopId/available-sale-units');
      final data = unwrapData(res.data);
      return asList(data).whereType<Map>().map((e) {
        final m = asMap(e);
        final seasons = asMap(m['seasons']);
        return AvailableSaleUnit(
          id: readString(m, ['id']),
          code: readString(m, ['code']),
          quantity: readString(m, ['quantity']),
          unit: readString(m, ['unit'], 'kg'),
          shortCode: readStringOrNull(m, ['short_code', 'shortCode']),
          cropName: readStringOrNull(seasons, ['crop_name', 'cropName']),
        );
      }).toList();
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<Product>> getShopProducts(String shopId) async {
    try {
      final res = await _dio.get(
        '/shop/$shopId/products',
        queryParameters: {'page': 1, 'limit': 100},
      );
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, Product.fromJson);
      return PaginatedResult.fromJson(data, Product.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Product> addProduct(String shopId, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/shop/$shopId/products', data: body);
      return Product.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Product> updateProduct(
    String shopId,
    String productId,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.patch(
        '/shop/$shopId/products/$productId',
        data: body,
      );
      return Product.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw _mapProductMutationError(e);
    }
  }

  @override
  Future<void> deleteProduct(String shopId, String productId) async {
    try {
      await _dio.delete('/shop/$shopId/products/$productId');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        try {
          await _dio.patch(
            '/shop/$shopId/products/$productId',
            data: {'is_active': false},
          );
          return;
        } catch (e2) {
          throw _mapProductMutationError(e2);
        }
      }
      throw _mapProductMutationError(e);
    }
  }
}
