import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopEarningsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Doanh thu')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(shopEarningsProvider),
        emptyMessage: 'Chưa có dữ liệu doanh thu',
        builder: (e) => RefreshIndicator(
          color: AppColors.forest,
          onRefresh: () async {
            ref.invalidate(shopEarningsProvider);
            await ref.read(shopEarningsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.screen,
            children: [
              _tile(context, 'Đã thanh toán cho bạn', Formatters.money(e.finalizedSellerPayout)),
              const SizedBox(height: AppSpacing.md),
              _tile(context, 'GMV đã chốt', Formatters.money(e.totalGmvFinalized)),
              const SizedBox(height: AppSpacing.md),
              _tile(
                context,
                'Hoa hồng nền tảng',
                Formatters.money(e.totalPlatformCommissionFinalized),
              ),
              const SizedBox(height: AppSpacing.md),
              _tile(
                context,
                'Ước tính đang chờ',
                Formatters.money(e.pipelineEstimatedPayout),
              ),
              const SizedBox(height: AppSpacing.md),
              _tile(context, 'Số đơn đã chốt', '${e.finalizedOrderCount}'),
              const SizedBox(height: AppSpacing.md),
              _tile(context, 'Số đơn pipeline', '${e.pipelineOrderCount}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
          ),
        ],
      ),
    );
  }
}
