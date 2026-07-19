import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';

class ConsumerHomeScreen extends ConsumerWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(highlightProductsProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào 👋',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Chuỗi Xanh Việt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          _roundAction(
            icon: Icons.qr_code_scanner_rounded,
            onTap: () => context.push('/consumer/trace/scan'),
          ),
          _roundAction(
            icon: Icons.notifications_none_rounded,
            onTap: () => context.push('/consumer/notifications'),
          ),
          Stack(
            children: [
              _roundAction(
                icon: Icons.shopping_bag_outlined,
                onTap: () => context.push('/consumer/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$cartCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () async => ref.invalidate(highlightProductsProvider),
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            SoftHeroBanner(
              title: 'Nông sản truy xuất\nnguồn gốc',
              subtitle:
                  'Mua trực tiếp từ nông hộ — minh bạch từ trang trại đến bàn ăn.',
              actionLabel: 'Khám phá chợ',
              onAction: () => context.go('/consumer/marketplace'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.storefront_rounded,
                    label: 'Chợ nông sản',
                    onTap: () => context.go('/consumer/marketplace'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Quét truy xuất',
                    color: AppColors.mintDeep,
                    onTap: () => context.push('/consumer/trace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Nổi bật hôm nay',
              actionLabel: 'Xem tất cả',
              onAction: () => context.go('/consumer/marketplace'),
            ),
            const SizedBox(height: AppSpacing.md),
            AsyncBody(
              value: products.asLike,
              onRetry: () => ref.invalidate(highlightProductsProvider),
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có sản phẩm nổi bật',
              builder: (list) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return ProductCard(
                    name: p.name,
                    price: p.price,
                    imageUrl: p.imageUrl,
                    subtitle: p.shop?.name,
                    onTap: () => context.push('/consumer/product/${p.id}'),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
        ),
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}
