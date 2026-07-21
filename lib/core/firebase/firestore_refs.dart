import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralizes Firestore collection paths so repositories never hardcode
/// path strings. `carts/{uid}/items` scopes cart docs to their owner for
/// the security rule `request.auth.uid == uid`; `notifications` is a flat
/// collection filtered by a `userId` field rather than a per-user
/// subcollection, since notifications must be writable by *other* users
/// (e.g. whoever triggered the event), not only by the recipient.
class FirestoreRefs {
  FirestoreRefs._();

  static CollectionReference<Map<String, dynamic>> cartItemsRef(String uid) =>
      FirebaseFirestore.instance
          .collection('carts')
          .doc(uid)
          .collection('items');

  static CollectionReference<Map<String, dynamic>> forumPostsRef() =>
      FirebaseFirestore.instance.collection('forum_posts');

  static CollectionReference<Map<String, dynamic>> forumCommentsRef(
    String postId,
  ) =>
      forumPostsRef().doc(postId).collection('comments');

  static CollectionReference<Map<String, dynamic>> notificationsRef() =>
      FirebaseFirestore.instance.collection('notifications');
}
