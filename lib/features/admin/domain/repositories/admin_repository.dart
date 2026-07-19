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
