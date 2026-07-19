import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(dioProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<PaginatedResult<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).list();
});
