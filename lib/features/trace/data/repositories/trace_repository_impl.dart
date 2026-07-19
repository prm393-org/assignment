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
