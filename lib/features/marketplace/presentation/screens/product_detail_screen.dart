import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/review/presentation/providers/review_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));
    final reviews = ref.watch(productReviewsProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(productDetailProvider(productId)),
        builder: (p) => ListView(
          padding: AppSpacing.screen,
          children: [
            AppNetworkImage(
              url: p.imageUrl,
              height: 220,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${Formatters.money(p.price)}${p.unit != null ? ' / ${p.unit}' : ''}',
              style: const TextStyle(
                color: AppColors.forest,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (p.shop != null) ...[
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront, color: AppColors.forest),
                title: Text(p.shop!.name),
                subtitle: Text(p.shop!.province ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/consumer/shop/${p.shopId}'),
              ),
            ],
            if (p.description != null && p.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Mô tả', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(p.description!),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Đánh giá', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AsyncBody(
              value: reviews.asLike,
              emptyMessage: 'Chưa có đánh giá',
              isEmpty: (page) => page.items.isEmpty,
              builder: (page) => Column(
                children: [
                  for (final r in page.items.take(5))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.reviewerName ?? 'Người mua'),
                      subtitle: Text(r.comment ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppColors.warning, size: 16),
                          Text('${r.rating}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (p) => SafeArea(
          child: Padding(
            padding: AppSpacing.screen,
            child: FilledButton.icon(
              onPressed: () async {
                await ref.read(cartProvider.notifier).addItem(
                      CartItem(
                        productId: p.id,
                        productName: p.name,
                        price: p.price,
                        unit: p.unit ?? 'kg',
                        quantity: 1,
                        shopId: p.shopId,
                        shopName: p.shop?.name ?? 'Gian hàng',
                        stockQty: p.stockQty,
                        imageUrl: p.imageUrl,
                      ),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm vào giỏ')),
                  );
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Thêm vào giỏ'),
            ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
