# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


# ADMIN
w('features/admin/domain/entities/admin_models.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class AdminDashboardSummary extends Equatable {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.pendingCerts,
    required this.newUsers7d,
    required this.newOrders7d,
    this.byRole = const {},
    this.ordersByStatus = const {},
  });

  final int totalUsers;
  final int pendingCerts;
  final int newUsers7d;
  final int newOrders7d;
  final Map<String, int> byRole;
  final Map<String, int> ordersByStatus;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    final users = asMap(json['users']);
    final orders = asMap(json['orders']);
    final last7 = asMap(json['last7Days'] ?? json['last_7_days']);
    final byRoleRaw = asMap(users['byRole'] ?? users['by_role']);
    final byStatusOrders = asMap(orders['byStatus'] ?? orders['by_status']);
    return AdminDashboardSummary(
      totalUsers: readInt(users, ['total']),
      pendingCerts: readInt(json, [
        'pendingFarmCertificatesAdminScope',
        'pending_farm_certificates_admin_scope',
      ]),
      newUsers7d: readInt(last7, ['newUsers', 'new_users']),
      newOrders7d: readInt(last7, ['newOrders', 'new_orders']),
      byRole: byRoleRaw.map((k, v) => MapEntry('$k', int.tryParse('$v') ?? 0)),
      ordersByStatus:
          byStatusOrders.map((k, v) => MapEntry('$k', int.tryParse('$v') ?? 0)),
    );
  }

  @override
  List<Object?> get props => [totalUsers, pendingCerts];
}

class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.status,
    this.email,
    this.phone,
  });

  final String id;
  final String fullName;
  final String role;
  final String status;
  final String? email;
  final String? phone;

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: readString(json, ['id']),
        fullName: readString(json, ['fullName', 'full_name']),
        role: readString(json, ['role']),
        status: readString(json, ['status']),
        email: readStringOrNull(json, ['email']),
        phone: readStringOrNull(json, ['phone']),
      );

  @override
  List<Object?> get props => [id, status];
}

class AuditLogItem extends Equatable {
  const AuditLogItem({
    required this.id,
    required this.module,
    required this.action,
    required this.status,
    required this.createdAt,
    this.actorName,
    this.path,
    this.errorMessage,
  });

  final String id;
  final String module;
  final String action;
  final String status;
  final String createdAt;
  final String? actorName;
  final String? path;
  final String? errorMessage;

  factory AuditLogItem.fromJson(Map<String, dynamic> json) {
    final actor = asMap(json['actor']);
    return AuditLogItem(
      id: readString(json, ['id']),
      module: readString(json, ['module']),
      action: readString(json, ['action']),
      status: readString(json, ['status']),
      createdAt: readString(json, ['createdAt', 'created_at']),
      actorName: readStringOrNull(actor, ['fullName', 'full_name']),
      path: readStringOrNull(json, ['path']),
      errorMessage: readStringOrNull(json, ['errorMessage', 'error_message']),
    );
  }

  @override
  List<Object?> get props => [id];
}
''')

w('features/admin/domain/repositories/admin_repository.dart', r'''
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/admin/domain/entities/admin_models.dart';

abstract class AdminRepository {
  Future<AdminDashboardSummary> getDashboardSummary();
  Future<PaginatedResult<AdminUser>> listUsers({
    int page = 1,
    String? q,
    String? role,
    String? status,
  });
  Future<AdminUser> patchUserStatus(String userId, String status);
  Future<Map<String, dynamic>> broadcast({
    required String title,
    required String body,
    required String audience,
    String? linkPath,
  });
  Future<PaginatedResult<AuditLogItem>> listAuditLogs({int page = 1, String? q});
}
''')

w('features/admin/data/repositories/admin_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
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
        if (role != null) 'role': role,
        if (status != null) 'status': status,
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
        if (linkPath != null) 'linkPath': linkPath,
      });
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
''')

w('features/admin/presentation/providers/admin_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/admin/domain/entities/admin_models.dart';
import 'package:chuoi_xanh_viet/features/admin/domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(dioProvider));
});

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardSummary>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboardSummary();
});

final adminUsersProvider =
    FutureProvider.autoDispose.family<PaginatedResult<AdminUser>, String>((ref, q) {
  return ref.watch(adminRepositoryProvider).listUsers(q: q.isEmpty ? null : q);
});

