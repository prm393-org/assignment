import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

const seasonStatusLabels = <String, String>{
  'draft': 'Nháp',
  'ready_to_anchor': 'Sẵn sàng neo',
  'anchored': 'Đã neo',
  'amended': 'Đã sửa',
  'failed': 'Thất bại',
};

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
            Text(
              '${s.code} · ${s.cropName}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Trạng thái',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in seasonStatusLabels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: s.status == entry.key,
                    onSelected: (_) => _updateStatus(context, ref, entry.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Bắt đầu: ${Formatters.date(s.startDate)}'),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Nhật ký canh tác',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AsyncBody(
              value: diaries.asLike,
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Chưa có nhật ký',
              builder: (page) => Column(
                children: [
                  for (final d in page.items)
                    ListTile(
                      title:
                          Text(diaryEventLabels[d.eventType] ?? d.eventType),
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

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      await ref
          .read(farmRepositoryProvider)
          .updateSeasonStatus(seasonId, status);
      ref.invalidate(seasonDetailProvider(seasonId));
      final season = await ref.read(seasonDetailProvider(seasonId).future);
      ref.invalidate(farmSeasonsProvider(season.farmId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật: ${seasonStatusLabels[status] ?? status}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _addDiary(BuildContext context, WidgetRef ref) async {
    final season = await ref.read(seasonDetailProvider(seasonId).future);
    String eventType = 'sowing';
    final desc = TextEditingController();
    String? imageUrl;
    var uploading = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Thêm nhật ký'),
          content: SingleChildScrollView(
            child: Column(
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
                TextField(
                  controller: desc,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: AppSpacing.md),
                if (imageUrl != null)
                  const Text(
                    'Đã chọn ảnh',
                    style: TextStyle(color: AppColors.body),
                  ),
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          final file = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (file == null) return;
                          setLocal(() => uploading = true);
                          try {
                            final urls = await ref
                                .read(uploadRepositoryProvider)
                                .uploadImages([file.path]);
                            if (urls.isNotEmpty) {
                              setLocal(() => imageUrl = urls.first);
                            }
                          } catch (e) {
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(e is Failure ? e.message : '$e'),
                              ),
                            );
                          } finally {
                            setLocal(() => uploading = false);
                          }
                        },
                  icon: uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined),
                  label: Text(uploading ? 'Đang tải...' : 'Thêm ảnh'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final entry = await ref.read(farmRepositoryProvider).createDiary({
        'seasonId': seasonId,
        'farmId': season.farmId,
        'eventType': eventType,
        'eventDate': DateTime.now().toIso8601String().substring(0, 10),
        'description': desc.text.trim(),
        if (imageUrl != null)
          'extraData': {
            'imageUrls': [imageUrl],
          },
      });
      if (imageUrl != null) {
        try {
          await ref.read(farmRepositoryProvider).addDiaryAttachment(
                entry.id,
                fileUrl: imageUrl!,
                mimeType: 'image/jpeg',
              );
        } catch (_) {}
      }
      ref.invalidate(seasonDiariesProvider(seasonId));
      ref.invalidate(farmDiariesProvider(season.farmId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }
}
