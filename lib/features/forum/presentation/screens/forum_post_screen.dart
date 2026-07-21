import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/forum_labels.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumPostScreen extends ConsumerStatefulWidget {
  const ForumPostScreen({
    super.key,
    required this.postId,
    this.basePath = '/consumer',
  });

  final String postId;
  final String basePath;

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

  Future<void> _editComment(ForumComment c) async {
    final ctrl = TextEditingController(text: c.content);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa bình luận'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Nội dung'),
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
    );
    if (ok != true) return;
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(forumRepositoryProvider).updateComment(
            postId: widget.postId,
            commentId: c.id,
            content: text,
          );
      ref.invalidate(forumCommentsProvider(widget.postId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _deleteComment(ForumComment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bình luận?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(forumRepositoryProvider).deleteComment(
            postId: widget.postId,
            commentId: c.id,
          );
      ref.invalidate(forumCommentsProvider(widget.postId));
      ref.invalidate(forumPostProvider(widget.postId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text('Bài viết và bình luận sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(forumRepositoryProvider).deletePost(widget.postId);
      ref.invalidate(forumPostsProvider(const ForumListQuery()));
      if (mounted) context.pop();
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
    final uid = ref.watch(currentFirebaseUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
        actions: [
          post.maybeWhen(
            data: (p) {
              if (uid == null || p.author?.id != uid) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    context.push(
                      '${widget.basePath}/forum/${widget.postId}/edit',
                    );
                  }
                  if (v == 'delete') _deletePost();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Sửa bài')),
                  PopupMenuItem(value: 'delete', child: Text('Xóa bài')),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncBody(
        value: post.asLike,
        onRetry: () => ref.invalidate(forumPostProvider(widget.postId)),
        builder: (p) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screen,
                children: [
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${p.author?.fullName ?? ''} · ${Formatters.dateTime(p.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (p.labels.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final slug in p.labels)
                          Chip(
                            label: Text(ForumLabels.labelOf(slug)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor:
                                AppColors.mint.withValues(alpha: 0.45),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(p.content),
                  if (p.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    for (final url in p.imageUrls) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppNetworkImage(
                          url: url,
                          width: double.infinity,
                          height: 220,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  const Divider(height: 32),
                  Text(
                    'Bình luận',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                            subtitle: Text(
                              '${c.content}\n${Formatters.date(c.createdAt)}',
                            ),
                            isThreeLine: true,
                            trailing: uid != null && c.author?.id == uid
                                ? PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') _editComment(c);
                                      if (v == 'delete') _deleteComment(c);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Sửa'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa'),
                                      ),
                                    ],
                                  )
                                : null,
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
