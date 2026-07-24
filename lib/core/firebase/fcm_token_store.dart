import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists device FCM tokens and a `firebaseUid → backend user` mapping in
/// Firestore.
///
/// Neither is required for push targeting (that is topic-based), so all
/// writes are best-effort. They exist for two reasons:
///  - a stored token lets you send a Console test to one specific device;
///  - `users/{uid}` bridges the two id spaces (backend `AuthUser.id` vs the
///    Firebase Auth uid) for anything that later wants to resolve one to the
///    other.
///
/// Requires Firestore rules that let a signed-in user write their own
/// `users/{uid}` doc and `fcm_tokens/{uid}/**` — see `push-worker/README.md`.
abstract final class FcmTokenStore {
  static Future<void> saveToken({
    required String firebaseUid,
    required String token,
    String? backendUserId,
    String? role,
    String? platform,
  }) async {
    if (firebaseUid.isEmpty || token.isEmpty) return;
    try {
      final db = FirebaseFirestore.instance;
      await db
          .collection('fcm_tokens')
          .doc(firebaseUid)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await db.collection('users').doc(firebaseUid).set({
        'backendUserId': backendUserId,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> removeToken({
    required String firebaseUid,
    required String token,
  }) async {
    if (firebaseUid.isEmpty || token.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(firebaseUid)
          .collection('tokens')
          .doc(token)
          .delete();
    } catch (_) {}
  }
}
