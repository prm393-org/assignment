import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/chat/data/chat_rtdb.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/chat_message.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  final List<ChatMessage> _liveMessages = [];
  ChatRealtimeController? _realtime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _realtime = ref.read(chatRealtimeControllerProvider);
      _realtime!.joinConversation(
        widget.conversationId,
        onMessage: _onLiveMessage,
      );
    });
  }

  void _onLiveMessage(ChatMessage message) {
    if (!mounted) return;
    if (message.conversationId.isNotEmpty &&
        message.conversationId != widget.conversationId) {
      return;
    }
    final exists = _liveMessages.any((m) => m.id == message.id);
    if (exists) return;
    setState(() => _liveMessages.add(message));
    ref.invalidate(chatMessagesProvider(widget.conversationId));
    ref.invalidate(conversationsProvider);
  }

  @override
  void dispose() {
    _realtime?.leaveConversation(widget.conversationId);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await ref
          .read(chatRepositoryProvider)
          .sendMessage(widget.conversationId, text);
      await ChatRtdb.publish(sent);
      _input.clear();
      if (!_liveMessages.any((m) => m.id == sent.id)) {
        setState(() => _liveMessages.add(sent));
      }
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<ChatMessage> _merge(List<ChatMessage> remote) {
    final byId = <String, ChatMessage>{};
    for (final m in remote) {
      byId[m.id] = m;
    }
    for (final m in _liveMessages) {
      byId[m.id] = m;
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final aAt = a.createdAt ?? '';
        final bAt = b.createdAt ?? '';
        return aAt.compareTo(bAt);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatMessagesProvider(widget.conversationId));
    final myId = ref.watch(authNotifierProvider).user?.id;
    final peerName = ref
        .watch(conversationsProvider)
        .valueOrNull
        ?.where((c) => c.id == widget.conversationId)
        .map((c) => c.peerName)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          peerName != null && peerName.trim().isNotEmpty
              ? peerName
              : 'Trò chuyện',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncBody(
              value: async.asLike,
              onRetry: () =>
                  ref.invalidate(chatMessagesProvider(widget.conversationId)),
              isEmpty: (list) => _merge(list).isEmpty,
              emptyMessage: 'Chưa có tin nhắn',
              builder: (list) {
                final messages = _merge(list).reversed.toList();
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: AppSpacing.screen,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMine = myId != null && m.senderId == myId;
                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.forest : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: isMine
                              ? null
                              : Border.all(color: AppColors.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.content,
                              style: TextStyle(
                                color: isMine
                                    ? AppColors.onPrimary
                                    : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.dateTime(m.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMine
                                    ? AppColors.onPrimary.withValues(alpha: 0.8)
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send, color: AppColors.forest),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
