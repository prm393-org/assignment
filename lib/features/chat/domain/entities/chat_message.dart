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
    final sender = asMap(json['sender'] ?? json['users'] ?? json['user']);
    return ChatMessage(
      id: readString(json, ['id']),
      conversationId: readString(json, [
        'conversationId',
        'conversation_id',
      ]),
      senderId: readString(
        sender.isNotEmpty ? sender : json,
        ['senderId', 'sender_id', 'userId', 'user_id', 'id'],
      ),
      content: readString(json, ['content', 'message', 'text']),
      createdAt: readStringOrNull(json, ['createdAt', 'created_at']),
    );
  }

  @override
  List<Object?> get props => [id];
}
