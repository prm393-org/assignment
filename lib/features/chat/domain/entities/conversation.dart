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
  });

  final String id;
  final String? peerUserId;
  final String? peerName;
  final String? peerAvatarUrl;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final peer = asMap(
      json['peer'] ??
          json['peerUser'] ??
          json['peer_user'] ??
          json['otherUser'] ??
          json['other_user'],
    );
    final last = asMap(json['lastMessage'] ?? json['last_message']);
    return Conversation(
      id: readString(json, ['id']),
      peerUserId: readStringOrNull(peer.isNotEmpty ? peer : json, [
        'peerUserId',
        'peer_user_id',
        'userId',
        'user_id',
        'id',
      ]),
      peerName: readStringOrNull(peer.isNotEmpty ? peer : json, [
        'fullName',
        'full_name',
        'peerName',
        'peer_name',
        'name',
      ]),
      peerAvatarUrl: resolveMediaUrl(
        readStringOrNull(peer.isNotEmpty ? peer : json, [
          'avatarUrl',
          'avatar_url',
          'avatar',
          'peerAvatarUrl',
          'peer_avatar_url',
        ]),
      ),
      lastMessage: readStringOrNull(
        last.isNotEmpty ? last : json,
        ['content', 'message', 'lastMessage', 'last_message', 'text'],
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
    );
  }

  @override
  List<Object?> get props => [id];
}
