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

  final prefix = switch (role) {
    AuthRole.farmer => '/farmer',
    AuthRole.admin => '/admin',
    AuthRole.cooperative => '/farmer',
    _ => '/consumer',
  };

  if (pathOnly.contains('/messages') || pathOnly.contains('/chat')) {
    final conversationId = query['c'] ?? query['conversationId'];
    if (conversationId != null && conversationId.isNotEmpty) {
      return '$prefix/chat/$conversationId';
    }
    return '/chat';
  }

  final forumId = RegExp(r'/forum/([^/?]+)').firstMatch(pathOnly)?.group(1);
  if (forumId != null && forumId != 'create' && forumId != 'edit') {
    if (pathOnly.startsWith('/farmer')) return '/farmer/forum/$forumId';
    if (pathOnly.startsWith('/admin')) return '/admin/forum/$forumId';
    return '$prefix/forum/$forumId';
  }

  final orderId = RegExp(r'/orders?/([^/?]+)').firstMatch(pathOnly)?.group(1);
  if (orderId != null) {
    if (pathOnly.contains('/farmer')) return '/farmer/orders/$orderId';
    return '/consumer/orders/$orderId';
  }

  if (pathOnly.startsWith('/consumer') ||
      pathOnly.startsWith('/farmer') ||
      pathOnly.startsWith('/admin') ||
      pathOnly.startsWith('/chat') ||
      pathOnly.startsWith('/trace') ||
      pathOnly.startsWith('/qr-scan')) {
    return pathOnly;
  }

  if (pathOnly == '/forum' || pathOnly.startsWith('/forum/')) {
    return '$prefix$pathOnly';
  }

  return null;
}
