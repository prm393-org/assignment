import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/firebase/presence_service.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/chat/data/chat_rtdb.dart';
import 'package:chuoi_xanh_viet/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/chat_message.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/conversation.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(dioProvider));
});

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final meId = ref.watch(authNotifierProvider).user?.id;
  final list = await ref.watch(chatRepositoryProvider).listConversations();
  return list.map((c) => c.resolvedFor(meId)).toList();
});

/// Total unread messages across conversations (header badge).
final unreadChatCountProvider = Provider<int>((ref) {
  if (!ref.watch(authNotifierProvider).isAuthenticated) return 0;
  final convs = ref.watch(conversationsProvider).valueOrNull;
  if (convs == null) return 0;
  var total = 0;
  for (final c in convs) {
    total += c.unreadCount;
  }
  return total;
});

final chatMessagesProvider =
    FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, id) {
  return ref.watch(chatRepositoryProvider).listMessages(id);
});

/// Replaces Socket.IO — RTDB child_added for the active conversation.
class ChatRealtimeController {
  ChatRealtimeController(this._rtdb);

  final ChatRtdb _rtdb;

  void joinConversation(
    String conversationId, {
    required void Function(ChatMessage message) onMessage,
  }) {
    _rtdb.joinConversation(conversationId, onMessage: onMessage);
  }

  void leaveConversation(String conversationId) {
    if (_rtdb.activeConversationId == conversationId) {
      _rtdb.leave();
    }
  }

  void dispose() => _rtdb.dispose();
}

final chatRtdbProvider = Provider<ChatRtdb>((ref) {
  final rtdb = ChatRtdb();
  ref.onDispose(rtdb.dispose);
  return rtdb;
});

final chatRealtimeControllerProvider = Provider<ChatRealtimeController>((ref) {
  final controller = ChatRealtimeController(ref.watch(chatRtdbProvider));
  ref.onDispose(controller.dispose);
  return controller;
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService();
  ref.onDispose(() {
    // ignore: discarded_futures
    service.goOffline();
  });
  return service;
});

/// Keeps presence + Crashlytics user identity in sync with auth/Firebase uid.
final presenceBindingProvider = Provider<void>((ref) {
  final presence = ref.watch(presenceServiceProvider);
  ref.listen(authNotifierProvider, (prev, next) async {
    final uid = ref.read(currentFirebaseUidProvider);
    if (next.isAuthenticated && uid != null) {
      await CrashlyticsService.setUser(
        firebaseUid: uid,
        backendUserId: next.user?.id,
        email: next.user?.email,
        role: next.user?.role,
      );
      await presence.goOnline(
        firebaseUid: uid,
        backendUserId: next.user?.id,
        displayName: next.user?.fullName,
      );
    } else if (prev?.isAuthenticated == true && !next.isAuthenticated) {
      await presence.goOffline();
      await CrashlyticsService.clearUser();
    }
  }, fireImmediately: true);

  ref.listen(currentFirebaseUidProvider, (prev, next) async {
    final auth = ref.read(authNotifierProvider);
    if (auth.isAuthenticated && next != null && next != prev) {
      await presence.goOnline(
        firebaseUid: next,
        backendUserId: auth.user?.id,
        displayName: auth.user?.fullName,
      );
      await CrashlyticsService.setUser(
        firebaseUid: next,
        backendUserId: auth.user?.id,
        email: auth.user?.email,
        role: auth.user?.role,
      );
    }
  });
});

final peerOnlineProvider =
    StreamProvider.autoDispose.family<bool, String>((ref, firebaseUid) {
  if (firebaseUid.isEmpty) return Stream<bool>.value(false);
  return ref.watch(presenceServiceProvider).watchOnline(firebaseUid);
});

/// Peer presence keyed by backend `AuthUser.id` (used in chat UI).
final peerOnlineByBackendIdProvider =
    StreamProvider.autoDispose.family<bool, String>((ref, backendUserId) {
  if (backendUserId.isEmpty) return Stream<bool>.value(false);
  return ref.watch(presenceServiceProvider).watchOnlineByBackendId(backendUserId);
});
