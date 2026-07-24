import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:chuoi_xanh_viet/core/firebase/rtdb_refs.dart';

/// Online / offline presence keyed by Firebase Auth uid.
class PresenceService {
  String? _uid;
  String? _backendUserId;
  StreamSubscription<DatabaseEvent>? _connectedSub;

  bool get isActive => _uid != null;

  Future<void> goOnline({
    required String firebaseUid,
    String? backendUserId,
    String? displayName,
  }) async {
    await goOffline();
    _uid = firebaseUid;
    _backendUserId = backendUserId;
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
      if (backendUserId != null && backendUserId.isNotEmpty) {
        final lookup = RtdbRefs.presenceLookup(backendUserId);
        final lookupPayload = <String, dynamic>{
          'online': true,
          'firebaseUid': firebaseUid,
          'lastSeenAt': ServerValue.timestamp,
        };
        await lookup.set(lookupPayload);
        await lookup.onDisconnect().update({
          'online': false,
          'lastSeenAt': ServerValue.timestamp,
        });
      }
      _connectedSub = RtdbRefs.db.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value == true;
        if (!connected || _uid != firebaseUid) return;
        unawaited(ref.set(payload));
        unawaited(ref.onDisconnect().update({
          'online': false,
          'lastSeenAt': ServerValue.timestamp,
        }));
        if (backendUserId != null && backendUserId.isNotEmpty) {
          final lookup = RtdbRefs.presenceLookup(backendUserId);
          unawaited(lookup.set({
            'online': true,
            'firebaseUid': firebaseUid,
            'lastSeenAt': ServerValue.timestamp,
          }));
          unawaited(lookup.onDisconnect().update({
            'online': false,
            'lastSeenAt': ServerValue.timestamp,
          }));
        }
      });
    } catch (_) {
      // RTDB may be unconfigured until Firebase Console setup.
    }
  }

  Future<void> goOffline() async {
    await _connectedSub?.cancel();
    _connectedSub = null;
    final uid = _uid;
    final backendUserId = _backendUserId;
    _uid = null;
    _backendUserId = null;
    if (uid == null) return;
    try {
      await RtdbRefs.presence(uid).onDisconnect().cancel();
      await RtdbRefs.presence(uid).update({
        'online': false,
        'lastSeenAt': ServerValue.timestamp,
      });
      if (backendUserId != null && backendUserId.isNotEmpty) {
        await RtdbRefs.presenceLookup(backendUserId).onDisconnect().cancel();
        await RtdbRefs.presenceLookup(backendUserId).update({
          'online': false,
          'lastSeenAt': ServerValue.timestamp,
        });
      }
    } catch (_) {}
  }

  /// Live stream of whether [firebaseUid] is online.
  Stream<bool> watchOnline(String firebaseUid) {
    return RtdbRefs.presence(firebaseUid).onValue.map(_readOnline);
  }

  /// Live stream keyed by backend user id (for chat peers).
  Stream<bool> watchOnlineByBackendId(String backendUserId) {
    if (backendUserId.isEmpty) return Stream<bool>.value(false);
    return RtdbRefs.presenceLookup(backendUserId).onValue.map(_readOnline);
  }

  static bool _readOnline(DatabaseEvent event) {
    final raw = event.snapshot.value;
    if (raw is Map) {
      final v = raw['online'];
      return v == true || v == 1 || v == 'true';
    }
    return false;
  }
}
