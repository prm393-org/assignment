import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.isSeller = false});

  final bool isSeller;

  Future<void> _cancel(BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn chắc chắn muốn hủy đơn đang chờ xử lý?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(id);
      ref.invalidate(isSeller ? shopOrdersProvider : myOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Failure ? e.message : 'Không hủy được đơn'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    if (!isSeller && !auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mua hàng', style: Theme.of(context).textTheme.bodySmall),
              Text(
                'Đơn hàng của tôi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        body: EmptyState(
          message: 'Đăng nhập để xem đơn hàng của bạn',
          icon: Icons.receipt_long_outlined,
          actionLabel: 'Đăng nhập',
          onAction: () => context.push('/login'),
        ),
      );
    }

    final async = ref.watch(isSeller ? shopOrdersProvider : myOrdersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSeller ? 'Bán hàng' : 'Mua hàng',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              isSeller ? 'Đơn bán' : 'Đơn hàng của tôi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () =>
            ref.invalidate(isSeller ? shopOrdersProvider : myOrdersProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: isSeller
            ? 'Chưa có đơn bán nào'
            : 'Bạn chưa có đơn hàng — ghé chợ để mua nhé',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            if (i == 0) {
              return PageHeader(
                title: isSeller ? 'Theo dõi đơn bán' : 'Lịch sử mua hàng',
                subtitle: '${page.items.length} đơn gần đây',
                icon: isSeller
                    ? Icons.storefront_rounded
                    : Icons.receipt_long_rounded,
              );
            }
            final o = page.items[i - 1];
            final path = isSeller
                ? '/farmer/orders/${o.id}'
                : '/consumer/orders/${o.id}';
            final shortId = o.id.length > 8 ? o.id.substring(0, 8) : o.id;
            final canCancel =
                !isSeller && o.status.toLowerCase() == 'pending';
            return SurfaceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push(path),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: isSeller
                            ? Icons.local_shipping_outlined
                            : Icons.shopping_bag_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.shopName ?? 'Đơn #$shortId',
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              Formatters.dateTime(o.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusChip.order(o.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        o.paymentMethod.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.money(o.totalAmount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  if (canCancel) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _cancel(context, ref, o.id),
                        child: const Text(
                          'Hủy đơn',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
