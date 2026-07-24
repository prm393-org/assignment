import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/forum_labels.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/widgets/forum_label_chip.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class CreateForumPostScreen extends ConsumerStatefulWidget {
  const CreateForumPostScreen({super.key, this.editPostId});

  final String? editPostId;

  @override
  ConsumerState<CreateForumPostScreen> createState() =>
      _CreateForumPostScreenState();
}

class _CreateForumPostScreenState extends ConsumerState<CreateForumPostScreen> {
  static const _maxImages = 6;

  final _title = TextEditingController();
  final _content = TextEditingController();
  final _selectedLabels = <String>{};
  final _imageUrls = <String>[];
  bool _loading = false;
  bool _uploading = false;
  bool _hydrating = false;

  bool get _isEdit => widget.editPostId != null;

  bool get _canSubmit =>
      !_loading &&
      !_uploading &&
      _title.text.trim().isNotEmpty &&
      _content.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
    _content.addListener(() => setState(() {}));
    if (_isEdit) {
      _hydrating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    try {
      final post =
          await ref.read(forumRepositoryProvider).getPost(widget.editPostId!);
      if (!mounted) return;
      setState(() {
        _title.text = post.title;
        _content.text = post.content;
        _selectedLabels
          ..clear()
          ..addAll(post.labels);
        _imageUrls
          ..clear()
          ..addAll(post.imageUrls);
        _hydrating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hydrating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _imageUrls.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa $_maxImages ảnh mỗi bài')),
      );
      return;
    }
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final paths = files.take(remaining).map((f) => f.path).toList();
      final urls =
          await ref.read(uploadRepositoryProvider).uploadImages(paths);
      if (!mounted) return;
      setState(() => _imageUrls.addAll(urls));
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
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(forumRepositoryProvider);
      if (_isEdit) {
        await repo.updatePost(
          postId: widget.editPostId!,
          title: _title.text.trim(),
          content: _content.text.trim(),
          labels: _selectedLabels.toList(),
          imageUrls: List<String>.from(_imageUrls),
        );
        ref.invalidate(forumPostProvider(widget.editPostId!));
      } else {
        await repo.createPost(
          title: _title.text.trim(),
          content: _content.text.trim(),
          labels: _selectedLabels.toList(),
          imageUrls: List<String>.from(_imageUrls),
        );
      }
      ref.invalidate(forumPostsProvider(const ForumListQuery()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Đã cập nhật bài viết' : 'Đã đăng bài'),
          ),
        );
        context.pop();
      }
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
    if (_hydrating) {
      return Scaffold(
        backgroundColor: AppColors.canvasSoft,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          title: const Text('Sửa bài viết'),
        ),
        body: const LoadingView(message: 'Đang tải bài viết…'),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.canvasSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEdit ? 'Sửa bài viết' : 'Viết bài mới'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(_isEdit ? 'Lưu' : 'Đăng'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nội dung',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    hintText: 'Tiêu đề bài viết',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _content,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: 'Chia sẻ kinh nghiệm, câu hỏi, mẹo canh tác...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Chủ đề',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedLabels.isEmpty
                          ? 'Tuỳ chọn'
                          : '${_selectedLabels.length} đã chọn',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slug in ForumLabels.all)
                      ForumLabelChip(
                        slug: slug,
                        selected: _selectedLabels.contains(slug),
                        onTap: () {
                          setState(() {
                            if (_selectedLabels.contains(slug)) {
                              _selectedLabels.remove(slug);
                            } else {
                              _selectedLabels.add(slug);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hình ảnh',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_imageUrls.length}/$_maxImages',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _AddImageTile(
                        loading: _uploading,
                        enabled: _imageUrls.length < _maxImages,
                        onTap: _pickImages,
                      ),
                      for (var i = 0; i < _imageUrls.length; i++) ...[
                        const SizedBox(width: 8),
                        _ImageThumb(
                          url: _imageUrls[i],
                          onRemove: () =>
                              setState(() => _imageUrls.removeAt(i)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: Icon(_isEdit ? Icons.save_outlined : Icons.send_rounded),
            label: Text(_isEdit ? 'Lưu thay đổi' : 'Đăng bài viết'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tôn trọng cộng đồng — chia sẻ nội dung hữu ích, rõ ràng.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: child,
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.hairlineStrong,
            radius: 12,
          ),
          child: SizedBox(
            width: 96,
            height: 96,
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: enabled ? AppColors.forest : AppColors.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thêm',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  enabled ? AppColors.forest : AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.url, required this.onRemove});
  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AppNetworkImage(url: url, width: 96, height: 96),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: AppColors.ink.withValues(alpha: 0.65),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
