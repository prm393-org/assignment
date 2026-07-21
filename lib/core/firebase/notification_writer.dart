import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chuoi_xanh_viet/core/firebase/firestore_refs.dart';

/// Writes a notification doc for [userId] (a Firebase Auth uid, not a
/// backend `AuthUser.id`). There is no backend writer for notifications —
/// whatever client action causes one (a forum reply, an order status
/// change, ...) must call this directly. Failures are swallowed: a missed
/// notification must never block the action that triggered it.
Future<void> notifyUser({
  required String userId,
  required String title,
  required String content,
  String type = 'system',
  String? link,
}) async {
  try {
    await FirestoreRefs.notificationsRef().add({
      'userId': userId,
      'title': title,
      'content': content,
      'type': type,
      'link': link,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    // Best-effort; a failed notification write must not block the caller.
  }
}
