import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';

class ShopManageScreen extends ConsumerWidget {
  const ShopManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myShopsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gian hàng của tôi')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createShop(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(myShopsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có gian hàng',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final s = list[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(s.name),
              subtitle: Text(s.farmName ?? s.status),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/farmer/shop/${s.id}'),
            );
          },
        ),
      ),
    );
  }

  Future<void> _createShop(BuildContext context, WidgetRef ref) async {
    final farms = await ref.read(myFarmsProvider.future);
    if (farms.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần tạo nông trại trước')),
      );
      return;
    }
    String farmId = farms.first.id;
    final name = TextEditingController(text: 'Gian hàng ${farms.first.name}');
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tạo gian hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: farmId,
                items: [
                  for (final f in farms)
                    DropdownMenuItem(value: f.id, child: Text(f.name)),
                ],
                onChanged: (v) => setLocal(() => farmId = v ?? farmId),
                decoration: const InputDecoration(labelText: 'Nông trại'),
              ),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên gian hàng')),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(shopManageRepositoryProvider).createShop(
            farmId: farmId,
            name: name.text.trim(),
            description: desc.text.trim().isEmpty ? null : desc.text.trim(),
          );
      ref.invalidate(myShopsProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }
}
