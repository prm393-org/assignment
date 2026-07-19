import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/certificate/presentation/providers/certificate_providers.dart';

class AdminCertificatesScreen extends ConsumerWidget {
  const AdminCertificatesScreen({super.key});

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
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = page.items[i];
            return Card(
              child: ListTile(
                title: Text('${c.type} · ${c.certificateNo ?? ''}'),
                subtitle: Text(c.farmName ?? c.farmId),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.success),
                      onPressed: () async {
                        try {
                          await ref.read(certificateRepositoryProvider).approve(c.id);
                          ref.invalidate(pendingAdminCertificatesProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e is Failure ? e.message : '$e')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error),
                      onPressed: () async {
                        try {
                          await ref.read(certificateRepositoryProvider).reject(c.id, 'Không đạt yêu cầu');
                          ref.invalidate(pendingAdminCertificatesProvider);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e is Failure ? e.message : '$e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
