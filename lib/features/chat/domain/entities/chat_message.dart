import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Prefer top-level sender ids (API uses senderUserId). Nested sender/user
    // objects are fallback only — never treat the message `id` as senderId.
    final nested = asMap(json['sender'] ?? json['users'] ?? json['user']);
    final senderId = readString(json, [
      'senderUserId',
      'sender_user_id',
      'senderId',
      'sender_id',
      'userId',
      'user_id',
    ]);
    final nestedSenderId = nested.isEmpty
        ? ''
        : readString(nested, [
            'senderUserId',
            'sender_user_id',
            'senderId',
            'sender_id',
            'userId',
            'user_id',
            'id',
          ]);
    // Plain string sender field (rare).
    final stringSender = json['sender'] is String ? '${json['sender']}' : '';

    return ChatMessage(
      id: readString(json, ['id']),
      conversationId: readString(json, [
        'conversationId',
        'conversation_id',
      ]),
      senderId: senderId.isNotEmpty
          ? senderId
          : (nestedSenderId.isNotEmpty
              ? nestedSenderId
              : stringSender),
      content: readString(json, ['content', 'message', 'text']),
      createdAt: readStringOrNull(json, ['createdAt', 'created_at']),
    );
  }

  @override
  List<Object?> get props => [id];
}
