import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:chuoi_xanh_viet/core/firebase/rtdb_refs.dart';

/// Online / offline presence keyed by Firebase Auth uid.
class PresenceService {
  String? _uid;
  StreamSubscription<DatabaseEvent>? _connectedSub;

  bool get isActive => _uid != null;

  Future<void> goOnline({
    required String firebaseUid,
    String? backendUserId,
    String? displayName,
  }) async {
    await goOffline();
    _uid = firebaseUid;
    final ref = RtdbRefs.presence(firebaseUid);
    final payload = <String, dynamic>{
      'online': true,
      'lastSeenAt': ServerValue.timestamp,
      'backendUserId': ?backendUserId,
      'displayName': ?displayName,
    };
    try {
      await ref.set(payload);
      await ref.onDisconnect().update({
        'online': false,
        'lastSeenAt': ServerValue.timestamp,
      });
      _connectedSub = RtdbRefs.db.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value == true;
        if (!connected || _uid != firebaseUid) return;
        unawaited(ref.set(payload));
        unawaited(ref.onDisconnect().update({
          'online': false,
          'lastSeenAt': ServerValue.timestamp,
        }));
      });
    } catch (_) {
      // RTDB may be unconfigured until Firebase Console setup.
    }
  }

  Future<void> goOffline() async {
    await _connectedSub?.cancel();
    _connectedSub = null;
    final uid = _uid;
    _uid = null;
    if (uid == null) return;
    try {
      await RtdbRefs.presence(uid).onDisconnect().cancel();
      await RtdbRefs.presence(uid).update({
        'online': false,
        'lastSeenAt': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  /// Live stream of whether [firebaseUid] is online.
  Stream<bool> watchOnline(String firebaseUid) {
    return RtdbRefs.presence(firebaseUid).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        final v = raw['online'];
        return v == true || v == 1 || v == 'true';
      }
      return false;
    });
  }
}
