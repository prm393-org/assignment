import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/notification_navigation.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final role = ref.watch(authNotifierProvider).role;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(notificationsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Không có thông báo mới',
        emptyIcon: Icons.notifications_none_rounded,
        builder: (page) => RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            await ref.read(notificationsProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final n = page.items[i];
              return SurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: n.read
                    ? AppColors.surface
                    : AppColors.mint.withValues(alpha: 0.35),
                onTap: () async {
                  if (!n.read) {
                    await ref.read(notificationRepositoryProvider).markRead(n.id);
                    ref.invalidate(notificationsProvider);
                  }
                  if (!context.mounted) return;
                  final route = resolveNotificationRoute(n.link, role: role);
                  if (route != null) context.push(route);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBadge(
                      icon: n.read
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      color:
                          n.read ? AppColors.surfaceElevated : AppColors.mintDeep,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              if (!n.read)
                                Container(
                                  width: AppSpacing.sm,
                                  height: AppSpacing.sm,
                                  decoration: const BoxDecoration(
                                    color: AppColors.forest,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            n.content,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            Formatters.dateTime(n.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
