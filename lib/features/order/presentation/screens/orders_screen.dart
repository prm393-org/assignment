import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.isSeller = false});

  final bool isSeller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(isSeller ? shopOrdersProvider : myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(isSeller ? 'Đơn bán' : 'Đơn hàng của tôi')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(isSeller ? shopOrdersProvider : myOrdersProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có đơn hàng',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final o = page.items[i];
            final path = isSeller
                ? '/farmer/orders/${o.id}'
                : '/consumer/orders/${o.id}';
            return ListTile(
              onTap: () => context.push(path),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(o.shopName ?? 'Đơn #${o.id.substring(0, 8)}'),
              subtitle: Text('${o.status} · ${Formatters.dateTime(o.createdAt)}'),
              trailing: Text(
                Formatters.money(o.totalAmount),
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
