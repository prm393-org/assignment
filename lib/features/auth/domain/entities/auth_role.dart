enum AuthRole { consumer, farmer, admin, cooperative }

AuthRole? normalizeAuthRole(String? role) {
  if (role == null) return null;
  final normalized = role.trim().toLowerCase();
  if (normalized == 'consumer' ||
      normalized == 'role_consumer' ||
      normalized == 'buyer' ||
      normalized == 'role_buyer') {
    return AuthRole.consumer;
  }
  if (normalized == 'admin' || normalized == 'role_admin') {
    return AuthRole.admin;
  }
  if (normalized == 'farmer' || normalized == 'role_farmer') {
    return AuthRole.farmer;
  }
  if (normalized == 'cooperative' ||
      normalized == 'cooperativ' ||
      normalized == 'role_cooperative') {
    return AuthRole.cooperative;
  }
  return null;
}

String roleHomePath(AuthRole? role) {
  switch (role) {
    case AuthRole.farmer:
      return '/farmer/home';
    case AuthRole.admin:
      return '/admin/home';
    case AuthRole.cooperative:
      return '/consumer/home';
    case AuthRole.consumer:
    case null:
      return '/consumer/home';
  }
}

/// The role's route section (no trailing `/home`), for building sibling
/// routes such as `<section>/notifications`.
String roleSectionPath(AuthRole? role) {
  switch (role) {
    case AuthRole.farmer:
      return '/farmer';
    case AuthRole.admin:
      return '/admin';
    case AuthRole.cooperative:
    case AuthRole.consumer:
    case null:
      return '/consumer';
  }
}

String roleLabel(AuthRole role) {
  switch (role) {
    case AuthRole.consumer:
      return 'Người mua';
    case AuthRole.farmer:
      return 'Nông dân';
    case AuthRole.admin:
      return 'Quản trị';
    case AuthRole.cooperative:
      return 'HTX';
  }
}
