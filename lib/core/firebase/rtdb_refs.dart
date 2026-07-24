import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:chuoi_xanh_viet/firebase_options.dart';

/// Realtime Database path helpers (Firebase Auth uid unless noted).
abstract final class RtdbRefs {
  /// The database lives in `asia-southeast1`, but `google-services.json` ships
  /// without `firebase_url`, so the natively auto-created `[DEFAULT]` app falls
  /// back to the US URL and the server kills the connection ("Database lives in
  /// a different region"). Bind the URL explicitly so the region is always right.
  static FirebaseDatabase get db {
    final url = DefaultFirebaseOptions.currentPlatform.databaseURL;
    if (url == null || url.isEmpty) return FirebaseDatabase.instance;
    return FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: url);
  }

  static DatabaseReference presence(String firebaseUid) =>
      db.ref('presence/$firebaseUid');

  static DatabaseReference chatMessages(String conversationId) =>
      db.ref('chat_messages/$conversationId');

  static DatabaseReference chatMessage(
    String conversationId,
    String messageId,
  ) =>
      db.ref('chat_messages/$conversationId/$messageId');

  static DatabaseReference orderStatus(String orderId) =>
      db.ref('order_status/$orderId');

  static DatabaseReference notificationUnread(String firebaseUid) =>
      db.ref('notification_unread/$firebaseUid');
}
