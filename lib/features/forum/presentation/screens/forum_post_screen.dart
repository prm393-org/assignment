import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/entities/forum_post.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/widgets/forum_author_avatar.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/widgets/forum_label_chip.dart';

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
  final _focus = FocusNode();
  bool _sending = false;
  int _imageIndex = 0;

  @override
  void dispose() {
    _comment.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(forumRepositoryProvider).createComment(widget.postId, text);
      _comment.clear();
      _focus.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editComment(ForumComment c) async {
    final ctrl = TextEditingController(text: c.content);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sửa bình luận',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nội dung bình luận',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
    final postAsync = ref.watch(forumPostProvider(widget.postId));
    final commentsAsync = ref.watch(forumCommentsProvider(widget.postId));
    final uid = ref.watch(currentFirebaseUidProvider);
    final textTheme = Theme.of(context).textTheme;
    final post = postAsync.valueOrNull;
    final canManagePost =
        post != null && uid != null && post.author?.id == uid;

    return Scaffold(
      backgroundColor: AppColors.canvasSoft,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: const Text('Bài viết'),
        actions: [
          if (canManagePost)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  context.push(
                    '${widget.basePath}/forum/${widget.postId}/edit',
                  );
                }
                if (v == 'delete') _deletePost();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Sửa bài'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Xóa bài'),
                ),
              ],
            ),
        ],
      ),
      body: postAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorState(
          message: e is Failure ? e.message : '$e',
          onRetry: () => ref.invalidate(forumPostProvider(widget.postId)),
        ),
        data: (p) {
          final ago = Formatters.activityAgo(p.createdAt);
          final timeLabel =
              ago.isEmpty ? Formatters.dateTime(p.createdAt) : ago;
          final authorName = (p.author?.fullName.trim().isNotEmpty ?? false)
              ? p.author!.fullName
              : 'Ẩn danh';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ForumAuthorAvatar(author: p.author, size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeLabel,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (p.labels.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final slug in p.labels)
                                  ForumLabelChip(slug: slug, compact: true),
                              ],
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            p.title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p.content,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.body,
                              height: 1.55,
                            ),
                          ),
                          if (p.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: PageView.builder(
                                  itemCount: p.imageUrls.length,
                                  onPageChanged: (i) =>
                                      setState(() => _imageIndex = i),
                                  itemBuilder: (_, i) => AppNetworkImage(
                                    url: p.imageUrls[i],
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                            if (p.imageUrls.length > 1) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < p.imageUrls.length; i++)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: i == _imageIndex
                                            ? AppColors.forest
                                            : AppColors.hairlineStrong,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.mode_comment_outlined,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${p.commentCount} bình luận',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Thảo luận',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CommentsSection(
                      commentsAsync: commentsAsync,
                      uid: uid,
                      onEdit: _editComment,
                      onDelete: _deleteComment,
                    ),
                  ],
                ),
              ),
              _CommentComposer(
                controller: _comment,
                focusNode: _focus,
                sending: _sending,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.commentsAsync,
    required this.uid,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<ForumComment>> commentsAsync;
  final String? uid;
  final ValueChanged<ForumComment> onEdit;
  final ValueChanged<ForumComment> onDelete;

  @override
  Widget build(BuildContext context) {
    return commentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          e is Failure ? e.message : 'Không tải được bình luận',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Chưa có bình luận — hãy là người đầu tiên',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
          );
        }
        return Column(
          children: [
            for (final c in list) ...[
              _CommentTile(
                comment: c,
                isMine: uid != null && c.author?.id == uid,
                onEdit: () => onEdit(c),
                onDelete: () => onDelete(c),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isMine,
    required this.onEdit,
    required this.onDelete,
  });

  final ForumComment comment;
  final bool isMine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ago = Formatters.activityAgo(comment.createdAt);
    final timeLabel =
        ago.isEmpty ? Formatters.date(comment.createdAt) : ago;
    final name = comment.author?.fullName.trim().isNotEmpty == true
        ? comment.author!.fullName
        : 'Người dùng';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ForumAuthorAvatar(author: comment.author, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$name · $timeLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isMine)
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') onEdit();
                          if (v == 'delete') onDelete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Sửa')),
                          PopupMenuItem(value: 'delete', child: Text('Xóa')),
                        ],
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.45,
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

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.shadow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final canSend = controller.text.trim().isNotEmpty && !sending;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.mintDeep),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: canSend
                        ? AppColors.forest
                        : AppColors.hairlineStrong,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: canSend ? onSend : null,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: AppColors.onPrimary,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
