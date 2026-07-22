import 'package:firebase_database/firebase_database.dart';
import 'package:chuoi_xanh_viet/core/firebase/rtdb_refs.dart';

/// Unread notification counter on RTDB (live badge).
abstract final class NotificationCounterSync {
  static Future<void> setCount(String firebaseUid, int count) async {
    if (firebaseUid.isEmpty) return;
    try {
      await RtdbRefs.notificationUnread(firebaseUid).set({
        'count': count < 0 ? 0 : count,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  static Future<void> increment(String firebaseUid, [int by = 1]) async {
    if (firebaseUid.isEmpty) return;
    try {
      final ref = RtdbRefs.notificationUnread(firebaseUid).child('count');
      await ref.runTransaction((Object? current) {
        final n = current is num
            ? current.toInt()
            : (int.tryParse('$current') ?? 0);
        return Transaction.success(n + by);
      });
      await RtdbRefs.notificationUnread(firebaseUid)
          .child('updatedAt')
          .set(ServerValue.timestamp);
    } catch (_) {}
  }

  static Stream<int> watchCount(String firebaseUid) {
    if (firebaseUid.isEmpty) {
      return Stream<int>.value(0);
    }
    return RtdbRefs.notificationUnread(firebaseUid).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        final c = raw['count'];
        if (c is num) return c.toInt();
        return int.tryParse('$c') ?? 0;
      }
      if (raw is num) return raw.toInt();
      return 0;
    });
  }
}
