import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/config/api_config.dart';
import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
import 'package:chuoi_xanh_viet/core/network/auth_session_coordinator.dart';
import 'package:chuoi_xanh_viet/core/network/auth_token_holder.dart';
import 'package:chuoi_xanh_viet/core/network/jwt_utils.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authTokenHolder.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final msg = _responseMessage(error.response?.data);
        final path = error.requestOptions.path;
        final isAuthEndpoint = path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/forgot-password') ||
            path.contains('/auth/reset-password') ||
            path.contains('/auth/verify-forgot-password');
        final alreadyRetried =
            error.requestOptions.extra['auth_retried'] == true;
        final expired = status == 401 || looksLikeAuthExpiredMessage(msg);

        if (expired && !alreadyRetried && !isAuthEndpoint) {
          final newToken =
              await authSessionCoordinator.refreshAccessToken();
          if (newToken != null && newToken.isNotEmpty) {
            final req = error.requestOptions;
            req.headers['Authorization'] = 'Bearer $newToken';
            req.extra['auth_retried'] = true;
            try {
              final response = await dio.fetch(req);
              return handler.resolve(response);
            } catch (_) {
              // Fall through to expire session.
            }
          }
          await authSessionCoordinator.notifyExpired();
        }

        // Auth 401 is expected on expired sessions — skip noise.
        if (status != 401) {
          // ignore: discarded_futures
          CrashlyticsService.recordNonFatal(
            error,
            error.stackTrace,
            reason: 'api_fail ${error.requestOptions.method} '
                '${error.requestOptions.path} status=$status',
            keys: {
              'api_path': error.requestOptions.path,
              'api_method': error.requestOptions.method,
              'api_status': ?status,
            },
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

String? _responseMessage(dynamic data) {
  if (data is Map) {
    final message = data['message'] ?? data['error'] ?? data['msg'];
    if (message is String && message.isNotEmpty) return message;
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}
