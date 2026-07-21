import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/providers/notification_providers.dart';

class ConsumerHomeScreen extends ConsumerStatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  ConsumerState<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends ConsumerState<ConsumerHomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(highlightProductsProvider);
    final shops = ref.watch(highlightShopsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final region = ref.watch(marketplaceRegionProvider);
    final unreadNotif = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.canvasSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            Text(
              'Chuỗi Xanh Việt',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        actions: [
          _roundAction(
            icon: Icons.qr_code_scanner_rounded,
            onTap: () => context.push('/consumer/trace/scan'),
          ),
          Stack(
            children: [
              _roundAction(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/consumer/notifications'),
              ),
              if (unreadNotif > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      unreadNotif > 99 ? '99+' : '$unreadNotif',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
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
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
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
        onRefresh: () async {
          ref.invalidate(highlightProductsProvider);
          ref.invalidate(highlightShopsProvider);
        },
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
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm, gian hàng...',
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.muted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.mintDeep),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                final q = v.trim();
                if (q.isEmpty) {
                  context.go('/consumer/marketplace');
                } else {
                  context.push(
                    '/consumer/marketplace?q=${Uri.encodeComponent(q)}',
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: marketplaceRegions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final r = marketplaceRegions[i];
                  final selected = region == r;
                  return FilterChip(
                    label: Text(r),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.forest,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.onPrimary : AppColors.body,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.forest : AppColors.hairline,
                    ),
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => ref
                        .read(marketplaceRegionProvider.notifier)
                        .setRegion(r),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                _TrustChip(icon: Icons.verified, label: 'Xác minh'),
                const SizedBox(width: 8),
                _TrustChip(icon: Icons.eco_outlined, label: 'VietGAP'),
                const SizedBox(width: 8),
                _TrustChip(icon: Icons.qr_code_2, label: 'QR truy xuất'),
              ],
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
              title: 'Gian hàng nổi bật',
              actionLabel: 'Xem tất cả',
              onAction: () => context.go('/consumer/marketplace'),
            ),
            const SizedBox(height: AppSpacing.md),
            AsyncBody(
              value: shops.asLike,
              onRetry: () => ref.invalidate(highlightShopsProvider),
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có gian hàng nổi bật',
              builder: (list) => SizedBox(
                height: 156,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return SizedBox(
                      width: 200,
                      child: Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => context.push('/consumer/shop/${s.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: AppNetworkImage(
                                        url: s.avatarUrl,
                                        width: 44,
                                        height: 44,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (s.isVerified)
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                if (s.averageRating != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${s.averageRating!.toStringAsFixed(1)} (${s.reviewCount})',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                if (s.province != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (s.district != null) s.district,
                                      s.province,
                                    ].whereType<String>().join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.muted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
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
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (_, i) {
                  final p = list[i];
                  final regionLine = [
                    p.shop?.farm?.district,
                    p.shop?.province,
                  ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
                  return ProductCard(
                    name: p.name,
                    price: p.price,
                    imageUrl: p.imageUrl,
                    subtitle: regionLine.isNotEmpty
                        ? regionLine
                        : p.shop?.name,
                    rating: p.averageRating,
                    reviewCount: p.reviewCount,
                    isVerified: p.shop?.isVerified == true,
                    outOfStock: p.stockQty != null && p.stockQty! <= 0,
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
          backgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.ink,
        ),
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.forest),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
