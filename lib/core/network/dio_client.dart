import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/config/api_config.dart';
import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
import 'package:chuoi_xanh_viet/core/network/auth_token_holder.dart';

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
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authTokenHolder.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
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
