import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(conversationsProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có cuộc trò chuyện',
        builder: (list) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final c = list[i];
            final initial = (c.peerName != null && c.peerName!.isNotEmpty)
                ? c.peerName!.characters.first.toUpperCase()
                : '?';
            return ListTile(
              onTap: () => context.push('/chat/${c.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              leading: CircleAvatar(
                backgroundColor: AppColors.lime.withValues(alpha: 0.3),
                child: Text(
                  initial,
                  style: const TextStyle(color: AppColors.forest),
                ),
              ),
              title: Text(c.peerName ?? 'Người dùng'),
              subtitle: Text(
                [
                  if (c.lastMessage != null && c.lastMessage!.isNotEmpty)
                    c.lastMessage!,
                  Formatters.dateTime(c.lastMessageAt),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: c.unreadCount > 0
                  ? CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.forest,
                      child: Text(
                        '${c.unreadCount}',
                        style: const TextStyle(
                          color: AppColors.onPrimary,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
