import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/forum_labels.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';
import 'package:chuoi_xanh_viet/features/upload/presentation/providers/upload_providers.dart';

class CreateForumPostScreen extends ConsumerStatefulWidget {
  const CreateForumPostScreen({super.key, this.editPostId});

  final String? editPostId;

  @override
  ConsumerState<CreateForumPostScreen> createState() =>
      _CreateForumPostScreenState();
}

class _CreateForumPostScreenState extends ConsumerState<CreateForumPostScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _selectedLabels = <String>{};
  final _imageUrls = <String>[];
  bool _loading = false;
  bool _uploading = false;
  bool _hydrating = false;

  bool get _isEdit => widget.editPostId != null;

  @override
  void initState() {
    super.initState();
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
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final urls = await ref
          .read(uploadRepositoryProvider)
          .uploadImages(files.map((f) => f.path).toList());
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
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
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
    if (_hydrating) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sửa bài viết')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa bài viết' : 'Tạo bài viết'),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _content,
            decoration: const InputDecoration(labelText: 'Nội dung'),
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Chủ đề', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slug in ForumLabels.all)
                FilterChip(
                  label: Text(ForumLabels.labelOf(slug)),
                  selected: _selectedLabels.contains(slug),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedLabels.add(slug);
                      } else {
                        _selectedLabels.remove(slug);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text('Hình ảnh', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: _uploading ? null : _pickImages,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Thêm ảnh'),
              ),
            ],
          ),
          if (_imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final url = _imageUrls[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppNetworkImage(
                          url: url,
                          width: 96,
                          height: 96,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _imageUrls.removeAt(i)),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _loading || _uploading ? null : _submit,
            child: Text(_isEdit ? 'Lưu thay đổi' : 'Đăng bài'),
          ),
        ],
      ),
    );
  }
}
