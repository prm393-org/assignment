import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/review/data/repositories/review_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/review/domain/entities/shop_review.dart';
import 'package:chuoi_xanh_viet/features/review/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.watch(dioProvider));
});

final productReviewsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ShopReview>, String>((ref, productId) {
  return ref.watch(reviewRepositoryProvider).listByProduct(productId);
});

final shopReviewsProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ShopReview>, String>((ref, shopId) {
  return ref.watch(reviewRepositoryProvider).listByShop(shopId);
});
