import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class ShopReview extends Equatable {
  const ShopReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.reviewerName,
    this.productName,
    this.productImageUrl,
  });

  final String id;
  final int rating;
  final String createdAt;
  final String? comment;
  final String? reviewerName;
  final String? productName;
  final String? productImageUrl;

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    final reviewer = asMap(json['reviewer'] ?? json['users']);
    final product = asMap(json['product'] ?? json['products']);
    return ShopReview(
      id: readString(json, ['id']),
      rating: readInt(json, ['rating']),
      createdAt: readString(json, ['createdAt', 'created_at']),
      comment: readStringOrNull(json, ['comment']),
      reviewerName: readStringOrNull(reviewer, ['fullName', 'full_name']),
      productName: readStringOrNull(product, ['name']),
      productImageUrl: resolveMediaUrl(
        readStringOrNull(product, ['imageUrl', 'image_url']),
      ),
    );
  }

  @override
  List<Object?> get props => [id];
}
