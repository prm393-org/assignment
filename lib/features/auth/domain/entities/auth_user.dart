import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.zaloUserId,
    this.contactAddress,
    this.telegramLinked = false,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatarUrl;
  final String? zaloUserId;
  final String? contactAddress;
  final bool telegramLinked;

  AuthRole? get authRole => normalizeAuthRole(role);

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: readString(json, ['id']),
      fullName: readString(json, ['fullName', 'full_name']),
      email: readString(json, ['email']),
      phone: readString(json, ['phone']),
      role: readString(json, ['role']),
      status: readString(json, ['status']),
      avatarUrl: readStringOrNull(json, ['avatarUrl', 'avatar_url']),
      zaloUserId: readStringOrNull(json, ['zaloUserId', 'zalo_user_id']),
      contactAddress:
          readStringOrNull(json, ['contactAddress', 'contact_address']),
      telegramLinked: readBool(json, ['telegramLinked', 'telegram_linked']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'avatarUrl': avatarUrl,
        'zaloUserId': zaloUserId,
        'contactAddress': contactAddress,
        'telegramLinked': telegramLinked,
      };

  @override
  List<Object?> get props => [id, email, role, status, fullName];
}
