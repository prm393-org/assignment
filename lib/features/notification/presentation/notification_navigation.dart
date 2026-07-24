import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';

/// Maps notification `link` values (RN or Flutter paths) to go_router routes.
String? resolveNotificationRoute(
  String? link, {
  AuthRole? role,
}) {
  if (link == null) return null;
  var path = link.trim();
  if (path.isEmpty) return null;

  if (path.startsWith('http://') || path.startsWith('https://')) {
    final uri = Uri.tryParse(path);
    if (uri == null) return null;
    path = uri.path;
    if (uri.hasQuery) path = '$path?${uri.query}';
  }
  if (!path.startsWith('/')) path = '/$path';

  final uri = Uri.tryParse(path.startsWith('http') ? path : 'app://local$path');
  final pathOnly = uri?.path ?? path.split('?').first;
  final query = uri?.queryParameters ?? const <String, String>{};

  // Cooperative uses consumer shell; admin has no forum routes.
  final prefix = switch (role) {
    AuthRole.farmer => '/farmer',
    AuthRole.admin => '/admin',
    AuthRole.cooperative => '/consumer',
    _ => '/consumer',
  };

  if (pathOnly.contains('/messages') || pathOnly.contains('/chat')) {
    final conversationId = query['c'] ?? query['conversationId'];
    if (conversationId != null && conversationId.isNotEmpty) {
      return '$prefix/chat/$conversationId';
    }
    return '$prefix/chat';
  }

  final forumId = RegExp(r'/forum/([^/?]+)').firstMatch(pathOnly)?.group(1);
  if (forumId != null && forumId != 'create' && forumId != 'edit') {
    if (role == AuthRole.admin) {
      return '/admin/home';
    }
    if (pathOnly.startsWith('/farmer') || role == AuthRole.farmer) {
      return '/farmer/forum/$forumId';
    }
    return '/consumer/forum/$forumId';
  }

  final orderId = RegExp(r'/orders?/([^/?]+)').firstMatch(pathOnly)?.group(1);
  if (orderId != null) {
    if (pathOnly.contains('/farmer') || role == AuthRole.farmer) {
      return '/farmer/orders/$orderId';
    }
    return '/consumer/orders/$orderId';
  }

  if (pathOnly == '/qr-scan' || pathOnly.startsWith('/qr-scan')) {
    return '/consumer/trace/scan';
  }

  if (pathOnly.startsWith('/consumer') ||
      pathOnly.startsWith('/farmer') ||
      pathOnly.startsWith('/admin') ||
      pathOnly.startsWith('/chat') ||
      pathOnly.startsWith('/trace')) {
    // Rewrite admin forum deep links that have no matching routes.
    if (pathOnly.startsWith('/admin/forum')) {
      return role == AuthRole.admin ? '/admin/home' : '/consumer/forum';
    }
    return pathOnly;
  }

  if (pathOnly == '/forum' || pathOnly.startsWith('/forum/')) {
    if (role == AuthRole.admin) return '/admin/home';
    return '$prefix$pathOnly';
  }

  return null;
}
