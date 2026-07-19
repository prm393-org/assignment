import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/chat_message.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/entities/conversation.dart';
import 'package:chuoi_xanh_viet/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<Conversation>> listConversations() async {
    try {
      final res = await _dio.get('/chat/conversations');
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, Conversation.fromJson);
      return PaginatedResult.fromJson(data, Conversation.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Conversation> openConversation(String peerUserId) async {
    try {
      final res = await _dio.post('/chat/conversations', data: {
        'peerUserId': peerUserId,
        'peer_user_id': peerUserId,
      });
      return Conversation.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<List<ChatMessage>> listMessages(String conversationId) async {
    try {
      final res = await _dio.get('/chat/conversations/$conversationId/messages');
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, ChatMessage.fromJson);
      return PaginatedResult.fromJson(data, ChatMessage.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String content) async {
    try {
      final res = await _dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {'content': content, 'message': content},
      );
      return ChatMessage.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
