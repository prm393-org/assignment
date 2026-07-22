import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    this.peerUserId,
    this.peerName,
    this.peerAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.participant1UserId,
    this.participant2UserId,
    this.participant1Name,
    this.participant2Name,
    this.participant1AvatarUrl,
    this.participant2AvatarUrl,
  });

  final String id;
  final String? peerUserId;
  final String? peerName;
  final String? peerAvatarUrl;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final String? participant1UserId;
  final String? participant2UserId;
  final String? participant1Name;
  final String? participant2Name;
  final String? participant1AvatarUrl;
  final String? participant2AvatarUrl;

  /// Picks the other participant when API returns participant1/participant2.
  Conversation resolvedFor(String? currentUserId) {
    if (peerName != null && peerName!.trim().isNotEmpty) return this;
    if (currentUserId == null || currentUserId.isEmpty) {
      return _withPeer(
        peerUserId: participant1UserId ?? participant2UserId,
        peerName: participant1Name ?? participant2Name,
        peerAvatarUrl: participant1AvatarUrl ?? participant2AvatarUrl,
      );
    }
    final iAmP1 = participant1UserId == currentUserId;
    if (iAmP1) {
      return _withPeer(
        peerUserId: participant2UserId,
        peerName: participant2Name,
        peerAvatarUrl: participant2AvatarUrl,
      );
    }
    final iAmP2 = participant2UserId == currentUserId;
    if (iAmP2) {
      return _withPeer(
        peerUserId: participant1UserId,
        peerName: participant1Name,
        peerAvatarUrl: participant1AvatarUrl,
      );
    }
    return _withPeer(
      peerUserId: participant1UserId ?? participant2UserId,
      peerName: participant1Name ?? participant2Name,
      peerAvatarUrl: participant1AvatarUrl ?? participant2AvatarUrl,
    );
  }

  Conversation _withPeer({
    String? peerUserId,
    String? peerName,
    String? peerAvatarUrl,
  }) {
    return Conversation(
      id: id,
      peerUserId: peerUserId ?? this.peerUserId,
      peerName: peerName ?? this.peerName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      participant1UserId: participant1UserId,
      participant2UserId: participant2UserId,
      participant1Name: participant1Name,
      participant2Name: participant2Name,
      participant1AvatarUrl: participant1AvatarUrl,
      participant2AvatarUrl: participant2AvatarUrl,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final peer = asMap(
      json['peer'] ??
          json['peerUser'] ??
          json['peer_user'] ??
          json['otherUser'] ??
          json['other_user'],
    );
    final p1 = asMap(json['participant1'] ?? json['participant_1']);
    final p2 = asMap(json['participant2'] ?? json['participant_2']);
    final last = asMap(json['lastMessage'] ?? json['last_message']);

    String? nameOf(Map<String, dynamic> p) => readStringOrNull(p, [
          'fullName',
          'full_name',
          'name',
        ]);
    String? avatarOf(Map<String, dynamic> p) => resolveMediaUrl(
          readStringOrNull(p, ['avatarUrl', 'avatar_url', 'avatar']),
        );
    String? idOf(Map<String, dynamic> p, List<String> rootKeys) {
      final fromNested = readStringOrNull(p, ['id', 'userId', 'user_id']);
      if (fromNested != null) return fromNested;
      return readStringOrNull(json, rootKeys);
    }

    return Conversation(
      id: readString(json, ['id']),
      peerUserId: readStringOrNull(peer.isNotEmpty ? peer : json, [
        'peerUserId',
        'peer_user_id',
        'userId',
        'user_id',
        if (peer.isNotEmpty) 'id',
      ]),
      peerName: readStringOrNull(peer.isNotEmpty ? peer : const {}, [
        'fullName',
        'full_name',
        'peerName',
        'peer_name',
        'name',
      ]),
      peerAvatarUrl: resolveMediaUrl(
        readStringOrNull(peer.isNotEmpty ? peer : const {}, [
          'avatarUrl',
          'avatar_url',
          'avatar',
          'peerAvatarUrl',
          'peer_avatar_url',
        ]),
      ),
      lastMessage: readStringOrNull(
        last.isNotEmpty ? last : json,
        [
          'content',
          'message',
          'lastMessage',
          'last_message',
          'lastMessagePreview',
          'last_message_preview',
          'text',
        ],
      ),
      lastMessageAt: readStringOrNull(
        last.isNotEmpty ? last : json,
        [
          'createdAt',
          'created_at',
          'lastMessageAt',
          'last_message_at',
          'updatedAt',
          'updated_at',
        ],
      ),
      unreadCount: readInt(json, ['unreadCount', 'unread_count']),
      participant1UserId: idOf(p1, ['participant1UserId', 'participant1_user_id']),
      participant2UserId: idOf(p2, ['participant2UserId', 'participant2_user_id']),
      participant1Name: nameOf(p1),
      participant2Name: nameOf(p2),
      participant1AvatarUrl: avatarOf(p1),
      participant2AvatarUrl: avatarOf(p2),
    );
  }

  @override
  List<Object?> get props => [id];
}
