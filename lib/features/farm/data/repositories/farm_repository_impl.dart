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
        'seasonId': ?seasonId,
        'farmId': ?farmId,
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

  @override
  Future<void> addDiaryAttachment(
    String diaryId, {
    required String fileUrl,
    required String mimeType,
  }) async {
    try {
      await _dio.post('/diary/$diaryId/attachments', data: {
        'file_url': fileUrl,
        'fileUrl': fileUrl,
        'mime_type': mimeType,
        'mimeType': mimeType,
      });
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deleteDiaryAttachment(String attachmentId) async {
    try {
      await _dio.delete('/diary/attachments/$attachmentId');
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
