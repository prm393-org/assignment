import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/review/domain/entities/shop_review.dart';
import 'package:chuoi_xanh_viet/features/review/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<ShopReview>> listByProduct(String productId) async {
    try {
      final res = await _dio.get('/review/product/$productId');
      return PaginatedResult.fromJson(unwrapData(res.data), ShopReview.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<ShopReview>> listByShop(String shopId) async {
    try {
      final res = await _dio.get('/review/shop/$shopId');
      return PaginatedResult.fromJson(unwrapData(res.data), ShopReview.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await _dio.post('/review', data: {
        'order_id': orderId,
        'product_id': productId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
      return ShopReview.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
