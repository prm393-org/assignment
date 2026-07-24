import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chuoi_xanh_viet/core/error/firestore_exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/firebase/firestore_refs.dart';
import 'package:chuoi_xanh_viet/core/firebase/notification_counter_sync.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/repositories/notification_repository.dart';

const _pageSize = 30;

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required String? Function() currentUid})
      : _currentUid = currentUid;

  final String? Function() _currentUid;

  @override
  Future<PaginatedResult<AppNotification>> list({
    int page = 1,
    bool? unreadOnly,
  }) async {
    try {
      final snapshot = await _query(unreadOnly).get();
      final items =
          snapshot.docs.map((d) => AppNotification.fromJson(_json(d))).toList();
      return PaginatedResult(items: items, total: items.length, limit: _pageSize);
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Stream<PaginatedResult<AppNotification>> watchInbox({bool? unreadOnly}) {
    return _query(unreadOnly).snapshots().map((snapshot) {
      final items =
          snapshot.docs.map((d) => AppNotification.fromJson(_json(d))).toList();
      return PaginatedResult(items: items, total: items.length, limit: _pageSize);
    });
  }

  Query<Map<String, dynamic>> _query(bool? unreadOnly) {
    Query<Map<String, dynamic>> query = FirestoreRefs.notificationsRef()
        .where('userId', isEqualTo: _currentUid());
    if (unreadOnly == true) {
      query = query.where('read', isEqualTo: false);
    }
    return query.orderBy('createdAt', descending: true).limit(_pageSize);
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await FirestoreRefs.notificationsRef().doc(id).update({'read': true});
      await syncUnreadCount();
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      final uid = _currentUid();
      final snapshot = await FirestoreRefs.notificationsRef()
          .where('userId', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();
      final docs = snapshot.docs;
      // Firestore batches cap at 500 writes.
      for (var i = 0; i < docs.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in docs.skip(i).take(500)) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
      if (uid != null) await NotificationCounterSync.setCount(uid, 0);
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> syncUnreadCount() async {
    final uid = _currentUid();
    if (uid == null) return;
    final snapshot = await FirestoreRefs.notificationsRef()
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    await NotificationCounterSync.setCount(uid, snapshot.docs.length);
  }

  Map<String, dynamic> _json(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      'title': data['title'],
      'content': data['content'],
      'read': data['read'],
      'createdAt': _isoFromTimestamp(data['createdAt']),
      'type': data['type'],
      'link': data['link'],
    };
  }

  String? _isoFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is String) return value;
    return null;
  }
}
