import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/chat/data/chat_socket.dart';
import 'package:chuoi_xanh_viet/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/chat_message.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/conversation.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(dioProvider));
});

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).listConversations();
});

final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, id) {
  return ref.watch(chatRepositoryProvider).listMessages(id);
});

class ChatSocketController {
  ChatSocketController(this._socket);

  final ChatSocket _socket;
  String? _activeConversationId;
  void Function(ChatMessage message)? _onThreadMessage;

  void connect(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) {
      disconnect();
      return;
    }
    _socket.connect(accessToken);
    _socket.onMessage(_handleRawMessage);
  }

  void disconnect() {
    _activeConversationId = null;
    _onThreadMessage = null;
    _socket.offMessage();
    _socket.disconnect();
  }

  void joinConversation(
    String conversationId, {
    required void Function(ChatMessage message) onMessage,
  }) {
    _activeConversationId = conversationId;
    _onThreadMessage = onMessage;
    _socket.join(conversationId);
  }

  void leaveConversation(String conversationId) {
    if (_activeConversationId == conversationId) {
      _activeConversationId = null;
      _onThreadMessage = null;
    }
    _socket.leave(conversationId);
  }

  void _handleRawMessage(dynamic data) {
    final map = asMap(data is Map ? data : unwrapData(data));
    if (map.isEmpty) return;
    final nested = asMap(map['message'] ?? map['data']);
    final json = nested.isNotEmpty ? nested : map;
    final message = ChatMessage.fromJson(json);
    if (_activeConversationId != null &&
        message.conversationId.isNotEmpty &&
        message.conversationId != _activeConversationId) {
      return;
    }
    _onThreadMessage?.call(message);
  }

  void dispose() => disconnect();
}

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket();
  ref.onDispose(socket.disconnect);
  return socket;
});

final chatSocketControllerProvider = Provider<ChatSocketController>((ref) {
  final controller = ChatSocketController(ref.watch(chatSocketProvider));
  ref.listen<AuthState>(authNotifierProvider, (prev, next) {
    if (next.isAuthenticated && next.accessToken != null) {
      controller.connect(next.accessToken);
    } else {
      controller.disconnect();
    }
  }, fireImmediately: true);
  ref.onDispose(controller.dispose);
  return controller;
});
