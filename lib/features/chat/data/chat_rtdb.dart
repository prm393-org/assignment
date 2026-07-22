import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:chuoi_xanh_viet/core/firebase/rtdb_refs.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/chat_message.dart';

/// Chat realtime over Firebase RTDB (replaces Socket.IO).
///
/// REST remains the source of truth for send/history; after a successful
/// REST send the client mirrors the message into RTDB so peers receive it live.
class ChatRtdb {
  StreamSubscription<DatabaseEvent>? _sub;
  String? _activeConversationId;
  void Function(ChatMessage message)? _onMessage;

  void joinConversation(
    String conversationId, {
    required void Function(ChatMessage message) onMessage,
  }) {
    leave();
    _activeConversationId = conversationId;
    _onMessage = onMessage;
    try {
      _sub = RtdbRefs.chatMessages(conversationId)
          .orderByChild('createdAtMs')
          .limitToLast(50)
          .onChildAdded
          .listen((event) {
        final snap = event.snapshot;
        final data = snap.value;
        if (data is! Map) return;
        final map = Map<String, dynamic>.from(
          data.map((k, v) => MapEntry('$k', v)),
        );
        map.putIfAbsent('id', () => snap.key ?? '');
        map.putIfAbsent('conversationId', () => conversationId);
        final message = ChatMessage.fromJson(map);
        if (message.id.isEmpty || message.content.isEmpty) return;
        _onMessage?.call(message);
      });
    } catch (_) {
      // Unconfigured RTDB — thread still works via REST invalidate.
    }
  }

  void leave() {
    _sub?.cancel();
    _sub = null;
    _activeConversationId = null;
    _onMessage = null;
  }

  String? get activeConversationId => _activeConversationId;

  /// Mirror a persisted REST message into RTDB for live peers.
  static Future<void> publish(ChatMessage message) async {
    if (message.id.isEmpty || message.conversationId.isEmpty) return;
    try {
      await RtdbRefs.chatMessage(message.conversationId, message.id).set({
        'id': message.id,
        'conversationId': message.conversationId,
        'senderUserId': message.senderId,
        'senderId': message.senderId,
        'content': message.content,
        'createdAt': message.createdAt ?? DateTime.now().toIso8601String(),
        'createdAtMs': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  void dispose() => leave();
}
