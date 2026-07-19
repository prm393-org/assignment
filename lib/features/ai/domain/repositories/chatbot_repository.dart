abstract class ChatbotRepository {
  Future<String> chat(String message, {List<Map<String, String>> history = const []});
  Future<String> market(String message, {String? crop, String? region});
  Future<String> diagnose({required String imagePath, String? note});
}
