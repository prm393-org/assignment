import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
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
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final log = page.items[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              title: Text('${log.module} · ${log.action}'),
              subtitle: Text(
                '${log.actorName ?? 'system'} · ${Formatters.dateTime(log.createdAt)}\n${log.path ?? ''}',
              ),
              isThreeLine: true,
              trailing: Text(
                log.status,
                style: TextStyle(
                  color: log.status == 'success' ? AppColors.success : AppColors.error,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
