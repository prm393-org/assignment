# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


# ORDER
w('features/order/domain/entities/order.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.productName,
    this.unit,
    this.imageUrl,
    this.myReviewId,
    this.myReviewRating,
  });

  final String id;
  final String productId;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final String productName;
  final String? unit;
  final String? imageUrl;
  final String? myReviewId;
  final int? myReviewRating;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = asMap(json['product'] ?? json['products']);
    final review = asMap(json['myReview'] ?? json['my_review']);
    return OrderItem(
      id: readString(json, ['id']),
      productId: readString(json, ['productId', 'product_id']),
      qty: readDouble(json, ['qty', 'quantity'], 1),
      unitPrice: readDouble(json, ['unitPrice', 'unit_price']),
      lineTotal: readDouble(json, ['lineTotal', 'line_total']),
      productName: readString(product, ['name'], 'Sản phẩm'),
      unit: readStringOrNull(product, ['unit']),
      imageUrl: resolveMediaUrl(readStringOrNull(product, ['imageUrl', 'image_url'])),
      myReviewId: review.isEmpty ? null : readStringOrNull(review, ['id']),
      myReviewRating: review.isEmpty ? null : readInt(review, ['rating']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.shopId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
    this.note,
    this.shopName,
    this.items = const [],
    this.sellerPayout,
  });

  final String id;
  final String shopId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final String createdAt;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress;
  final String? note;
  final String? shopName;
  final List<OrderItem> items;
  final double? sellerPayout;

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final shop = asMap(json['shop'] ?? json['shops']);
    return OrderEntity(
      id: readString(json, ['id']),
      shopId: readString(json, ['shopId', 'shop_id']),
      status: readString(json, ['status']),
      paymentMethod: readString(json, ['paymentMethod', 'payment_method'], 'cod'),
      paymentStatus: readString(json, ['paymentStatus', 'payment_status']),
      totalAmount: readDouble(json, ['totalAmount', 'total_amount']),
      createdAt: readString(json, ['createdAt', 'created_at']),
      shippingName: readStringOrNull(json, ['shippingName', 'shipping_name']),
      shippingPhone: readStringOrNull(json, ['shippingPhone', 'shipping_phone']),
      shippingAddress: readStringOrNull(json, ['shippingAddress', 'shipping_address']),
      note: readStringOrNull(json, ['note']),
      shopName: readStringOrNull(shop, ['name']),
      items: mapList(json['items'] ?? json['order_items'], OrderItem.fromJson),
      sellerPayout: readNum(json, ['sellerPayout', 'seller_payout', 'estimatedSellerPayout'])?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, status];
}

class ShopEarnings extends Equatable {
  const ShopEarnings({
    required this.finalizedSellerPayout,
    required this.totalGmvFinalized,
    required this.totalPlatformCommissionFinalized,
    required this.pipelineEstimatedPayout,
    required this.finalizedOrderCount,
    required this.pipelineOrderCount,
  });

  final double finalizedSellerPayout;
  final double totalGmvFinalized;
  final double totalPlatformCommissionFinalized;
  final double pipelineEstimatedPayout;
  final int finalizedOrderCount;
  final int pipelineOrderCount;

  factory ShopEarnings.fromJson(Map<String, dynamic> json) => ShopEarnings(
        finalizedSellerPayout: readDouble(json, ['finalizedSellerPayout']),
        totalGmvFinalized: readDouble(json, ['totalGmvFinalized']),
        totalPlatformCommissionFinalized:
            readDouble(json, ['totalPlatformCommissionFinalized']),
        pipelineEstimatedPayout: readDouble(json, ['pipelineEstimatedPayout']),
        finalizedOrderCount: readInt(json, ['finalizedOrderCount']),
        pipelineOrderCount: readInt(json, ['pipelineOrderCount']),
      );

  @override
  List<Object?> get props => [finalizedSellerPayout];
}
''')

w('features/order/domain/repositories/order_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';

abstract class OrderRepository {
  Future<OrderEntity> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    String paymentMethod = 'cod',
    String? note,
  });

  Future<PaginatedResult<OrderEntity>> getMyOrders({int page = 1, String? status});
  Future<PaginatedResult<OrderEntity>> getShopOrders({int page = 1, String? status});
  Future<OrderEntity> getOrderById(String orderId);
  Future<OrderEntity> cancelOrder(String orderId);
  Future<OrderEntity> updateOrderStatus(String orderId, String status);
  Future<ShopEarnings> getShopEarnings();
}
''')

