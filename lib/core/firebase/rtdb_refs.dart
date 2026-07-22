import 'package:firebase_database/firebase_database.dart';

/// Realtime Database path helpers (Firebase Auth uid unless noted).
abstract final class RtdbRefs {
  static FirebaseDatabase get db {
    // databaseURL comes from DefaultFirebaseOptions once configured.
    return FirebaseDatabase.instance;
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
