import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/certificate/presentation/providers/certificate_providers.dart';

class AdminCertificatesScreen extends ConsumerWidget {
  const AdminCertificatesScreen({super.key});

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(certificateRepositoryProvider).approve(id);
      ref.invalidate(pendingAdminCertificatesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final reasonCtrl = TextEditingController(text: 'Không đạt yêu cầu');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối chứng nhận?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Lý do'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final reason = reasonCtrl.text.trim().isEmpty
        ? 'Không đạt yêu cầu'
        : reasonCtrl.text.trim();
    try {
      await ref.read(certificateRepositoryProvider).reject(id, reason);
      ref.invalidate(pendingAdminCertificatesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingAdminCertificatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chứng nhận chờ duyệt')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(pendingAdminCertificatesProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Không còn chứng nhận chờ',
        emptyIcon: Icons.verified_outlined,
        builder: (page) => RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(pendingAdminCertificatesProvider);
            await ref.read(pendingAdminCertificatesProvider.future);
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final c = page.items[i];
              return SurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.type} · ${c.certificateNo ?? ''}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            c.farmName ?? c.farmId,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _approve(context, ref, c.id),
                      icon: const Icon(Icons.check_rounded, color: AppColors.success),
                      label: const Text('Duyệt'),
                    ),
                    TextButton.icon(
                      onPressed: () => _reject(context, ref, c.id),
                      icon: const Icon(Icons.close_rounded, color: AppColors.error),
                      label:                       Text(
                        'Từ chối',
                        style: TextStyle(color: AppColors.error),
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
