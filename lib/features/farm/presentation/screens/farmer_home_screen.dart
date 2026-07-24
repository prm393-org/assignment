import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/consumer_header_actions.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class FarmerHomeScreen extends ConsumerWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(myFarmsProvider);
    final earnings = ref.watch(shopEarningsProvider);
    return Scaffold(
      appBar: const FarmerTabAppBar(
        subtitle: 'Bảng điều khiển',
        title: 'Nông hộ',
      ),
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () async {
          ref.invalidate(myFarmsProvider);
          ref.invalidate(shopEarningsProvider);
          await Future.wait([
            ref.read(myFarmsProvider.future),
            ref.read(shopEarningsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screen,
          children: [
            SoftHeroBanner(
              title: 'Quản lý trang trại\nthông minh',
              subtitle: 'Theo dõi doanh thu, nhật ký và truy xuất nguồn gốc.',
              actionLabel: 'Mở gian hàng',
              onAction: () => context.go('/farmer/shop'),
              icon: Icons.agriculture_rounded,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Doanh thu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AsyncBody(
              value: earnings.asLike,
              onRetry: () => ref.invalidate(shopEarningsProvider),
              builder: (e) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.45,
                children: [
                  StatPill(
                    label: 'Đã nhận',
                    value: Formatters.money(e.finalizedSellerPayout),
                  ),
                  StatPill(
                    label: 'Ước tính',
                    value: Formatters.money(e.pipelineEstimatedPayout),
                  ),
                  StatPill(label: 'Đơn xong', value: '${e.finalizedOrderCount}'),
                  StatPill(
                    label: 'Đang xử lý',
                    value: '${e.pipelineOrderCount}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Lối tắt', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.35,
              children: [
                QuickActionCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Đơn bán',
                  onTap: () => context.push('/farmer/orders'),
                ),
                QuickActionCard(
                  icon: Icons.payments_outlined,
                  label: 'Doanh thu',
                  color: AppColors.mintDeep,
                  onTap: () => context.push('/farmer/earnings'),
                ),
                QuickActionCard(
                  icon: Icons.smart_toy_outlined,
                  label: 'Trợ lý AI',
                  onTap: () => context.push('/farmer/ai'),
                ),
                QuickActionCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Xu hướng',
                  color: AppColors.mintDeep,
                  onTap: () => context.push('/farmer/agri-trend'),
                ),
                QuickActionCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Nhật ký',
                  onTap: () => context.push('/farmer/diary'),
                ),
                QuickActionCard(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Truy xuất',
                  color: AppColors.mintDeep,
                  onTap: () => context.push('/farmer/trace'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Nông trại của tôi',
              actionLabel: 'Tất cả',
              onAction: () => context.go('/farmer/farms'),
            ),
            const SizedBox(height: AppSpacing.md),
            AsyncBody(
              value: farms.asLike,
              onRetry: () => ref.invalidate(myFarmsProvider),
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có nông trại — tạo mới để bắt đầu',
              emptyActionLabel: 'Tạo nông trại',
              onEmptyAction: () => context.push('/farmer/farms/create'),
              emptyIcon: Icons.agriculture_outlined,
              builder: (list) => Column(
                children: [
                  for (final f in list.take(3)) ...[
                    SurfaceCard(
                      onTap: () => context.push('/farmer/farms/${f.id}'),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.agriculture_rounded,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${f.areaHa} ha · ${f.cropMain}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