w('features/order/data/repositories/order_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';
import 'package:chuoi_xanh_viet/features/order/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<OrderEntity> createOrder({
    required String shopId,
    required List<Map<String, dynamic>> items,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    String paymentMethod = 'cod',
    String? note,
  }) async {
    try {
      final res = await _dio.post('/order', data: {
        'shop_id': shopId,
        'items': items,
        'shipping_name': shippingName,
        'shipping_phone': shippingPhone,
        'shipping_address': shippingAddress,
        'payment_method': paymentMethod,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<OrderEntity>> getMyOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final res = await _dio.get('/order/mine', queryParameters: {
        'page': page,
        'limit': 20,
        if (status != null) 'status': status,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), OrderEntity.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<OrderEntity>> getShopOrders({
    int page = 1,
    String? status,
  }) async {
    try {
      final res = await _dio.get('/order/shop', queryParameters: {
        'page': page,
        'limit': 20,
        if (status != null) 'status': status,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), OrderEntity.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> getOrderById(String orderId) async {
    try {
      final res = await _dio.get('/order/$orderId');
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> cancelOrder(String orderId) async {
    try {
      final res = await _dio.patch('/order/$orderId/cancel');
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<OrderEntity> updateOrderStatus(String orderId, String status) async {
    try {
      final res = await _dio.patch('/order/$orderId/status', data: {'status': status});
      return OrderEntity.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ShopEarnings> getShopEarnings() async {
    try {
      final res = await _dio.get('/order/shop/earnings');
      return ShopEarnings.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/order/presentation/providers/order_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/order/data/repositories/order_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/order/domain/entities/order.dart';
import 'package:chuoi_xanh_viet/features/order/domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(ref.watch(dioProvider));
});

final myOrdersProvider =
    FutureProvider.autoDispose<PaginatedResult<OrderEntity>>((ref) {
  return ref.watch(orderRepositoryProvider).getMyOrders();
});

final shopOrdersProvider =
    FutureProvider.autoDispose<PaginatedResult<OrderEntity>>((ref) {
  return ref.watch(orderRepositoryProvider).getShopOrders();
});

final orderDetailProvider =
    FutureProvider.autoDispose.family<OrderEntity, String>((ref, id) {
  return ref.watch(orderRepositoryProvider).getOrderById(id);
});

final shopEarningsProvider =
    FutureProvider.autoDispose<ShopEarnings>((ref) {
  return ref.watch(orderRepositoryProvider).getShopEarnings();
});
''')

# FARM
w('features/farm/domain/entities/farm.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class Farm extends Equatable {
  const Farm({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.cropMain,
    required this.province,
    required this.district,
    required this.ward,
    this.address,
    this.latitude,
    this.longitude,
    this.inCooperative = false,
    this.provinceCode,
    this.districtCode,
    this.wardCode,
  });

  final String id;
  final String name;
  final double areaHa;
  final String cropMain;
  final String province;
  final String district;
  final String ward;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool inCooperative;
  final int? provinceCode;
  final int? districtCode;
  final int? wardCode;

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: readString(json, ['id']),
        name: readString(json, ['name']),
        areaHa: readDouble(json, ['areaHa', 'area_ha']),
        cropMain: readString(json, ['cropMain', 'crop_main']),
        province: readString(json, ['province']),
        district: readString(json, ['district']),
        ward: readString(json, ['ward']),
        address: readStringOrNull(json, ['address']),
        latitude: readNum(json, ['latitude'])?.toDouble(),
        longitude: readNum(json, ['longitude'])?.toDouble(),
        inCooperative: readBool(json, ['inCooperative', 'in_cooperative']),
        provinceCode: readNum(json, ['provinceCode', 'province_code'])?.toInt(),
        districtCode: readNum(json, ['districtCode', 'district_code'])?.toInt(),
        wardCode: readNum(json, ['wardCode', 'ward_code'])?.toInt(),
      );

  String get locationLabel => [ward, district, province]
      .where((e) => e.isNotEmpty)
      .join(', ');

  @override
  List<Object?> get props => [id];
}
''')

w('features/farm/domain/entities/season.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class Season extends Equatable {
  const Season({
    required this.id,
    required this.farmId,
    required this.code,
    required this.cropName,
    required this.status,
    this.startDate,
    this.harvestStartDate,
    this.harvestEndDate,
    this.estimatedYield,
    this.actualYield,
    this.yieldUnit,
  });

  final String id;
  final String farmId;
  final String code;
  final String cropName;
  final String status;
  final String? startDate;
  final String? harvestStartDate;
  final String? harvestEndDate;
  final double? estimatedYield;
  final double? actualYield;
  final String? yieldUnit;

  factory Season.fromJson(Map<String, dynamic> json) => Season(
        id: readString(json, ['id']),
        farmId: readString(json, ['farmId', 'farm_id']),
        code: readString(json, ['code']),
        cropName: readString(json, ['cropName', 'crop_name']),
        status: readString(json, ['status'], 'planning'),
        startDate: readStringOrNull(json, ['startDate', 'start_date']),
        harvestStartDate:
            readStringOrNull(json, ['harvestStartDate', 'harvest_start_date']),
        harvestEndDate:
            readStringOrNull(json, ['harvestEndDate', 'harvest_end_date']),
        estimatedYield:
            readNum(json, ['estimatedYield', 'estimated_yield'])?.toDouble(),
        actualYield: readNum(json, ['actualYield', 'actual_yield'])?.toDouble(),
        yieldUnit: readStringOrNull(json, ['yieldUnit', 'yield_unit']),
      );

  @override
  List<Object?> get props => [id];
}
''')

w('features/farm/domain/entities/diary_entry.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class DiaryEntry extends Equatable {
  const DiaryEntry({
    required this.id,
    required this.seasonId,
    required this.farmId,
    required this.eventType,
    required this.eventDate,
    this.description,
  });

  final String id;
  final String seasonId;
  final String farmId;
  final String eventType;
  final String eventDate;
  final String? description;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: readString(json, ['id']),
        seasonId: readString(json, ['seasonId', 'season_id']),
        farmId: readString(json, ['farmId', 'farm_id']),
        eventType: readString(json, ['eventType', 'event_type']),
        eventDate: readString(json, ['eventDate', 'event_date']),
        description: readStringOrNull(json, ['description']),
      );

  @override
  List<Object?> get props => [id];
}

const diaryEventLabels = <String, String>{
  'land_prep': 'Làm đất',
  'sowing': 'Gieo trồng',
  'fertilizing': 'Bón phân',
  'pesticide': 'Phun thuốc',
  'irrigation': 'Tưới nước',
  'harvesting': 'Thu hoạch',
  'packing': 'Đóng gói',
  'other': 'Khác',
};
''')

w('features/farm/domain/repositories/farm_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/season.dart';

abstract class FarmRepository {
  Future<List<Farm>> getMyFarms();
  Future<Farm> createFarm(Map<String, dynamic> body);
  Future<Farm> updateFarm(String id, Map<String, dynamic> body);
  Future<void> deleteFarm(String id);

  Future<List<Season>> getSeasons(String farmId);
  Future<Season> getSeasonById(String seasonId);
  Future<Season> createSeason(Map<String, dynamic> body);
  Future<Season> updateSeason(String id, Map<String, dynamic> body);
  Future<Season> updateSeasonStatus(String id, String status);

  Future<PaginatedResult<DiaryEntry>> getDiaries({
    String? seasonId,
    String? farmId,
    int page = 1,
  });
  Future<DiaryEntry> createDiary(Map<String, dynamic> body);
}
''')

w('features/farm/data/repositories/farm_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/season.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/repositories/farm_repository.dart';

class FarmRepositoryImpl implements FarmRepository {
  FarmRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Farm>> getMyFarms() async {
    try {
      final res = await _dio.get('/farm/mine');
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, Farm.fromJson);
      return PaginatedResult.fromJson(data, Farm.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Farm> createFarm(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/farm', data: body);
      return Farm.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Farm> updateFarm(String id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch('/farm/$id', data: body);
      return Farm.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deleteFarm(String id) async {
    try {
      await _dio.delete('/farm/$id');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<Season>> getSeasons(String farmId) async {
    try {
      final res = await _dio.get('/season', queryParameters: {'farmId': farmId});
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, Season.fromJson);
      return PaginatedResult.fromJson(data, Season.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Season> getSeasonById(String seasonId) async {
    try {
      final res = await _dio.get('/season/$seasonId');
      return Season.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Season> createSeason(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/season', data: body);
      return Season.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Season> updateSeason(String id, Map<String, dynamic> body) async {
    try {
      final res = await _dio.patch('/season/$id', data: body);
      return Season.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Season> updateSeasonStatus(String id, String status) async {
    try {
      final res = await _dio.patch('/season/$id/status', data: {'status': status});
      return Season.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<DiaryEntry>> getDiaries({
    String? seasonId,
    String? farmId,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get('/diary', queryParameters: {
        'page': page,
        'limit': 50,
        if (seasonId != null) 'seasonId': seasonId,
        if (farmId != null) 'farmId': farmId,
      });
      final data = unwrapData(res.data);
      if (data is List) {
        return PaginatedResult(items: mapList(data, DiaryEntry.fromJson));
      }
      return PaginatedResult.fromJson(data, DiaryEntry.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<DiaryEntry> createDiary(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/diary', data: body);
      return DiaryEntry.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/farm/presentation/providers/farm_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/farm/data/repositories/farm_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/season.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/repositories/farm_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepositoryImpl(ref.watch(dioProvider));
});

final myFarmsProvider = FutureProvider.autoDispose<List<Farm>>((ref) {
  return ref.watch(farmRepositoryProvider).getMyFarms();
});

final farmSeasonsProvider =
    FutureProvider.autoDispose.family<List<Season>, String>((ref, farmId) {
  return ref.watch(farmRepositoryProvider).getSeasons(farmId);
});

final seasonDetailProvider =
    FutureProvider.autoDispose.family<Season, String>((ref, id) {
  return ref.watch(farmRepositoryProvider).getSeasonById(id);
});

final seasonDiariesProvider = FutureProvider.autoDispose
    .family<PaginatedResult<DiaryEntry>, String>((ref, seasonId) {
  return ref.watch(farmRepositoryProvider).getDiaries(seasonId: seasonId);
});
''')

print('part2 done')