final auditLogsProvider =
    FutureProvider.autoDispose<PaginatedResult<AuditLogItem>>((ref) {
  return ref.watch(adminRepositoryProvider).listAuditLogs();
});
''')

# AI
w('features/ai/domain/repositories/chatbot_repository.dart', r'''
abstract class ChatbotRepository {
  Future<String> chat(String message, {List<Map<String, String>> history = const []});
  Future<String> market(String message, {String? crop, String? region});
  Future<String> diagnose({required String imagePath, String? note});
}
''')

w('features/ai/data/repositories/chatbot_repository_impl.dart', r'''
import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/config/api_config.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/ai/domain/repositories/chatbot_repository.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  ChatbotRepositoryImpl(this._dio);
  final Dio _dio;

  Options get _aiOpts => Options(receiveTimeout: ApiConfig.aiTimeout);

  @override
  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await _dio.post(
        '/chatbot/chat',
        data: {'message': message, 'conversationHistory': history},
        options: _aiOpts,
      );
      final data = asMap(unwrapData(res.data));
      return readString(data, ['reply'], 'Không có phản hồi');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<String> market(
    String message, {
    String? crop,
    String? region,
  }) async {
    try {
      final res = await _dio.post(
        '/chatbot/market',
        data: {
          'message': message.trim(),
          if (crop != null && crop.isNotEmpty) 'crop': crop,
          if (region != null && region.isNotEmpty) 'region': region,
          'conversationHistory': <Map<String, String>>[],
        },
        options: _aiOpts,
      );
      final data = asMap(unwrapData(res.data));
      return readString(data, ['advice', 'message'], 'Không có tư vấn');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<String> diagnose({required String imagePath, String? note}) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'plant.jpg'),
        if (note != null && note.isNotEmpty) 'note': note,
      });
      final res = await _dio.post(
        '/chatbot/diagnose',
        data: form,
        options: _aiOpts,
      );
      final data = asMap(unwrapData(res.data));
      return readString(data, ['diagnosis'], 'Không có chẩn đoán');
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
''')

w('features/ai/presentation/providers/ai_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/ai/data/repositories/chatbot_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/ai/domain/repositories/chatbot_repository.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepositoryImpl(ref.watch(dioProvider));
});
''')

# AGRI TREND
w('features/agri_trend/domain/entities/agri_trend.dart', r'''
import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class AgriTrend extends Equatable {
  const AgriTrend({
    required this.summary,
    required this.generatedAt,
    this.hotCrops = const [],
    this.alerts = const [],
  });

  final String summary;
  final String generatedAt;
  final List<Map<String, String>> hotCrops;
  final List<Map<String, String>> alerts;

  factory AgriTrend.fromJson(Map<String, dynamic> json) {
    return AgriTrend(
      summary: readString(json, ['summary']),
      generatedAt: readString(json, ['generatedAt', 'generated_at']),
      hotCrops: asList(json['hotCrops'] ?? json['hot_crops']).whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'name': readString(m, ['name']),
          'reason': readString(m, ['reason']),
          'sentiment': readString(m, ['sentiment']),
        };
      }).toList(),
      alerts: asList(json['alerts']).whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'type': readString(m, ['type']),
          'severity': readString(m, ['severity']),
          'message': readString(m, ['message']),
        };
      }).toList(),
    );
  }

  @override
  List<Object?> get props => [generatedAt, summary];
}
''')

w('features/agri_trend/domain/repositories/agri_trend_repository.dart', r'''
import 'package:chuoi_xanh_viet/features/agri_trend/domain/entities/agri_trend.dart';

abstract class AgriTrendRepository {
  Future<AgriTrend> getTrend({bool refresh = false});
}
''')

w('features/agri_trend/data/repositories/agri_trend_repository_impl.dart', r'''
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
''')

w('features/agri_trend/presentation/providers/agri_trend_providers.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/data/repositories/agri_trend_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/domain/entities/agri_trend.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/domain/repositories/agri_trend_repository.dart';

final agriTrendRepositoryProvider = Provider<AgriTrendRepository>((ref) {
  return AgriTrendRepositoryImpl(ref.watch(dioProvider));
});

final agriTrendProvider = FutureProvider.autoDispose<AgriTrend>((ref) {
  return ref.watch(agriTrendRepositoryProvider).getTrend();
});
''')

print('part5 done')
