# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


w('features/marketplace/presentation/screens/consumer_home_screen.dart', r'''
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

class ConsumerHomeScreen extends ConsumerWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(highlightProductsProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuỗi Xanh Việt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/consumer/trace/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/consumer/notifications'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/consumer/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: AppColors.lime,
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(fontSize: 10, color: AppColors.ink),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(highlightProductsProvider),
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.forest, AppColors.darkGreen],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nông sản truy xuất nguồn gốc',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Mua trực tiếp từ nông hộ, minh bạch từ trang trại đến bàn ăn.',
                    style: TextStyle(color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: () => context.go('/consumer/marketplace'),
                    child: const Text('Khám phá chợ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nổi bật', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.go('/consumer/marketplace'),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AsyncBody(
              value: products.asLike,
              onRetry: () => ref.invalidate(highlightProductsProvider),
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có sản phẩm',
              builder: (list) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return InkWell(
                    onTap: () => context.push('/consumer/product/${p.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AppNetworkImage(
                              url: p.imageUrl,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.money(p.price),
                                  style: const TextStyle(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''')

w('features/marketplace/presentation/screens/marketplace_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productsProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Chợ nông sản')),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              onSubmitted: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: AsyncBody(
              value: async.asLike,
              onRetry: () => ref.invalidate(productsProvider(_query)),
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Không tìm thấy sản phẩm',
              builder: (page) => ListView.separated(
                padding: AppSpacing.screen,
                itemCount: page.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  final p = page.items[i];
                  return ListTile(
                    onTap: () => context.push('/consumer/product/${p.id}'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.hairline),
                    ),
                    tileColor: AppColors.surface,
                    leading: AppNetworkImage(
                      url: p.imageUrl,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(p.name),
                    subtitle: Text(p.shop?.name ?? 'Gian hàng'),
                    trailing: Text(
                      Formatters.money(p.price),
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
''')

w('features/marketplace/presentation/screens/product_detail_screen.dart', r'''
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
''')

w('features/marketplace/presentation/screens/shop_detail_screen.dart', r'''
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
''')

print('marketplace screens done')
