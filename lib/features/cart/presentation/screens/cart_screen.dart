import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final groups = groupCartByShop(items);
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mua sắm', style: Theme.of(context).textTheme.bodySmall),
            Text('Giỏ hàng', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: items.isEmpty
          ? EmptyState(
              message: 'Giỏ hàng trống',
              icon: Icons.shopping_bag_outlined,
              actionLabel: 'Đi chợ ngay',
              onAction: () => context.go('/consumer/marketplace'),
            )
          : ListView(
              padding: AppSpacing.screen,
              children: [
                PageHeader(
                  title: '${items.length} sản phẩm',
                  subtitle: '${groups.length} gian hàng',
                  icon: Icons.shopping_bag_outlined,
                ),
                for (final g in groups) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const IconBadge(
                              icon: Icons.storefront_rounded,
                              size: 40,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                g.shopName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        for (final item in g.items) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style:
                                          Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      Formatters.money(item.price),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.forest),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(item.productId, -1),
                                      icon: const Icon(
                                        Icons.remove_rounded,
                                        size: 18,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(item.productId, 1),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .removeItem(item.productId),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          if (item != g.items.last)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: AppSpacing.screen,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.hairline)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tạm tính',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          Formatters.money(subtotal),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.forest,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => context.push('/consumer/checkout'),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Thanh toán'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
