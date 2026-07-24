import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/config/push_config.dart';

/// Fires an FCM push through the relay worker (see `push-worker/`).
///
/// Topic-only by design: the worker sends an FCM message to [topic]. This is
/// **best-effort** — a disabled or failing relay must never break the
/// business action that triggered it, so every path swallows errors and
/// returns. Uses its own [Dio] (no auth interceptor: the relay is public and
/// guarded by its own shared secret, not the backend bearer token).
abstract final class PushSender {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  static Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
    String? link,
    Map<String, String>? data,
  }) async {
    if (!PushConfig.isConfigured || topic.isEmpty) return;
    try {
      await _dio.post(
        PushConfig.endpoint,
        options: Options(
          headers: {
            'content-type': 'application/json',
            if (PushConfig.apiKey.isNotEmpty) 'x-push-key': PushConfig.apiKey,
          },
        ),
        data: {
          'topic': topic,
          'title': title,
          'body': body,
          if (link != null && link.isNotEmpty) 'link': link,
          if (data != null && data.isNotEmpty) 'data': data,
        },
      );
    } catch (_) {
      // Best-effort: never surface relay failures to the caller.
    }
  }
}
