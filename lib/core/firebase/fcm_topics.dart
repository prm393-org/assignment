/// Central FCM topic naming.
///
/// Push targeting is **topic-only**: every signed-in user subscribes to a
/// handful of topics at login (see `messagingBindingProvider`), so a sender
/// only ever needs an id it already holds (shopId / farmId / orderId /
/// user id) and never the recipient's FCM token or a second id space.
///
/// Topic names must match `[a-zA-Z0-9-_.~%]+`; [_slug] enforces that.
abstract final class FcmTopics {
  /// Every device is subscribed — used by admin broadcast to "all".
  static const String broadcast = 'broadcast';

  /// Per-role fan-out, e.g. `role_farmer` — used by audience-scoped broadcast.
  static String role(String role) => 'role_${_slug(role)}';

  /// Direct-to-user by Firebase Auth uid (forum authors are keyed this way).
  static String userByFirebaseUid(String uid) => 'u_${_slug(uid)}';

  /// Direct-to-user by backend `AuthUser.id` (chat peers are keyed this way).
  static String userByBackendId(String backendUserId) =>
      'ub_${_slug(backendUserId)}';

  /// A shop the farmer owns — receives "new order" pushes.
  static String shop(String shopId) => 'shop_${_slug(shopId)}';

  /// A farm the farmer owns — receives certificate-review pushes.
  static String farm(String farmId) => 'farm_${_slug(farmId)}';

  /// A single order — the buyer subscribes at checkout to receive
  /// status-change pushes without the seller needing the buyer's id.
  static String order(String orderId) => 'order_${_slug(orderId)}';

  static String _slug(String raw) =>
      raw.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
}
