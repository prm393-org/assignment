import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/notification/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<PaginatedResult<AppNotification>> list({int page = 1, bool? unreadOnly});
  Stream<PaginatedResult<AppNotification>> watchInbox({bool? unreadOnly});
  Future<void> markRead(String id);
  Future<void> markAllRead();

  /// Recomputes the unread badge counter from the inbox, repairing it after
  /// notifications that were written while the counter was unreachable.
  Future<void> syncUnreadCount();
}
