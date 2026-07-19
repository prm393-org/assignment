import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/domain/entities/agri_trend.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/domain/repositories/agri_trend_repository.dart';

class AgriTrendRepositoryImpl implements AgriTrendRepository {
  AgriTrendRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<AgriTrend> getTrend({bool refresh = false}) async {
    try {
      final res = await _dio.get(
        '/agri-trend',
        queryParameters: refresh ? {'refresh': true} : null,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      return AgriTrend.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
