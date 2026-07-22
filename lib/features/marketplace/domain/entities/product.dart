import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

List<String> parseCertifications(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
  }
  return const [];
}

class ProductFarmInfo extends Equatable {
  const ProductFarmInfo({
    required this.id,
    required this.name,
    this.ownerUserId,
    this.province,
    this.district,
    this.ward,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? ownerUserId;
  final String? province;
  final String? district;
  final String? ward;
  final String? address;
  final double? latitude;
  final double? longitude;

  String? get regionLine {
    final parts = [district, province].whereType<String>().where((e) => e.isNotEmpty);
    if (parts.isEmpty) return province ?? district;
    return parts.join(', ');
  }

  String? get mapQuery {
    final parts = [address, ward, district, province]
        .whereType<String>()
        .where((e) => e.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  bool get hasGeo =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  factory ProductFarmInfo.fromJson(Map<String, dynamic> json) {
    return ProductFarmInfo(
      id: readString(json, ['id']),
      name: readString(json, ['name'], 'Nông trại'),
      ownerUserId: readStringOrNull(json, [
        'ownerUserId',
        'owner_user_id',
      ]),
      province: readStringOrNull(json, ['province']),
      district: readStringOrNull(json, ['district']),
      ward: readStringOrNull(json, ['ward']),
      address: readStringOrNull(json, ['address']),
      latitude: readNum(json, ['latitude'])?.toDouble(),
      longitude: readNum(json, ['longitude'])?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id];
}

class ProductSaleUnit extends Equatable {
  const ProductSaleUnit({
    required this.id,
    required this.code,
    this.shortCode,
    this.qrUrl,
  });

  final String id;
  final String code;
  final String? shortCode;
  final String? qrUrl;

  String? get traceValue {
    final url = qrUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    final code = (shortCode ?? this.code).trim();
    return code.isEmpty ? null : code;
  }

  String? get displayCode =>
      (shortCode?.trim().isNotEmpty == true) ? shortCode!.trim() : code;

  factory ProductSaleUnit.fromJson(Map<String, dynamic> json) {
    return ProductSaleUnit(
      id: readString(json, ['id']),
      code: readString(json, ['code']),
      shortCode: readStringOrNull(json, ['shortCode', 'short_code']),
      qrUrl: readStringOrNull(json, ['qrUrl', 'qr_url']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class ProductSeasonInfo extends Equatable {
  const ProductSeasonInfo({
    required this.id,
    required this.code,
    required this.cropName,
    this.startDate,
    this.harvestStartDate,
    this.harvestEndDate,
    this.status,
  });

  final String id;
  final String code;
  final String cropName;
  final String? startDate;
  final String? harvestStartDate;
  final String? harvestEndDate;
  final String? status;

  factory ProductSeasonInfo.fromJson(Map<String, dynamic> json) {
    return ProductSeasonInfo(
      id: readString(json, ['id']),
      code: readString(json, ['code']),
      cropName: readString(json, ['cropName', 'crop_name'], 'Cây trồng'),
      startDate: readStringOrNull(json, ['startDate', 'start_date']),
      harvestStartDate:
          readStringOrNull(json, ['harvestStartDate', 'harvest_start_date']),
      harvestEndDate:
          readStringOrNull(json, ['harvestEndDate', 'harvest_end_date']),
      status: readStringOrNull(json, ['status']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class ProductShopInfo extends Equatable {
  const ProductShopInfo({
    required this.id,
    required this.name,
    this.description,
    this.isVerified = false,
    this.averageRating,
    this.reviewCount = 0,
    this.certifications = const [],
    this.farm,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final bool isVerified;
  final double? averageRating;
  final int reviewCount;
  final List<String> certifications;
  final ProductFarmInfo? farm;
  final String? updatedAt;

  String? get farmName => farm?.name;
  String? get province => farm?.province;

  factory ProductShopInfo.fromJson(Map<String, dynamic> json) {
    final farms = asMap(json['farms'] ?? json['farm']);
    return ProductShopInfo(
      id: readString(json, ['id']),
      name: readString(json, ['name'], 'Gian hàng'),
      description: readStringOrNull(json, ['description']),
      isVerified: readBool(json, ['isVerified', 'is_verified']),
      averageRating:
          readNum(json, ['averageRating', 'average_rating'])?.toDouble(),
      reviewCount: readInt(json, ['reviewCount', 'review_count']),
      certifications: parseCertifications(json['certifications']),
      farm: farms.isEmpty ? null : ProductFarmInfo.fromJson(farms),
      updatedAt: readStringOrNull(json, ['updatedAt', 'updated_at']),
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
    this.season,
    this.saleUnit,
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
  final ProductSeasonInfo? season;
  final ProductSaleUnit? saleUnit;

  String? get seasonId => season?.id;
  String? get seasonCode => season?.code;
  String? get cropName => season?.cropName;

  factory Product.fromJson(Map<String, dynamic> json) {
    final shops = asMap(json['shops'] ?? json['shop']);
    final seasons = asMap(json['seasons'] ?? json['season']);
    final saleUnit = asMap(json['saleUnit'] ?? json['sale_unit']);
    final shopId = readString(json, ['shopId', 'shop_id']);
    return Product(
      id: readString(json, ['id']),
      shopId: shopId.isNotEmpty ? shopId : readString(shops, ['id']),
      name: readString(json, ['name']),
      price: readDouble(json, ['price']),
      description: readStringOrNull(json, ['description']),
      unit: readStringOrNull(json, ['unit']),
      stockQty: readNum(json, ['stockQty', 'stock_qty'])?.toDouble(),
      imageUrl:
          resolveMediaUrl(readStringOrNull(json, ['imageUrl', 'image_url'])),
      isActive: readBool(json, ['isActive', 'is_active'], true),
      shop: shops.isEmpty ? null : ProductShopInfo.fromJson(shops),
      averageRating:
          readNum(json, ['averageRating', 'average_rating'])?.toDouble(),
      reviewCount: readInt(json, ['reviewCount', 'review_count']),
      season: seasons.isEmpty ? null : ProductSeasonInfo.fromJson(seasons),
      saleUnit: saleUnit.isEmpty ? null : ProductSaleUnit.fromJson(saleUnit),
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
    this.district,
    this.avatarUrl,
    this.certifications = const [],
    this.ownerUserId,
    this.updatedAt,
    this.farm,
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
  final String? district;
  final String? avatarUrl;
  final List<String> certifications;
  final String? ownerUserId;
  final String? updatedAt;
  final ProductFarmInfo? farm;

  factory ShopSummary.fromJson(Map<String, dynamic> json) {
    final farms = asMap(json['farms'] ?? json['farm']);
    final farm = farms.isEmpty ? null : ProductFarmInfo.fromJson(farms);
    return ShopSummary(
      id: readString(json, ['id']),
      name: readString(json, ['name']),
      farmId: readString(json, ['farmId', 'farm_id']).isNotEmpty
          ? readString(json, ['farmId', 'farm_id'])
          : (farm?.id ?? ''),
      description: readStringOrNull(json, ['description']),
      isVerified: readBool(json, ['isVerified', 'is_verified']),
      status: readString(json, ['status']),
      averageRating:
          readNum(json, ['averageRating', 'average_rating'])?.toDouble(),
      reviewCount: readInt(json, ['reviewCount', 'review_count']),
      farmName: farm?.name ?? readStringOrNull(farms, ['name']),
      province: farm?.province ?? readStringOrNull(farms, ['province']),
      district: farm?.district ?? readStringOrNull(farms, ['district']),
      avatarUrl: resolveMediaUrl(
        readStringOrNull(json, ['avatarUrl', 'avatar_url']),
      ),
      certifications: parseCertifications(json['certifications']),
      ownerUserId: farm?.ownerUserId ??
          readStringOrNull(farms, ['ownerUserId', 'owner_user_id']),
      updatedAt: readStringOrNull(json, ['updatedAt', 'updated_at']),
      farm: farm,
    );
  }

  @override
  List<Object?> get props => [id];
}
