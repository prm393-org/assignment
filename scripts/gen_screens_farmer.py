# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


w('features/farm/presentation/screens/farmer_home_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class FarmerHomeScreen extends ConsumerWidget {
  const FarmerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(myFarmsProvider);
    final earnings = ref.watch(shopEarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nông hộ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/farmer/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Text('Bảng điều khiển', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          AsyncBody(
            value: earnings.asLike,
            onRetry: () => ref.invalidate(shopEarningsProvider),
            builder: (e) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _stat(context, 'Đã nhận', Formatters.money(e.finalizedSellerPayout)),
                _stat(context, 'Ước tính', Formatters.money(e.pipelineEstimatedPayout)),
                _stat(context, 'Đơn xong', '${e.finalizedOrderCount}'),
                _stat(context, 'Đang xử lý', '${e.pipelineOrderCount}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/farmer/orders'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Đơn bán'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/farmer/earnings'),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Doanh thu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/farmer/ai'),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Trợ lý AI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/farmer/agri-trend'),
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Xu hướng'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Nông trại của tôi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          AsyncBody(
            value: farms.asLike,
            onRetry: () => ref.invalidate(myFarmsProvider),
            isEmpty: (list) => list.isEmpty,
            emptyMessage: 'Chưa có nông trại',
            builder: (list) => Column(
              children: [
                for (final f in list.take(3))
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.hairline),
                    ),
                    title: Text(f.name),
                    subtitle: Text('${f.cropMain} · ${f.locationLabel}'),
                    onTap: () => context.push('/farmer/farms/${f.id}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forest)),
        ],
      ),
    );
  }
}
''')

w('features/farm/presentation/screens/farms_list_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

class FarmsListScreen extends ConsumerWidget {
  const FarmsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFarmsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nông trại')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/farmer/farms/create'),
        child: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(myFarmsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có nông trại. Tạo mới để bắt đầu.',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final f = list[i];
            return ListTile(
              onTap: () => context.push('/farmer/farms/${f.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(f.name),
              subtitle: Text('${f.areaHa} ha · ${f.cropMain}\n${f.locationLabel}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
            );
          },
        ),
      ),
    );
  }
}
''')

