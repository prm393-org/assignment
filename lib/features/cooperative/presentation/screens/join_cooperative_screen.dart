import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/cooperative/presentation/providers/cooperative_providers.dart';

class JoinCooperativeScreen extends ConsumerWidget {
  const JoinCooperativeScreen({super.key, required this.farmId});

  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(htxListForFarmProvider(farmId));
    return Scaffold(
      appBar: AppBar(title: const Text('Tham gia HTX')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(htxListForFarmProvider(farmId)),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Không có HTX phù hợp',
        builder: (list) {
          return ListView.separated(
            padding: AppSpacing.screen,
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final htx = list[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.hairline),
                ),
                title: Text(htx.name),
                subtitle: htx.address != null && htx.address!.isNotEmpty
                    ? Text(htx.address!)
                    : (htx.description != null && htx.description!.isNotEmpty
                        ? Text(htx.description!)
                        : null),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/farmer/farms/$farmId/join-htx/${htx.id}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
