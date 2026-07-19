import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng quan', style: Theme.of(context).textTheme.bodySmall),
            Text('Quản trị', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(adminDashboardProvider),
        builder: (s) => ListView(
          padding: AppSpacing.screen,
          children: [
            SoftHeroBanner(
              title: 'Điều hành nền tảng',
              subtitle: 'Theo dõi người dùng, chứng nhận và hoạt động hệ thống.',
              icon: Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatPill(label: 'Người dùng', value: '${s.totalUsers}'),
                StatPill(label: 'Chứng nhận chờ', value: '${s.pendingCerts}'),
                StatPill(label: 'User 7 ngày', value: '${s.newUsers7d}'),
                StatPill(label: 'Đơn 7 ngày', value: '${s.newOrders7d}'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Thao tác nhanh', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Duyệt chứng nhận'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/admin/certificates'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: const Text('Broadcast thông báo'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/admin/broadcast'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Audit logs'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/admin/audit-logs'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
