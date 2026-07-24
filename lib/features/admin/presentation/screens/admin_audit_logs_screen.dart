import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/providers/admin_providers.dart';

class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký kiểm toán')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(auditLogsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có log',
        emptyIcon: Icons.history_rounded,
        builder: (page) => RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(auditLogsProvider);
            await ref.read(auditLogsProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final log = page.items[i];
              final ok = log.status == 'success';
              return SurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.module} · ${log.action}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${log.actorName ?? 'system'} · ${Formatters.dateTime(log.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (log.path != null && log.path!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              log.path!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusChip(
                      label: log.status,
                      tone: ok ? StatusTone.success : StatusTone.danger,
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
