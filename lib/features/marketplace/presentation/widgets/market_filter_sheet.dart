import 'package:flutter/material.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/widgets/market_chrome.dart';

/// Result of the Shopee-style filter bottom sheet.
class MarketFilterResult {
  const MarketFilterResult({
    required this.region,
    required this.sort,
    required this.minPrice,
    required this.maxPrice,
  });

  final String region;
  final String sort;
  final String minPrice;
  final String maxPrice;
}

/// Compact filter trigger (badge = số tiêu chí đang áp dụng).
class MarketFilterButton extends StatelessWidget {
  const MarketFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    return Material(
      color: active ? AppColors.mint : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: active ? AppColors.forest : AppColors.ink,
              ),
              if (active)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      activeCount > 9 ? '9+' : '$activeCount',
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
        ),
      ),
    );
  }
}

/// Active filters as removable chips above results (always visible when set).
class MarketActiveFilterChips extends StatelessWidget {
  const MarketActiveFilterChips({
    super.key,
    required this.chips,
    this.horizontalPadding = AppSpacing.lg,
  });

  final List<MarketActiveChip> chips;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final chip = chips[i];
          return Material(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: chip.onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chip.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.forest,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MarketActiveChip {
  const MarketActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;
}

Future<MarketFilterResult?> showMarketFilterSheet(
  BuildContext context, {
  required String region,
  required String sort,
  required String minPrice,
  required String maxPrice,
  required List<(String, String)> sortOptions,
  bool showSortAndPrice = true,
}) {
  return showModalBottomSheet<MarketFilterResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MarketFilterSheetBody(
      initialRegion: region,
      initialSort: sort,
      initialMinPrice: minPrice,
      initialMaxPrice: maxPrice,
      sortOptions: sortOptions,
      showSortAndPrice: showSortAndPrice,
    ),
  );
}

class _MarketFilterSheetBody extends StatefulWidget {
  const _MarketFilterSheetBody({
    required this.initialRegion,
    required this.initialSort,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.sortOptions,
    required this.showSortAndPrice,
  });

  final String initialRegion;
  final String initialSort;
  final String initialMinPrice;
  final String initialMaxPrice;
  final List<(String, String)> sortOptions;
  final bool showSortAndPrice;

  @override
  State<_MarketFilterSheetBody> createState() => _MarketFilterSheetBodyState();
}

class _MarketFilterSheetBodyState extends State<_MarketFilterSheetBody> {
  late String _region = widget.initialRegion;
  late String _sort = widget.initialSort;
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    _min = TextEditingController(text: widget.initialMinPrice);
    _max = TextEditingController(text: widget.initialMaxPrice);
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _region = 'Tất cả';
      _sort = 'newest';
      _min.clear();
      _max.clear();
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      MarketFilterResult(
        region: _region,
        sort: _sort,
        minPrice: _min.text.trim(),
        maxPrice: _max.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Bộ lọc',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Đặt lại'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Khu vực',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final r in marketplaceRegions)
                          MarketPillChip(
                            label: r,
                            selected: _region == r,
                            onTap: () => setState(() => _region = r),
                          ),
                      ],
                    ),
                    if (widget.showSortAndPrice) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Sắp xếp',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final opt in widget.sortOptions)
                            MarketPillChip(
                              label: opt.$2,
                              selected: _sort == opt.$1,
                              onTap: () => setState(() => _sort = opt.$1),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Khoảng giá (₫)',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _min,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Từ',
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              '—',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _max,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Đến',
                                filled: true,
                                fillColor: AppColors.surfaceElevated,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.hairline),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Xem kết quả'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
