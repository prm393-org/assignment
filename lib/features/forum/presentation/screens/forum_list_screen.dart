import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumListScreen extends ConsumerWidget {
  const ForumListScreen({super.key, this.basePath = '/consumer'});

  final String basePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(forumPostsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cộng đồng', style: Theme.of(context).textTheme.bodySmall),
            Text('Diễn đàn', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('$basePath/forum/create'),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Viết bài'),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(forumPostsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có bài viết — hãy chia sẻ kinh nghiệm đầu tiên',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            if (i == 0) {
              return SoftHeroBanner(
                title: 'Chia sẻ & học hỏi',
                subtitle: 'Kinh nghiệm canh tác, thị trường và câu chuyện nông sản.',
                icon: Icons.forum_rounded,
              );
            }
            final p = page.items[i - 1];
            final authorName = p.author?.fullName ?? 'Ẩn danh';
            final initial = authorName.isNotEmpty
                ? authorName.characters.first.toUpperCase()
                : '?';
            return SurfaceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('$basePath/forum/${p.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.mint,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              Formatters.dateTime(p.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const IconBadge(
                        icon: Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color: AppColors.surfaceElevated,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      p.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.mode_comment_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p.commentCount} bình luận',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        'Xem thêm',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.forest,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
