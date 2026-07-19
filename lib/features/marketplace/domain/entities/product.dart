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
