import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/review/presentation/providers/review_providers.dart';

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shop = ref.watch(shopDetailProvider(shopId));
    final products = ref.watch(shopProductsProvider(shopId));
    final reviews = ref.watch(shopReviewsProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: const Text('Gian hàng')),
      body: AsyncBody(
        value: shop.asLike,
        onRetry: () => ref.invalidate(shopDetailProvider(shopId)),
        builder: (s) => ListView(
          padding: AppSpacing.screen,
          children: [
            Text(s.name, style: Theme.of(context).textTheme.headlineMedium),
            if (s.isVerified)
              const Chip(
                label: Text('Đã xác minh'),
                avatar: Icon(Icons.verified, color: AppColors.success, size: 18),
              ),
            if (s.description != null) Text(s.description!),
            Text('${s.farmName ?? ''} · ${s.province ?? ''}'),
            if (s.averageRating != null)
              Text('★ ${s.averageRating!.toStringAsFixed(1)} (${s.reviewCount})'),
            const SizedBox(height: AppSpacing.xl),
            Text('Sản phẩm', style: Theme.of(context).textTheme.titleLarge),
            AsyncBody(
              value: products.asLike,
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Chưa có sản phẩm',
              builder: (page) => Column(
                children: [
                  for (final p in page.items)
                    ListTile(
                      title: Text(p.name),
                      trailing: Text(Formatters.money(p.price)),
                      onTap: () => context.push('/consumer/product/${p.id}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Đánh giá', style: Theme.of(context).textTheme.titleLarge),
            AsyncBody(
              value: reviews.asLike,
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Chưa có đánh giá',
              builder: (page) => Column(
                children: [
                  for (final r in page.items.take(10))
                    ListTile(
                      title: Text(r.reviewerName ?? 'Người mua'),
                      subtitle: Text(r.comment ?? ''),
                      trailing: Text('★ ${r.rating}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
