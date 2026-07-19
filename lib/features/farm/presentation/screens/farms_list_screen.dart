import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
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
      appBar: AppBar(title: const Text('Nông trại')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/farmer/farms/create'),
        child: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(myFarmsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có nông trại. Tạo mới để bắt đầu.',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final f = list[i];
            return ListTile(
              onTap: () => context.push('/farmer/farms/${f.id}'),
              onLongPress: () => _deleteFarm(context, ref, f),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(f.name),
              subtitle:
                  Text('${f.areaHa} ha · ${f.cropMain}\n${f.locationLabel}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _deleteFarm(context, ref, f);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Xoá')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
