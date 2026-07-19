import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';

Failure mapDioException(Object error) {
  if (error is! DioException) {
    return UnknownFailure(error.toString());
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? 0;
      final msg = _extractMessage(error.response?.data);
      if (status == 401 || status == 403) {
        return AuthFailure(msg ?? 'Không có quyền truy cập');
      }
      if (status >= 400 && status < 500) {
        return ValidationFailure(msg ?? 'Yêu cầu không hợp lệ');
      }
      return ServerFailure(msg ?? 'Lỗi máy chủ ($status)');
    default:
      return UnknownFailure(error.message ?? 'Đã xảy ra lỗi');
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map) {
    final message = data['message'] ?? data['error'] ?? data['msg'];
    if (message is String && message.isNotEmpty) return message;
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}
