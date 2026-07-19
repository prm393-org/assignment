import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class CreateForumPostScreen extends ConsumerStatefulWidget {
  const CreateForumPostScreen({super.key});

  @override
  ConsumerState<CreateForumPostScreen> createState() =>
      _CreateForumPostScreenState();
}

class _CreateForumPostScreenState extends ConsumerState<CreateForumPostScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(forumRepositoryProvider).createPost(
            title: _title.text.trim(),
            content: _content.text.trim(),
          );
      ref.invalidate(forumPostsProvider);
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
      appBar: AppBar(title: const Text('Tạo bài viết')),
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
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: const Text('Đăng bài'),
          ),
        ],
      ),
    );
  }
}
