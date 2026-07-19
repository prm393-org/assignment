import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<AppNotification>> list({
    int page = 1,
    bool? unreadOnly,
  }) async {
    try {
      final res = await _dio.get('/notification', queryParameters: {
        'page': page,
        'limit': 30,
        if (unreadOnly != null) 'unread_only': unreadOnly ? 'true' : 'false',
      });
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        AppNotification.fromJson,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.patch('/notification/$id/read');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notification/read-all');
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
