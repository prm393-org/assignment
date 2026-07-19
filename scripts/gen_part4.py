# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


# TRACE
w('features/trace/domain/entities/trace_info.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class TraceSaleUnit extends Equatable {
  const TraceSaleUnit({
    required this.id,
    required this.seasonId,
    required this.code,
    this.quantity,
    this.unit,
    this.shortCode,
    this.qrUrl,
    this.status,
  });

  final String id;
  final String seasonId;
  final String code;
  final String? quantity;
  final String? unit;
  final String? shortCode;
  final String? qrUrl;
  final String? status;

  factory TraceSaleUnit.fromJson(Map<String, dynamic> json) => TraceSaleUnit(
        id: readString(json, ['id']),
        seasonId: readString(json, ['seasonId', 'season_id']),
        code: readString(json, ['code']),
        quantity: readStringOrNull(json, ['quantity']),
        unit: readStringOrNull(json, ['unit']),
        shortCode: readStringOrNull(json, ['shortCode', 'short_code']),
        qrUrl: readStringOrNull(json, ['qrUrl', 'qr_url']),
        status: readStringOrNull(json, ['status']),
      );

  @override
  List<Object?> get props => [id];
}

class TraceSeasonDetail extends Equatable {
  const TraceSeasonDetail({
    required this.seasonCode,
    required this.cropName,
    required this.farmName,
    this.ownerName,
    this.province,
    this.status,
    this.diaries = const [],
  });

  final String seasonCode;
  final String cropName;
  final String farmName;
  final String? ownerName;
  final String? province;
  final String? status;
  final List<Map<String, String>> diaries;

  factory TraceSeasonDetail.fromJson(Map<String, dynamic> json) {
    final season = asMap(json['season']);
    final farm = asMap(json['farm']);
    final owner = asMap(json['owner']);
    final diariesRaw = asList(json['diaries']);
    return TraceSeasonDetail(
      seasonCode: readString(season, ['code']),
      cropName: readString(season, ['cropName', 'crop_name']),
      farmName: readString(farm, ['name']),
      ownerName: readStringOrNull(owner, ['fullName', 'full_name']),
      province: readStringOrNull(farm, ['province']),
      status: readStringOrNull(season, ['status']),
      diaries: diariesRaw.whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'eventType': readString(m, ['eventType', 'event_type']),
          'eventDate': readString(m, ['eventDate', 'event_date']),
          'description': readString(m, ['description']),
        };
      }).toList(),
    );
  }

  @override
  List<Object?> get props => [seasonCode, farmName];
}
''')

w('features/trace/domain/repositories/trace_repository.dart', r'''
import 'package:chuoi_xanh_viet/features/trace/domain/entities/trace_info.dart';

abstract class TraceRepository {
  Future<TraceSaleUnit> resolveByCode(String code, {bool isPublic = true});
  Future<TraceSeasonDetail> getSeasonDetail(String seasonId, {bool isPublic = true});
}
''')

w('features/trace/data/repositories/trace_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/entities/trace_info.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/repositories/trace_repository.dart';

class TraceRepositoryImpl implements TraceRepository {
  TraceRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<TraceSaleUnit> resolveByCode(String code, {bool isPublic = true}) async {
    try {
      final path = isPublic
          ? '/trace/public/resolve/${Uri.encodeComponent(code.trim())}'
          : '/trace/resolve/${Uri.encodeComponent(code.trim())}';
      final res = await _dio.get(path);
      return TraceSaleUnit.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<TraceSeasonDetail> getSeasonDetail(
    String seasonId, {
    bool isPublic = true,
  }) async {
    try {
      final path = isPublic
          ? '/trace/public/season/$seasonId'
          : '/trace/season/$seasonId';
      final res = await _dio.get(path);
      return TraceSeasonDetail.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/trace/presentation/providers/trace_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/trace/data/repositories/trace_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/repositories/trace_repository.dart';

final traceRepositoryProvider = Provider<TraceRepository>((ref) {
  return TraceRepositoryImpl(ref.watch(dioProvider));
});
''')

