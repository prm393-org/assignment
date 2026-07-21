import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/farm/data/local/pending_diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/pending_diary_queue_provider.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class DiaryDashboardScreen extends ConsumerStatefulWidget {
  const DiaryDashboardScreen({super.key});

  @override
  ConsumerState<DiaryDashboardScreen> createState() =>
      _DiaryDashboardScreenState();
}

class _DiaryDashboardScreenState extends ConsumerState<DiaryDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _farmId;
  String? _seasonId;
  String _eventType = 'sowing';
  final _desc = TextEditingController();
  String? _imageUrl;
  bool _saving = false;
  bool _uploading = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final urls =
          await ref.read(uploadRepositoryProvider).uploadImages([file.path]);
      if (urls.isNotEmpty) {
        setState(() => _imageUrl = urls.first);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (_farmId == null || _seasonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn nông trại và mùa vụ')),
      );
      return;
    }
    setState(() => _saving = true);
    final eventDate = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final body = <String, dynamic>{
        'seasonId': _seasonId,
        'farmId': _farmId,
        'eventType': _eventType,
        'eventDate': eventDate,
        'description': _desc.text.trim(),
        if (_imageUrl != null)
          'extraData': {
            'imageUrls': [_imageUrl],
          },
      };
      final entry = await ref.read(farmRepositoryProvider).createDiary(body);
      if (_imageUrl != null) {
        try {
          await ref.read(farmRepositoryProvider).addDiaryAttachment(
                entry.id,
                fileUrl: _imageUrl!,
                mimeType: 'image/jpeg',
              );
        } catch (_) {
          // Attachment endpoint may be missing; extraData already sent.
        }
      }
      _onSaved('Đã ghi nhật ký');
    } on NetworkFailure {
      await ref.read(pendingDiaryQueueProvider.notifier).enqueue(
            PendingDiaryEntry(
              localId: DateTime.now().microsecondsSinceEpoch.toString(),
              farmId: _farmId!,
              seasonId: _seasonId!,
              eventType: _eventType,
              eventDate: eventDate,
              description: _desc.text.trim(),
              imageUrl: _imageUrl,
            ),
          );
      _onSaved('Đã lưu offline, sẽ đồng bộ khi có mạng');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onSaved(String message) {
    _desc.clear();
    setState(() => _imageUrl = null);
    ref.invalidate(farmDiariesProvider(_farmId!));
    ref.invalidate(seasonDiariesProvider(_seasonId!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _tabs.animateTo(1);
  }

  Future<void> _syncPending() async {
    setState(() => _syncing = true);
    final synced = await ref
        .read(pendingDiaryQueueProvider.notifier)
        .flush(ref.read(farmRepositoryProvider));
    if (_farmId != null) ref.invalidate(farmDiariesProvider(_farmId!));
    if (_seasonId != null) ref.invalidate(seasonDiariesProvider(_seasonId!));
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced > 0 ? 'Đã đồng bộ $synced mục' : 'Chưa đồng bộ được, thử lại sau',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(myFarmsProvider);
    final seasonsAsync = _farmId == null
        ? null
        : ref.watch(farmSeasonsProvider(_farmId!));
    final diariesAsync =
        _farmId == null ? null : ref.watch(farmDiariesProvider(_farmId!));
    final pending = ref.watch(pendingDiaryQueueProvider);

    final entryCount = diariesAsync?.valueOrNull?.items.length ?? 0;
    final seasonCount = seasonsAsync?.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký canh tác'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Ghi nhật ký'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pending.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${pending.length} nhật ký chưa đồng bộ'),
                        ),
                        TextButton(
                          onPressed: _syncing ? null : _syncPending,
                          child: Text(
                            _syncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AsyncBody(
                  value: farmsAsync.asLike,
                  onRetry: () => ref.invalidate(myFarmsProvider),
                  isEmpty: (list) => list.isEmpty,
                  emptyMessage: 'Chưa có nông trại',
                  builder: (farms) {
                    final selected = _farmId != null &&
                            farms.any((f) => f.id == _farmId)
                        ? _farmId
                        : farms.first.id;
                    if (_farmId != selected) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _farmId = selected);
                      });
                    }
                    return DropdownButtonFormField<String>(
                      value: selected,
                      decoration:
                          const InputDecoration(labelText: 'Nông trại'),
                      items: [
                        for (final f in farms)
                          DropdownMenuItem(value: f.id, child: Text(f.name)),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _farmId = v;
                          _seasonId = null;
                        });
                      },
                    );
                  },
                ),
                if (_farmId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _StatChip(
                          label: 'Nhật ký',
                          value: '$entryCount',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatChip(
                          label: 'Mùa vụ',
                          value: '$seasonCount',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  padding: AppSpacing.screen,
                  children: [
                    if (seasonsAsync != null)
                      AsyncBody(
                        value: seasonsAsync.asLike,
                        onRetry: () =>
                            ref.invalidate(farmSeasonsProvider(_farmId!)),
                        isEmpty: (list) => list.isEmpty,
                        emptyMessage: 'Chưa có mùa vụ',
                        builder: (seasons) {
                          final selected = _seasonId != null &&
                                  seasons.any((s) => s.id == _seasonId)
                              ? _seasonId
                              : seasons.first.id;
                          if (_seasonId != selected) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _seasonId = selected);
                              }
                            });
                          }
                          return DropdownButtonFormField<String>(
                            value: selected,
                            decoration:
                                const InputDecoration(labelText: 'Mùa vụ'),
                            items: [
                              for (final s in seasons)
                                DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.code} · ${s.cropName}'),
                                ),
                            ],
                            onChanged: (v) => setState(() => _seasonId = v),
                          );
                        },
                      ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _eventType,
                      decoration:
                          const InputDecoration(labelText: 'Loại sự kiện'),
                      items: [
                        for (final e in diaryEventLabels.entries)
                          DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _eventType = v ?? 'other'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _desc,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_imageUrl != null)
                      Text(
                        'Đã chọn ảnh',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickImage,
                      icon: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _uploading ? 'Đang tải...' : 'Thêm ảnh',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: Text(_saving ? 'Đang lưu...' : 'Lưu nhật ký'),
                    ),
                  ],
                ),
                if (diariesAsync == null)
                  const EmptyState(message: 'Chọn nông trại để xem lịch sử')
                else
                  AsyncBody(
                    value: diariesAsync.asLike,
                    onRetry: () =>
                        ref.invalidate(farmDiariesProvider(_farmId!)),
                    isEmpty: (page) => page.items.isEmpty,
                    emptyMessage: 'Chưa có nhật ký',
                    builder: (page) => ListView.separated(
                      padding: AppSpacing.screen,
                      itemCount: page.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final d = page.items[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.hairline),
                          ),
                          tileColor: AppColors.surface,
                          title: Text(
                            diaryEventLabels[d.eventType] ?? d.eventType,
                          ),
                          subtitle: Text(d.description ?? ''),
                          trailing: Text(Formatters.date(d.eventDate)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
