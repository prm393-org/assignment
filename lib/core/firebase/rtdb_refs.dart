import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:chuoi_xanh_viet/firebase_options.dart';

/// Realtime Database path helpers (Firebase Auth uid unless noted).
abstract final class RtdbRefs {
  static const String databaseUrl =
      'https://prm301-asm-default-rtdb.asia-southeast1.firebasedatabase.app';

  static FirebaseDatabase? _db;

  static FirebaseDatabase get db {
    _db ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.android.databaseURL ?? databaseUrl,
    );
    return _db!;
  }

  static DatabaseReference presence(String firebaseUid) =>
      db.ref('presence/$firebaseUid');

  /// Lookup online state by backend `AuthUser.id` (chat/order peers).
  static DatabaseReference presenceLookup(String backendUserId) =>
      db.ref('presence_lookup/$backendUserId');

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
