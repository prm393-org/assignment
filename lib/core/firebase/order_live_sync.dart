import 'package:firebase_database/firebase_database.dart';
import 'package:chuoi_xanh_viet/core/firebase/rtdb_refs.dart';

/// Live order status mirror on RTDB.
abstract final class OrderLiveSync {
  static Future<void> publishStatus({
    required String orderId,
    required String status,
    String? buyerBackendUserId,
    String? sellerBackendUserId,
  }) async {
    if (orderId.isEmpty || status.isEmpty) return;
    try {
      await RtdbRefs.orderStatus(orderId).set({
        'status': status,
        'updatedAt': ServerValue.timestamp,
        'buyerUserId': ?buyerBackendUserId,
        'sellerUserId': ?sellerBackendUserId,
      });
    } catch (_) {}
  }

  static Stream<String?> watchStatus(String orderId) {
    return RtdbRefs.orderStatus(orderId).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        final status = raw['status'];
        if (status == null) return null;
        final s = '$status'.trim();
        return s.isEmpty ? null : s;
      }
      return null;
    });
  }
}
