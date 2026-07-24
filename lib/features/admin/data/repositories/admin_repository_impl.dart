import 'dart:async';

import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/firebase/fcm_topics.dart';
import 'package:chuoi_xanh_viet/core/firebase/push_sender.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/admin/domain/entities/admin_models.dart';
import 'package:chuoi_xanh_viet/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<AdminDashboardSummary> getDashboardSummary() async {
    try {
      final res = await _dio.get('/admin/dashboard/summary');
      return AdminDashboardSummary.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<AdminUser>> listUsers({
    int page = 1,
    String? q,
    String? role,
    String? status,
  }) async {
    try {
      final res = await _dio.get('/admin/users', queryParameters: {
        'page': page,
        'limit': 20,
        if (q != null && q.isNotEmpty) 'q': q,
        'role': ?role,
        'status': ?status,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), AdminUser.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AdminUser> patchUserStatus(String userId, String status) async {
    try {
      final res = await _dio.patch(
        '/admin/users/$userId/status',
        data: {'status': status},
      );
      return AdminUser.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> broadcast({
    required String title,
    required String body,
    required String audience,
    String? linkPath,
  }) async {
    try {
      final res = await _dio.post('/admin/notifications/broadcast', data: {
        'title': title,
        'body': body,
        'audience': audience,
        'linkPath': ?linkPath,
      });
      // Fan out as a push: "all" hits every device, otherwise the role topic.
      final normalized = audience.trim().toLowerCase();
      final topic = (normalized.isEmpty || normalized == 'all')
          ? FcmTopics.broadcast
          : FcmTopics.role(normalized);
      unawaited(PushSender.sendToTopic(
        topic: topic,
        title: title,
        body: body,
        link: linkPath,
      ));
      return asMap(unwrapData(res.data));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<AuditLogItem>> listAuditLogs({
    int page = 1,
    String? q,
  }) async {
    try {
      final res = await _dio.get('/admin/audit-logs', queryParameters: {
        'page': page,
        'limit': 30,
        if (q != null && q.isNotEmpty) 'q': q,
      });
      return PaginatedResult.fromJson(unwrapData(res.data), AuditLogItem.fromJson);
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
