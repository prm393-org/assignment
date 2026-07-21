import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _search = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  Timer? _debounce;
  String _debouncedSearch = '';
  String _debouncedMin = '';
  String _debouncedMax = '';
  int _page = 1;
  String _sort = 'newest';
  bool _productsTab = true;

  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery?.trim();
    if (q != null && q.isNotEmpty) {
      _search.text = q;
      _debouncedSearch = q;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  void _scheduleDebounce() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _debouncedSearch = _search.text.trim();
        _debouncedMin = _minPrice.text.trim();
        _debouncedMax = _maxPrice.text.trim();
        _page = 1;
      });
    });
  }

  double? _parsePrice(String s) {
    if (s.isEmpty) return null;
    final normalized = s.replaceAll(RegExp(r'\s'), '').replaceAll('.', '').replaceAll(',', '.');
    final n = double.tryParse(normalized);
    return (n != null && n >= 0) ? n : null;
  }

  MarketplaceFilter get _filter {
    final region = ref.watch(marketplaceRegionProvider);
    return MarketplaceFilter(
      page: _page,
      limit: _limit,
      searchTerm: _debouncedSearch.isEmpty ? null : _debouncedSearch,
      province: region == 'Tất cả' ? null : region,
      sort: _productsTab ? _sort : null,
      minPrice: _productsTab ? _parsePrice(_debouncedMin) : null,
      maxPrice: _productsTab ? _parsePrice(_debouncedMax) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = _filter;
    final productsAsync = ref.watch(productsProvider(filter));
    final shopsAsync = ref.watch(shopsProvider(filter));
    final region = ref.watch(marketplaceRegionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chợ nông sản'),
        actions: [
          IconButton.filledTonal(
            onPressed: () => context.push('/consumer/cart'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: 8, top: 4),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _SegmentChip(
                        label: 'Sản phẩm',
                        selected: _productsTab,
                        onTap: () => setState(() {
                          _productsTab = true;
                          _page = 1;
                        }),
                      ),
                      _SegmentChip(
                        label: 'Gian hàng',
                        selected: !_productsTab,
                        onTap: () => setState(() {
                          _productsTab = false;
                          _page = 1;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Tìm chuối, xoài, gian hàng...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              _scheduleDebounce();
                              setState(() {});
                            },
                          ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _scheduleDebounce();
                  },
                  textInputAction: TextInputAction.search,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: marketplaceRegions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final r = marketplaceRegions[i];
                      final selected = region == r;
                      return ChoiceChip(
                        label: Text(r),
                        selected: selected,
                        onSelected: (_) {
                          ref
                              .read(marketplaceRegionProvider.notifier)
                              .setRegion(r);
                          setState(() => _page = 1);
                        },
                      );
                    },
                  ),
                ),
                if (_productsTab) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final opt in const [
                        ('newest', 'Mới nhất'),
                        ('price_asc', 'Giá tăng'),
                        ('price_desc', 'Giá giảm'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(opt.$2),
                            selected: _sort == opt.$1,
                            onSelected: (_) => setState(() {
                              _sort = opt.$1;
                              _page = 1;
                            }),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPrice,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Giá từ',
                            isDense: true,
                          ),
                          onChanged: (_) => _scheduleDebounce(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _maxPrice,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Giá đến',
                            isDense: true,
                          ),
                          onChanged: (_) => _scheduleDebounce(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.forest,
              onRefresh: () async {
                ref.invalidate(productsProvider(filter));
                ref.invalidate(shopsProvider(filter));
              },
              child: _productsTab
                  ? AsyncBody<PaginatedResult<Product>>(
                      value: productsAsync.asLike,
                      onRetry: () =>
                          ref.invalidate(productsProvider(filter)),
                      isEmpty: (page) => page.items.isEmpty,
                      emptyMessage: 'Không tìm thấy sản phẩm phù hợp',
                      builder: (meta) {
                        final items = meta.items;
                        return ListView.separated(
                          padding: AppSpacing.screen,
                          itemCount: items.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) {
                            if (i == items.length) {
                              return _PaginationBar(
                                page: meta.page,
                                totalPages: meta.pages,
                                onPrev: () => setState(
                                  () =>
                                      _page = (_page - 1).clamp(1, meta.pages),
                                ),
                                onNext: () => setState(
                                  () =>
                                      _page = (_page + 1).clamp(1, meta.pages),
                                ),
                              );
                            }
                            final p = items[i];
                            return SurfaceCard(
                              padding: const EdgeInsets.all(12),
                              onTap: () =>
                                  context.push('/consumer/product/${p.id}'),
                              child: Row(
                                children: [
                                  AppNetworkImage(
                                    url: p.imageUrl,
                                    width: 84,
                                    height: 84,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        if (p.shop != null)
                                          InkWell(
                                            onTap: () => context.push(
                                              '/consumer/shop/${p.shop!.id}',
                                            ),
                                            child: Text(
                                              '${p.shop!.name} →',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.forest,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        if (p.averageRating != null &&
                                            p.reviewCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '★ ${p.averageRating!.toStringAsFixed(1)} (${p.reviewCount})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.warning,
                                                ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          Formatters.money(p.price),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.forest,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )
                  : AsyncBody<PaginatedResult<ShopSummary>>(
                      value: shopsAsync.asLike,
                      onRetry: () => ref.invalidate(shopsProvider(filter)),
                      isEmpty: (page) => page.items.isEmpty,
                      emptyMessage: 'Không tìm thấy gian hàng',
                      builder: (meta) {
                        final shops = meta.items;
                        return ListView.separated(
                          padding: AppSpacing.screen,
                          itemCount: shops.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) {
                            if (i == shops.length) {
                              return _PaginationBar(
                                page: meta.page,
                                totalPages: meta.pages,
                                onPrev: () => setState(
                                  () =>
                                      _page = (_page - 1).clamp(1, meta.pages),
                                ),
                                onNext: () => setState(
                                  () =>
                                      _page = (_page + 1).clamp(1, meta.pages),
                                ),
                              );
                            }
                            final s = shops[i];
                            return SurfaceCard(
                              padding: const EdgeInsets.all(14),
                              onTap: () =>
                                  context.push('/consumer/shop/${s.id}'),
                              child: Row(
                                children: [
                                  AppNetworkImage(
                                    url: s.avatarUrl,
                                    width: 64,
                                    height: 64,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                s.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ),
                                            if (s.isVerified)
                                              const Icon(
                                                Icons.verified,
                                                size: 18,
                                                color: AppColors.success,
                                              ),
                                          ],
                                        ),
                                        if (s.averageRating != null)
                                          Text(
                                            '★ ${s.averageRating!.toStringAsFixed(1)} (${s.reviewCount})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.warning,
                                                ),
                                          ),
                                        if (s.description != null)
                                          Text(
                                            s.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (s.province != null)
                                          Text(
                                            [
                                              if (s.district != null)
                                                s.district,
                                              s.province,
                                            ].whereType<String>().join(', '),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            );
                          },
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

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.forest : AppColors.body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: page <= 1 ? null : onPrev,
            child: const Text('← Trước'),
          ),
          Text(
            '$page / $totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: page >= totalPages ? null : onNext,
            child: const Text('Sau →'),
          ),
        ],
      ),
    );
  }
}
