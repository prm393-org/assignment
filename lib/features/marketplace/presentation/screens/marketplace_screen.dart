import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/repositories/marketplace_repository.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/widgets/market_cards.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/widgets/market_chrome.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/widgets/market_filter_sheet.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _debouncedSearch = '';
  String _minPriceText = '';
  String _maxPriceText = '';
  int _page = 1;
  String _sort = 'newest';
  bool _productsTab = true;

  static const _limit = 20;

  static const _sortOptions = <(String, String)>[
    ('newest', 'Mới nhất'),
    ('price_asc', 'Giá tăng'),
    ('price_desc', 'Giá giảm'),
  ];

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
    super.dispose();
  }

  void _scheduleDebounce() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _debouncedSearch = _search.text.trim();
        _page = 1;
      });
    });
  }

  double? _parsePrice(String s) {
    if (s.isEmpty) return null;
    final normalized =
        s.replaceAll(RegExp(r'\s'), '').replaceAll('.', '').replaceAll(',', '.');
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
      minPrice: _productsTab ? _parsePrice(_minPriceText) : null,
      maxPrice: _productsTab ? _parsePrice(_maxPriceText) : null,
    );
  }

  bool get _hasActivePriceFilter =>
      _minPriceText.isNotEmpty || _maxPriceText.isNotEmpty;

  int _activeFilterCount(String region) {
    var n = 0;
    if (region != 'Tất cả') n++;
    if (_productsTab && _sort != 'newest') n++;
    if (_productsTab && _hasActivePriceFilter) n++;
    return n;
  }

  Future<void> _openFilters(String region) async {
    final result = await showMarketFilterSheet(
      context,
      region: region,
      sort: _sort,
      minPrice: _minPriceText,
      maxPrice: _maxPriceText,
      sortOptions: _sortOptions,
      showSortAndPrice: _productsTab,
    );
    if (result == null || !mounted) return;
    await ref.read(marketplaceRegionProvider.notifier).setRegion(result.region);
    setState(() {
      _sort = result.sort;
      _minPriceText = result.minPrice;
      _maxPriceText = result.maxPrice;
      _page = 1;
    });
  }

  List<MarketActiveChip> _activeChips(String region) {
    final chips = <MarketActiveChip>[];
    if (region != 'Tất cả') {
      chips.add(
        MarketActiveChip(
          label: region,
          onRemove: () {
            ref.read(marketplaceRegionProvider.notifier).setRegion('Tất cả');
            setState(() => _page = 1);
          },
        ),
      );
    }
    if (_productsTab && _sort != 'newest') {
      final label = _sortOptions
          .where((o) => o.$1 == _sort)
          .map((o) => o.$2)
          .firstOrNull;
      if (label != null) {
        chips.add(
          MarketActiveChip(
            label: label,
            onRemove: () => setState(() {
              _sort = 'newest';
              _page = 1;
            }),
          ),
        );
      }
    }
    if (_productsTab && _hasActivePriceFilter) {
      chips.add(
        MarketActiveChip(
          label: 'Giá đã lọc',
          onRemove: () => setState(() {
            _minPriceText = '';
            _maxPriceText = '';
            _page = 1;
          }),
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final filter = _filter;
    final productsAsync = ref.watch(productsProvider(filter));
    final shopsAsync = ref.watch(shopsProvider(filter));
    final region = ref.watch(marketplaceRegionProvider);
    final cartCount = ref.watch(cartCountProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvasSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mua sắm',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            Text(
              'Chợ nông sản',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.ink,
                ),
                onPressed: () => context.push('/consumer/cart'),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                MarketSegmentControl(
                  productsSelected: _productsTab,
                  onChanged: (products) => setState(() {
                    _productsTab = products;
                    _page = 1;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: MarketSearchField(
                        controller: _search,
                        onChanged: (_) {
                          setState(() {});
                          _scheduleDebounce();
                        },
                        onClear: () {
                          _search.clear();
                          _scheduleDebounce();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MarketFilterButton(
                      activeCount: _activeFilterCount(region),
                      onPressed: () => _openFilters(region),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Builder(
            builder: (_) {
              final chips = _activeChips(region);
              if (chips.isEmpty) {
                return const Divider(height: 1, color: AppColors.hairline);
              }
              return Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  MarketActiveFilterChips(chips: chips),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(height: 1, color: AppColors.hairline),
                ],
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.forest,
              onRefresh: () async {
                ref.invalidate(productsProvider(filter));
                ref.invalidate(shopsProvider(filter));
                await Future<void>.delayed(const Duration(milliseconds: 250));
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
                        return CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.68,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) {
                                    final p = items[i];
                                    return MarketProductCard(
                                      product: p,
                                      onTap: () => context.push(
                                        '/consumer/product/${p.id}',
                                      ),
                                      onShopTap: p.shop == null
                                          ? null
                                          : () => context.push(
                                                '/consumer/shop/${p.shop!.id}',
                                              ),
                                    );
                                  },
                                  childCount: items.length,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: MarketPaginationBar(
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
                              ),
                            ),
                          ],
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
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: shops.length + 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) {
                            if (i == shops.length) {
                              return MarketPaginationBar(
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
                            return MarketShopCard(
                              shop: s,
                              onTap: () =>
                                  context.push('/consumer/shop/${s.id}'),
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
