import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumPostScreen extends ConsumerStatefulWidget {
  const ForumPostScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends ConsumerState<ForumPostScreen> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(forumRepositoryProvider).createComment(widget.postId, text);
      _comment.clear();
      ref.invalidate(forumCommentsProvider(widget.postId));
      ref.invalidate(forumPostProvider(widget.postId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(forumPostProvider(widget.postId));
    final comments = ref.watch(forumCommentsProvider(widget.postId));
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: AsyncBody(
        value: post.asLike,
        onRetry: () => ref.invalidate(forumPostProvider(widget.postId)),
        builder: (p) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screen,
                children: [
                  Text(p.title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${p.author?.fullName ?? ''} · ${Formatters.dateTime(p.createdAt)}',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(p.content),
                  const Divider(height: 32),
                  Text('Bình luận', style: Theme.of(context).textTheme.titleMedium),
                  AsyncBody(
                    value: comments.asLike,
                    isEmpty: (list) => list.isEmpty,
                    emptyMessage: 'Chưa có bình luận',
                    builder: (list) => Column(
                      children: [
                        for (final c in list)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.author?.fullName ?? 'Người dùng'),
                            subtitle: Text(c.content),
                            trailing: Text(Formatters.date(c.createdAt)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: AppSpacing.screen,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _comment,
                        decoration: const InputDecoration(
                          hintText: 'Viết bình luận...',
                        ),
                      ),
                    ),
                    IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
