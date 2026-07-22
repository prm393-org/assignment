import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chuoi_xanh_viet/core/firebase/firestore_refs.dart';
import 'package:chuoi_xanh_viet/core/firebase/notification_counter_sync.dart';

/// Writes a notification doc for [userId] (a Firebase Auth uid, not a
/// backend `AuthUser.id`). Also bumps the RTDB unread counter for live badges.
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
    unawaited(NotificationCounterSync.increment(userId));
  } catch (_) {
    // Best-effort; a failed notification write must not block the caller.
  }
}
