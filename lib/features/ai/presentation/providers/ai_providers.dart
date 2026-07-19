import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/ai/data/repositories/chatbot_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/ai/domain/repositories/chatbot_repository.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepositoryImpl(ref.watch(dioProvider));
});
