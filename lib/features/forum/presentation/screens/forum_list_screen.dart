import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/consumer_header_actions.dart';
import 'package:chuoi_xanh_viet/core/widgets/notched_bottom_nav_bar.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/providers/forum_providers.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/widgets/forum_label_chip.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/widgets/forum_post_card.dart';

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
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;
    final isConsumerShell = widget.basePath == '/consumer';
    final shellBottomInset =
        isConsumerShell ? consumerShellBottomInset(context) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.canvasSoft,
      appBar: widget.basePath == '/farmer'
          ? const FarmerTabAppBar(
              subtitle: 'Cộng đồng',
              title: 'Diễn đàn',
            )
          : const ConsumerTabAppBar(
              subtitle: 'Cộng đồng',
              title: 'Diễn đàn',
            ),
      floatingActionButtonLocation: isConsumerShell
          ? const FabAboveShellNavLocation()
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isAuthenticated) {
            context.push('/login');
            return;
          }
          context.push('${widget.basePath}/forum/create');
        },
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        child: const Icon(Icons.edit_rounded),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tiêu đề, nội dung...',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.muted,
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.mintDeep),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.only(bottom: 12),
            child: ForumTopicFilterBar(
              selectedSlug: _label,
              onChanged: (slug) => setState(() => _label = slug),
            ),
          ),
          const Divider(height: 1, color: AppColors.hairline),
          Expanded(
            child: AsyncBody(
              value: async.asLike,
              onRetry: () => ref.invalidate(forumPostsProvider(_query)),
              isEmpty: (page) => page.items.isEmpty,
              emptyMessage: 'Chưa có bài viết — hãy chia sẻ kinh nghiệm đầu tiên',
              builder: (page) => RefreshIndicator(
                color: AppColors.forest,
                onRefresh: () async {
                  ref.invalidate(forumPostsProvider(_query));
                  await ref.read(forumPostsProvider(_query).future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    isConsumerShell ? shellBottomInset + 72 : 88,
                  ),
                  itemCount: page.items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _ForumIntroBanner(
                        onWrite: () {
                          if (!isAuthenticated) {
                            context.push('/login');
                            return;
                          }
                          context.push('${widget.basePath}/forum/create');
                        },
                      );
                    }
                    final p = page.items[i - 1];
                    return ForumPostCard(
                      post: p,
                      onTap: () =>
                          context.push('${widget.basePath}/forum/${p.id}'),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumIntroBanner extends StatelessWidget {
  const _ForumIntroBanner({required this.onWrite});
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.forestSoft],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.forum_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chia sẻ & học hỏi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kinh nghiệm canh tác, sâu bệnh, thị trường.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onWrite,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Viết'),
          ),
        ],
      ),
    );
  }
}
