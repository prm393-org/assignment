import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

class FarmDetailScreen extends ConsumerWidget {
  const FarmDetailScreen({super.key, required this.farmId});
  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(myFarmsProvider);
    final seasons = ref.watch(farmSeasonsProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nông trại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final farm =
                  farms.valueOrNull?.where((f) => f.id == farmId).firstOrNull;
              if (farm != null) {
                context.push('/farmer/farms/$farmId/edit');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteFarm(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSeason(context, ref),
        label: const Text('Thêm mùa vụ'),
        icon: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: farms.asLike,
        onRetry: () => ref.invalidate(myFarmsProvider),
        builder: (list) {
          final farm = list.where((f) => f.id == farmId).firstOrNull;
          if (farm == null) {
            return const EmptyState(message: 'Không tìm thấy nông trại');
          }
          return ListView(
            padding: AppSpacing.screen,
            children: [
              Text(farm.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('${farm.areaHa} ha · ${farm.cropMain}'),
              Text(farm.locationLabel),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/farmer/farms/$farmId/join-htx'),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Tham gia HTX'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Mùa vụ', style: Theme.of(context).textTheme.titleLarge),
              AsyncBody(
                value: seasons.asLike,
                onRetry: () => ref.invalidate(farmSeasonsProvider(farmId)),
                isEmpty: (s) => s.isEmpty,
                emptyMessage: 'Chưa có mùa vụ',
                builder: (sList) => Column(
                  children: [
                    for (final s in sList)
                      ListTile(
                        title: Text('${s.code} · ${s.cropName}'),
                        subtitle: Text('${s.status} · ${Formatters.date(s.startDate)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/farmer/seasons/${s.id}'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteFarm(BuildContext context, WidgetRef ref) async {
    final farm =
        ref.read(myFarmsProvider).valueOrNull?.where((f) => f.id == farmId).firstOrNull;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá nông trại'),
        content: Text(
          'Xoá "${farm?.name ?? 'nông trại này'}"? Hành động không hoàn tác.',
        ),
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
      await ref.read(farmRepositoryProvider).deleteFarm(farmId);
      ref.invalidate(myFarmsProvider);
      if (!context.mounted) return;
      context.pop();
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

  Future<void> _createSeason(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final crop = TextEditingController(text: 'Chuối');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo mùa vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Mã mùa vụ')),
            TextField(controller: crop, decoration: const InputDecoration(labelText: 'Cây trồng')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(farmRepositoryProvider).createSeason({
        'farmId': farmId,
        'code': code.text.trim(),
        'cropName': crop.text.trim(),
        'startDate': DateTime.now().toIso8601String().substring(0, 10),
        'status': 'planning',
      });
      ref.invalidate(farmSeasonsProvider(farmId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e', style: const TextStyle(color: AppColors.onPrimary))),
      );
    }
  }
}