# CERTIFICATE
w('features/certificate/domain/entities/farm_certificate.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class FarmCertificate extends Equatable {
  const FarmCertificate({
    required this.id,
    required this.farmId,
    required this.type,
    required this.status,
    required this.fileUrl,
    this.certificateNo,
    this.issuer,
    this.issuedAt,
    this.expiresAt,
    this.farmName,
    this.reviewerNote,
  });

  final String id;
  final String farmId;
  final String type;
  final String status;
  final String fileUrl;
  final String? certificateNo;
  final String? issuer;
  final String? issuedAt;
  final String? expiresAt;
  final String? farmName;
  final String? reviewerNote;

  factory FarmCertificate.fromJson(Map<String, dynamic> json) {
    final farm = asMap(json['farm'] ?? json['farms']);
    return FarmCertificate(
      id: readString(json, ['id']),
      farmId: readString(json, ['farmId', 'farm_id']),
      type: readString(json, ['type']),
      status: readString(json, ['status']),
      fileUrl: readString(json, ['fileUrl', 'file_url']),
      certificateNo: readStringOrNull(json, ['certificateNo', 'certificate_no']),
      issuer: readStringOrNull(json, ['issuer']),
      issuedAt: readStringOrNull(json, ['issuedAt', 'issued_at']),
      expiresAt: readStringOrNull(json, ['expiresAt', 'expires_at']),
      farmName: readStringOrNull(farm, ['name']),
      reviewerNote: readStringOrNull(json, ['reviewerNote', 'reviewer_note', 'reject_reason']),
    );
  }

  @override
  List<Object?> get props => [id, status];
}
''')

w('features/certificate/domain/repositories/certificate_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/entities/farm_certificate.dart';

abstract class CertificateRepository {
  Future<PaginatedResult<FarmCertificate>> listMine({int page = 1});
  Future<FarmCertificate> create(Map<String, dynamic> body);
  Future<PaginatedResult<FarmCertificate>> listPendingAdmin({int page = 1});
  Future<FarmCertificate> approve(String id);
  Future<FarmCertificate> reject(String id, String reason);
}
''')

w('features/certificate/data/repositories/certificate_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/entities/farm_certificate.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/repositories/certificate_repository.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  CertificateRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<FarmCertificate>> listMine({int page = 1}) async {
    try {
      final res = await _dio.get('/certificate/farm/mine', queryParameters: {
        'page': page,
        'limit': 20,
      });
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        FarmCertificate.fromJson,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FarmCertificate> create(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/certificate/farm', data: body);
      return FarmCertificate.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<FarmCertificate>> listPendingAdmin({
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        '/certificate/farm/pending/admin',
        queryParameters: {'page': page, 'limit': 20},
      );
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        FarmCertificate.fromJson,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FarmCertificate> approve(String id) async {
    try {
      final res = await _dio.post('/certificate/farm/$id/approve', data: {});
      return FarmCertificate.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FarmCertificate> reject(String id, String reason) async {
    try {
      final res = await _dio.post(
        '/certificate/farm/$id/reject',
        data: {'reason': reason},
      );
      return FarmCertificate.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/certificate/presentation/providers/certificate_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/certificate/data/repositories/certificate_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/entities/farm_certificate.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/repositories/certificate_repository.dart';

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepositoryImpl(ref.watch(dioProvider));
});

final myCertificatesProvider =
    FutureProvider.autoDispose<PaginatedResult<FarmCertificate>>((ref) {
  return ref.watch(certificateRepositoryProvider).listMine();
});

final pendingAdminCertificatesProvider =
    FutureProvider.autoDispose<PaginatedResult<FarmCertificate>>((ref) {
  return ref.watch(certificateRepositoryProvider).listPendingAdmin();
});
''')

# SHOP MANAGE
w('features/shop_manage/domain/repositories/shop_manage_repository.dart', r'''
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';

class AvailableSaleUnit {
  const AvailableSaleUnit({
    required this.id,
    required this.code,
    required this.quantity,
    required this.unit,
    this.cropName,
    this.shortCode,
  });

  final String id;
  final String code;
  final String quantity;
  final String unit;
  final String? cropName;
  final String? shortCode;
}

abstract class ShopManageRepository {
  Future<List<ShopSummary>> getMyShops();
  Future<ShopSummary> createShop({
    required String farmId,
    required String name,
    String? description,
  });
  Future<List<AvailableSaleUnit>> getAvailableSaleUnits(String shopId);
  Future<Product> addProduct(String shopId, Map<String, dynamic> body);
}
''')

w('features/shop_manage/data/repositories/shop_manage_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/domain/repositories/shop_manage_repository.dart';

class ShopManageRepositoryImpl implements ShopManageRepository {
  ShopManageRepositoryImpl(this._dio);
  final Dio _dio;

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
  Future<ShopSummary> createShop({
    required String farmId,
    required String name,
    String? description,
  }) async {
    try {
      final res = await _dio.post('/shop', data: {
        'farm_id': farmId,
        'name': name,
        if (description != null) 'description': description,
      });
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
  Future<Product> addProduct(String shopId, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/shop/$shopId/products', data: body);
      return Product.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/shop_manage/presentation/providers/shop_manage_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/data/repositories/shop_manage_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/domain/repositories/shop_manage_repository.dart';

final shopManageRepositoryProvider = Provider<ShopManageRepository>((ref) {
  return ShopManageRepositoryImpl(ref.watch(dioProvider));
});

final myShopsProvider = FutureProvider.autoDispose<List<ShopSummary>>((ref) {
  return ref.watch(shopManageRepositoryProvider).getMyShops();
});

final availableSaleUnitsProvider = FutureProvider.autoDispose
    .family<List<AvailableSaleUnit>, String>((ref, shopId) {
  return ref.watch(shopManageRepositoryProvider).getAvailableSaleUnits(shopId);
});
''')

print('part4 done')
