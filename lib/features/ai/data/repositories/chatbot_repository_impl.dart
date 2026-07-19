import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/config/api_config.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/ai/domain/repositories/chatbot_repository.dart';

class ChatbotRepositoryImpl implements ChatbotRepository {
  ChatbotRepositoryImpl(this._dio);
  final Dio _dio;

  Options get _aiOpts => Options(receiveTimeout: ApiConfig.aiTimeout);

  @override
  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await _dio.post(
        '/chatbot/chat',
        data: {'message': message, 'conversationHistory': history},
        options: _aiOpts,
      );
      final data = asMap(unwrapData(res.data));
      return readString(data, ['reply'], 'Không có phản hồi');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<String> market(
    String message, {
    String? crop,
    String? region,
  }) async {
    try {
      final res = await _dio.post(
        '/chatbot/market',
        data: {
          'message': message.trim(),
          if (crop != null && crop.isNotEmpty) 'crop': crop,
          if (region != null && region.isNotEmpty) 'region': region,
          'conversationHistory': <Map<String, String>>[],
        },
        options: _aiOpts,
      );
      final data = asMap(unwrapData(res.data));
      return readString(data, ['advice', 'message'], 'Không có tư vấn');
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<String> diagnose({required String imagePath, String? note}) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'plant.jpg'),
        if (note != null && note.isNotEmpty) 'note': note,
      });
      final res = await _dio.post(
        '/chatbot/diagnose',
        data: form,
        options: _aiOpts,
      );
      final data = asMap(unwrapData(res.data));
      return readString(data, ['diagnosis'], 'Không có chẩn đoán');
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
