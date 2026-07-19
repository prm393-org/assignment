import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumListScreen extends ConsumerWidget {
  const ForumListScreen({super.key, this.basePath = '/consumer'});

  final String basePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(forumPostsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diễn đàn')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('$basePath/forum/create'),
        child: const Icon(Icons.edit),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(forumPostsProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có bài viết',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final p = page.items[i];
            return ListTile(
              onTap: () => context.push('$basePath/forum/${p.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(p.title),
              subtitle: Text(
                '${p.author?.fullName ?? 'Ẩn danh'} · ${Formatters.dateTime(p.createdAt)} · ${p.commentCount} bình luận',
              ),
            );
          },
        ),
      ),
    );
  }
}
