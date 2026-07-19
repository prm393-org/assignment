import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liên lạc', style: Theme.of(context).textTheme.bodySmall),
            Text('Tin nhắn', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(conversationsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có cuộc trò chuyện',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final c = list[i];
            final name = c.peerName ?? 'Người dùng';
            final initial =
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
            return SurfaceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push('/chat/${c.id}'),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.mint,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (c.unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.forest,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${c.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.lastMessage?.isNotEmpty == true
                              ? c.lastMessage!
                              : 'Chưa có tin nhắn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: c.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.dateTime(c.lastMessageAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
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
