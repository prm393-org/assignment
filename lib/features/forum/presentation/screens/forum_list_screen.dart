import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/forum/domain/forum_labels.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';

class ForumListScreen extends ConsumerStatefulWidget {
  const ForumListScreen({super.key, this.basePath = '/consumer'});

  final String basePath;

  @override
  ConsumerState<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends ConsumerState<ForumListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _label;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _search = value.trim());
    });
  }

  ForumListQuery get _query => ForumListQuery(
        searchTerm: _search.isEmpty ? null : _search,
        label: _label,
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(forumPostsProvider(_query));
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
        onPressed: () => context.push('${widget.basePath}/forum/create'),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Viết bài'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              decoration: InputDecoration(
                hintText: 'Tìm bài viết...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tất cả'),
                    selected: _label == null,
                    onSelected: (_) => setState(() => _label = null),
                  ),
                ),
                for (final slug in ForumLabels.all)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(ForumLabels.labelOf(slug)),
                      selected: _label == slug,
                      onSelected: (selected) {
                        setState(() => _label = selected ? slug : null);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncBody(
              value: async.asLike,
              onRetry: () => ref.invalidate(forumPostsProvider(_query)),
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Chưa có bài viết — hãy chia sẻ kinh nghiệm đầu tiên',
              builder: (page) => ListView.separated(
                padding: AppSpacing.screen,
                itemCount: page.items.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return const SoftHeroBanner(
                      title: 'Chia sẻ & học hỏi',
                      subtitle:
                          'Kinh nghiệm canh tác, thị trường và câu chuyện nông sản.',
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
                    onTap: () =>
                        context.push('${widget.basePath}/forum/${p.id}'),
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
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    Formatters.dateTime(p.createdAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                        if (p.labels.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final slug in p.labels.take(3))
                                Chip(
                                  label: Text(
                                    ForumLabels.labelOf(slug),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ],
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
                        if (p.imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppNetworkImage(
                              url: p.imageUrls.first,
                              height: 140,
                              width: double.infinity,
                            ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: AppColors.forest),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
