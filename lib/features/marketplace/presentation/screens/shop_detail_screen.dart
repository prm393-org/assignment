import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/review/presentation/providers/review_providers.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  bool _openingChat = false;
  int _productPage = 1;

  Future<void> _messageFarmer(String? ownerUserId) async {
    if (ownerUserId == null || ownerUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy nông dân của gian hàng này'),
        ),
      );
      return;
    }
    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để chat với nông dân')),
      );
      context.push('/login');
      return;
    }
    setState(() => _openingChat = true);
    try {
      final conversation = await ref
          .read(chatRepositoryProvider)
          .openConversation(ownerUserId);
      if (!mounted) return;
      context.push('/consumer/chat/${conversation.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Failure ? e.message : 'Không mở được cuộc trò chuyện',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _openFarmMap({
    double? lat,
    double? lng,
    String? query,
  }) async {
    final Uri uri;
    if (lat != null && lng != null && lat.isFinite && lng.isFinite) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (query != null && query.isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có vị trí trang trại')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được bản đồ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopDetailProvider(widget.shopId));
    final products = ref.watch(
      shopProductsProvider((shopId: widget.shopId, page: _productPage)),
    );
    final reviews = ref.watch(shopReviewsProvider(widget.shopId));

    return Scaffold(
      appBar: AppBar(title: const Text('Gian hàng')),
      body: AsyncBody(
        value: shop.asLike,
        onRetry: () => ref.invalidate(shopDetailProvider(widget.shopId)),
        builder: (s) {
          final farm = s.farm;
          final region = [
            if (s.district != null && s.district!.isNotEmpty) s.district,
            if (s.province != null && s.province!.isNotEmpty) s.province,
          ].whereType<String>().join(', ');
          final mapQuery = farm?.mapQuery ??
              ([
                farm?.address,
                farm?.ward,
                s.district,
                s.province,
              ].whereType<String>().where((e) => e.isNotEmpty).join(', '));

          return ListView(
            padding: AppSpacing.screen,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.avatarUrl != null && s.avatarUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppNetworkImage(
                        url: s.avatarUrl,
                        width: 72,
                        height: 72,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )
                  else
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: AppColors.forest,
                        size: 32,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (s.isVerified) ...[
                          const SizedBox(height: 6),
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(
                              Icons.verified,
                              color: AppColors.success,
                              size: 16,
                            ),
                            label: Text('Đã xác minh'),
                          ),
                        ],
                        if (s.averageRating != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '★ ${s.averageRating!.toStringAsFixed(1)} (${s.reviewCount})',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (s.updatedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Hoạt động ${Formatters.activityAgo(s.updatedAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (s.description != null && s.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(s.description!),
              ],
              if (region.isNotEmpty || (s.farmName?.isNotEmpty ?? false)) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  [
                    if (s.farmName != null && s.farmName!.isNotEmpty)
                      s.farmName,
                    if (region.isNotEmpty) region,
                  ].whereType<String>().join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (s.certifications.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in s.certifications)
                      Chip(
                        label: Text(c),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: (_openingChat ||
                            (s.ownerUserId == null || s.ownerUserId!.isEmpty))
                        ? null
                        : () => _messageFarmer(s.ownerUserId),
                    icon: _openingChat
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_outlined),
                    label: Text(_openingChat ? 'Đang mở...' : 'Nhắn nông dân'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/consumer/trace'),
                    icon: const Icon(Icons.qr_code_2_outlined),
                    label: const Text('Truy xuất'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openFarmMap(
                      lat: farm?.latitude,
                      lng: farm?.longitude,
                      query: mapQuery.isEmpty ? region : mapQuery,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Bản đồ'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Sản phẩm${products.asData != null ? ' (${products.asData!.value.total})' : ''}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              AsyncBody(
                value: products.asLike,
                isEmpty: (page) => page.items.isEmpty,
                emptyMessage: 'Chưa có sản phẩm',
                builder: (page) => Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: page.items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (_, i) {
                        final p = page.items[i];
                        return ProductCard(
                          name: p.name,
                          price: p.price,
                          imageUrl: p.imageUrl,
                          rating: p.averageRating,
                          reviewCount: p.reviewCount,
                          outOfStock:
                              p.stockQty != null && p.stockQty! <= 0,
                          onTap: () =>
                              context.push('/consumer/product/${p.id}'),
                        );
                      },
                    ),
                    if (page.pages > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _productPage <= 1
                                ? null
                                : () => setState(() => _productPage--),
                            child: const Text('← Trước'),
                          ),
                          Text('$_productPage / ${page.pages}'),
                          TextButton(
                            onPressed: _productPage >= page.pages
                                ? null
                                : () => setState(() => _productPage++),
                            child: const Text('Sau →'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Đánh giá', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AsyncBody(
                value: reviews.asLike,
                isEmpty: (page) => page.items.isEmpty,
                emptyMessage: 'Chưa có đánh giá',
                builder: (page) => Column(
                  children: [
                    for (final r in page.items.take(10))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(r.reviewerName ?? 'Người mua'),
                        subtitle: Text(
                          [
                            if (r.productName != null &&
                                r.productName!.isNotEmpty)
                              r.productName!,
                            if (r.comment != null && r.comment!.isNotEmpty)
                              r.comment!,
                          ].join('\n'),
                        ),
                        isThreeLine: r.productName != null &&
                            r.comment != null &&
                            r.comment!.isNotEmpty,
                        trailing: Text(
                          '★ ${r.rating}',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
