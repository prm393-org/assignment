import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
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
        builder: (e) => ListView(
          padding: AppSpacing.screen,
          children: [
            _card('Đã thanh toán cho bạn', Formatters.money(e.finalizedSellerPayout)),
            _card('GMV đã chốt', Formatters.money(e.totalGmvFinalized)),
            _card('Hoa hồng nền tảng', Formatters.money(e.totalPlatformCommissionFinalized)),
            _card('Ước tính đang chờ', Formatters.money(e.pipelineEstimatedPayout)),
            _card('Số đơn đã chốt', '${e.finalizedOrderCount}'),
            _card('Số đơn pipeline', '${e.pipelineOrderCount}'),
          ],
        ),
      ),
    );
  }

  Widget _card(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
      ),
    );
  }
}
