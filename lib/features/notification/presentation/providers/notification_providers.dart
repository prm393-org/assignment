import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/firebase/notification_counter_sync.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    currentUid: () => ref.read(currentFirebaseUidProvider),
  );
});

final notificationsProvider =
    StreamProvider.autoDispose<PaginatedResult<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchInbox();
});

/// The RTDB badge counter only moves when `notifyUser` increments it, so a
/// notification written while the counter was unreachable leaves the badge
/// permanently stale. Recompute it from the inbox once the uid is known.
/// Watched app-wide from `app.dart`.
final notificationCounterBindingProvider = Provider<void>((ref) {
  ref.listen<String?>(currentFirebaseUidProvider, (prev, next) {
    if (next == null || next.isEmpty) return;
    unawaited(ref.read(notificationRepositoryProvider).syncUnreadCount());
  }, fireImmediately: true);
});

/// Live unread badge from Firebase RTDB.
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final uid = ref.watch(currentFirebaseUidProvider);
  if (uid == null || uid.isEmpty) return Stream<int>.value(0);
  return NotificationCounterSync.watchCount(uid);
});
