import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

class FarmsListScreen extends ConsumerWidget {
  const FarmsListScreen({super.key});

  Future<void> _deleteFarm(
    BuildContext context,
    WidgetRef ref,
    Farm farm,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá nông trại'),
        content: Text('Xoá "${farm.name}"? Hành động không hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(farmRepositoryProvider).deleteFarm(farm.id);
      ref.invalidate(myFarmsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá nông trại')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFarmsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản lý', style: Theme.of(context).textTheme.bodySmall),
            Text('Nông trại', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farmer/farms/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm trại'),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(myFarmsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có nông trại. Tạo mới để bắt đầu.',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            if (i == 0) {
              return SoftHeroBanner(
                title: 'Trang trại của bạn',
                subtitle: '${list.length} nông trại đang quản lý',
                actionLabel: 'Tạo nông trại',
                onAction: () => context.push('/farmer/farms/create'),
                icon: Icons.agriculture_rounded,
              );
            }
            final f = list[i - 1];
            return SurfaceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/farmer/farms/${f.id}'),
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.grass_rounded,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${f.areaHa} ha · ${f.cropMain}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                f.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        if (f.inCooperative) ...[
                          const SizedBox(height: 8),
                          const StatusChip(
                            label: 'Thuộc HTX',
                            tone: StatusTone.success,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        context.push('/farmer/farms/${f.id}/edit');
                      } else if (v == 'delete') {
                        _deleteFarm(context, ref, f);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      PopupMenuItem(value: 'delete', child: Text('Xoá')),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
