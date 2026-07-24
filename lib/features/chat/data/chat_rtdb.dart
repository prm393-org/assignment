import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
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
    if (FirebaseAuth.instance.currentUser == null) {
      if (kDebugMode) {
        debugPrint(
          'ChatRtdb: skip listen — Firebase Auth chưa đăng nhập '
          '(RTDB rules cần auth). Hãy đăng xuất rồi đăng nhập lại.',
        );
      }
      return;
    }
    try {
      _sub = RtdbRefs.chatMessages(conversationId)
          .orderByChild('createdAtMs')
          .limitToLast(50)
          .onChildAdded
          .listen(
        (event) {
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
        },
        onError: (Object error, StackTrace stack) {
          if (kDebugMode) debugPrint('ChatRtdb listen error: $error');
          unawaited(CrashlyticsService.recordNonFatal(
            error,
            stack,
            reason: 'chat_rtdb_listen_fail',
          ));
        },
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('ChatRtdb join error: $e');
      unawaited(CrashlyticsService.recordNonFatal(e, st, reason: 'chat_rtdb_join_fail'));
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
    if (message.conversationId.isEmpty) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      if (kDebugMode) {
        debugPrint(
          'ChatRtdb.publish skipped: Firebase Auth null — '
          'đăng xuất rồi đăng nhập lại sau khi bật Authentication.',
        );
      }
      return;
    }

    try {
      final ref = message.id.isNotEmpty
          ? RtdbRefs.chatMessage(message.conversationId, message.id)
          : RtdbRefs.chatMessages(message.conversationId).push();
      final messageId = message.id.isNotEmpty ? message.id : ref.key;
      if (messageId == null || messageId.isEmpty) return;

      await ref.set({
        'id': messageId,
        'conversationId': message.conversationId,
        'senderUserId': message.senderId,
        'senderId': message.senderId,
        'content': message.content,
        'createdAt': message.createdAt ?? DateTime.now().toIso8601String(),
        'createdAtMs': ServerValue.timestamp,
      });
      if (kDebugMode) {
        debugPrint(
          'ChatRtdb.publish ok: chat_messages/${message.conversationId}/$messageId',
        );
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('ChatRtdb.publish error: $e');
      unawaited(CrashlyticsService.recordNonFatal(
        e,
        st,
        reason: 'chat_rtdb_publish_fail conv=${message.conversationId}',
      ));
    }
  }

  void dispose() => leave();
}
