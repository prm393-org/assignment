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
      byRole: byRoleRaw.map((k, v) => MapEntry(k, int.tryParse('$v') ?? 0)),
      ordersByStatus:
          byStatusOrders.map((k, v) => MapEntry(k, int.tryParse('$v') ?? 0)),
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
