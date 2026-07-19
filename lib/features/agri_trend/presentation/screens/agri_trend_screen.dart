import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/presentation/providers/agri_trend_providers.dart';

class AgriTrendScreen extends ConsumerWidget {
  const AgriTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agriTrendProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xu hướng nông nghiệp'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(agriTrendProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(agriTrendProvider),
        builder: (t) => ListView(
          padding: AppSpacing.screen,
          children: [
            Text(Formatters.dateTime(t.generatedAt), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            Text(t.summary),
            const SizedBox(height: AppSpacing.xl),
            Text('Cây trồng nóng', style: Theme.of(context).textTheme.titleLarge),
            for (final c in t.hotCrops)
              Card(
                child: ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Text(c['reason'] ?? ''),
                  trailing: Text(c['sentiment'] ?? ''),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Cảnh báo', style: Theme.of(context).textTheme.titleLarge),
            for (final a in t.alerts)
              ListTile(
                leading: const Icon(Icons.warning_amber, color: AppColors.warning),
                title: Text(a['message'] ?? ''),
                subtitle: Text('${a['type']} · ${a['severity']}'),
              ),
          ],
        ),
      ),
    );
  }
}