w('features/farm/presentation/screens/farm_form_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

class FarmFormScreen extends ConsumerStatefulWidget {
  const FarmFormScreen({super.key, this.farm});
  final Farm? farm;

  @override
  ConsumerState<FarmFormScreen> createState() => _FarmFormScreenState();
}

class _FarmFormScreenState extends ConsumerState<FarmFormScreen> {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _crop = TextEditingController();
  final _province = TextEditingController();
  final _district = TextEditingController();
  final _ward = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController(text: '10.76');
  final _lng = TextEditingController(text: '106.66');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final f = widget.farm;
    if (f != null) {
      _name.text = f.name;
      _area.text = '${f.areaHa}';
      _crop.text = f.cropMain;
      _province.text = f.province;
      _district.text = f.district;
      _ward.text = f.ward;
      _address.text = f.address ?? '';
      _lat.text = '${f.latitude ?? 10.76}';
      _lng.text = '${f.longitude ?? 106.66}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _crop.dispose();
    _province.dispose();
    _district.dispose();
    _ward.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final body = {
      'name': _name.text.trim(),
      'area_ha': double.tryParse(_area.text) ?? 0,
      'crop_main': _crop.text.trim(),
      'in_cooperative': false,
      'province': _province.text.trim(),
      'district': _district.text.trim(),
      'ward': _ward.text.trim(),
      'province_code': 79,
      'district_code': 760,
      'ward_code': 26734,
      'address': _address.text.trim(),
      'latitude': double.tryParse(_lat.text) ?? 0,
      'longitude': double.tryParse(_lng.text) ?? 0,
    };
    try {
      final repo = ref.read(farmRepositoryProvider);
      if (widget.farm == null) {
        await repo.createFarm(body);
      } else {
        await repo.updateFarm(widget.farm!.id, body);
      }
      ref.invalidate(myFarmsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.farm == null ? 'Tạo nông trại' : 'Sửa nông trại')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Tên nông trại')),
          const SizedBox(height: 12),
          TextField(controller: _area, decoration: const InputDecoration(labelText: 'Diện tích (ha)'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: _crop, decoration: const InputDecoration(labelText: 'Cây trồng chính')),
          const SizedBox(height: 12),
          TextField(controller: _province, decoration: const InputDecoration(labelText: 'Tỉnh/TP')),
          const SizedBox(height: 12),
          TextField(controller: _district, decoration: const InputDecoration(labelText: 'Quận/Huyện')),
          const SizedBox(height: 12),
          TextField(controller: _ward, decoration: const InputDecoration(labelText: 'Phường/Xã')),
          const SizedBox(height: 12),
          TextField(controller: _address, decoration: const InputDecoration(labelText: 'Địa chỉ')),
          const SizedBox(height: 12),
          TextField(controller: _lat, decoration: const InputDecoration(labelText: 'Vĩ độ')),
          const SizedBox(height: 12),
          TextField(controller: _lng, decoration: const InputDecoration(labelText: 'Kinh độ')),
          const SizedBox(height: 24),
          FilledButton(onPressed: _loading ? null : _save, child: const Text('Lưu')),
        ],
      ),
    );
  }
}
''')

w('features/farm/presentation/screens/farm_detail_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

class FarmDetailScreen extends ConsumerWidget {
  const FarmDetailScreen({super.key, required this.farmId});
  final String farmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(myFarmsProvider);
    final seasons = ref.watch(farmSeasonsProvider(farmId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nông trại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final farm = farms.valueOrNull?.where((f) => f.id == farmId).firstOrNull;
              if (farm != null) {
                context.push('/farmer/farms/$farmId/edit');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createSeason(context, ref),
        label: const Text('Thêm mùa vụ'),
        icon: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: farms.asLike,
        onRetry: () => ref.invalidate(myFarmsProvider),
        builder: (list) {
          final farm = list.where((f) => f.id == farmId).firstOrNull;
          if (farm == null) {
            return const EmptyState(message: 'Không tìm thấy nông trại');
          }
          return ListView(
            padding: AppSpacing.screen,
            children: [
              Text(farm.name, style: Theme.of(context).textTheme.headlineMedium),
              Text('${farm.areaHa} ha · ${farm.cropMain}'),
              Text(farm.locationLabel),
              const SizedBox(height: AppSpacing.xl),
              Text('Mùa vụ', style: Theme.of(context).textTheme.titleLarge),
              AsyncBody(
                value: seasons.asLike,
                onRetry: () => ref.invalidate(farmSeasonsProvider(farmId)),
                isEmpty: (s) => s.isEmpty,
                emptyMessage: 'Chưa có mùa vụ',
                builder: (sList) => Column(
                  children: [
                    for (final s in sList)
                      ListTile(
                        title: Text('${s.code} · ${s.cropName}'),
                        subtitle: Text('${s.status} · ${Formatters.date(s.startDate)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/farmer/seasons/${s.id}'),
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

  Future<void> _createSeason(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final crop = TextEditingController(text: 'Chuối');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo mùa vụ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Mã mùa vụ')),
            TextField(controller: crop, decoration: const InputDecoration(labelText: 'Cây trồng')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(farmRepositoryProvider).createSeason({
        'farmId': farmId,
        'code': code.text.trim(),
        'cropName': crop.text.trim(),
        'startDate': DateTime.now().toIso8601String().substring(0, 10),
        'status': 'planning',
      });
      ref.invalidate(farmSeasonsProvider(farmId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e', style: const TextStyle(color: AppColors.onPrimary))),
      );
    }
  }
}
''')

w('features/farm/presentation/screens/season_detail_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';

class SeasonDetailScreen extends ConsumerWidget {
  const SeasonDetailScreen({super.key, required this.seasonId});
  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(seasonDetailProvider(seasonId));
    final diaries = ref.watch(seasonDiariesProvider(seasonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mùa vụ')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDiary(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AsyncBody(
        value: season.asLike,
        onRetry: () => ref.invalidate(seasonDetailProvider(seasonId)),
        builder: (s) => ListView(
          padding: AppSpacing.screen,
          children: [
            Text('${s.code} · ${s.cropName}', style: Theme.of(context).textTheme.headlineMedium),
            Text('Trạng thái: ${s.status}'),
            Text('Bắt đầu: ${Formatters.date(s.startDate)}'),
            const SizedBox(height: AppSpacing.xl),
            Text('Nhật ký canh tác', style: Theme.of(context).textTheme.titleLarge),
            AsyncBody(
              value: diaries.asLike,
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Chưa có nhật ký',
              builder: (page) => Column(
                children: [
                  for (final d in page.items)
                    ListTile(
                      title: Text(diaryEventLabels[d.eventType] ?? d.eventType),
                      subtitle: Text(d.description ?? ''),
                      trailing: Text(Formatters.date(d.eventDate)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDiary(BuildContext context, WidgetRef ref) async {
    final season = await ref.read(seasonDetailProvider(seasonId).future);
    String eventType = 'sowing';
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Thêm nhật ký'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: eventType,
                items: [
                  for (final e in diaryEventLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setLocal(() => eventType = v ?? 'other'),
              ),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(farmRepositoryProvider).createDiary({
        'seasonId': seasonId,
        'farmId': season.farmId,
        'eventType': eventType,
        'eventDate': DateTime.now().toIso8601String().substring(0, 10),
        'description': desc.text.trim(),
      });
      ref.invalidate(seasonDiariesProvider(seasonId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }
}
''')

print('farmer screens batch1 done')
