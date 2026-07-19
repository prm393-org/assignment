import 'package:chuoi_xanh_viet/features/chat/domain/entities/chat_message.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/conversation.dart';

abstract class ChatRepository {
  Future<List<Conversation>> listConversations();
  Future<Conversation> openConversation(String peerUserId);
  Future<List<ChatMessage>> listMessages(String conversationId);
  Future<ChatMessage> sendMessage(String conversationId, String content);
}
