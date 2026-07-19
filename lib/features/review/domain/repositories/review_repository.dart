import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/review/domain/entities/shop_review.dart';

abstract class ReviewRepository {
  Future<PaginatedResult<ShopReview>> listByProduct(String productId);
  Future<PaginatedResult<ShopReview>> listByShop(String shopId);
  Future<ShopReview> createReview({
    required String orderId,
    required String productId,
    required int rating,
    String? comment,
  });
}
