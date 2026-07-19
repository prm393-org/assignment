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
