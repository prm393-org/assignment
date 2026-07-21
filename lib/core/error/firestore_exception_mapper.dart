import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';

Failure mapFirestoreException(Object error) {
  if (error is! FirebaseException) {
    return UnknownFailure(error.toString());
  }

  switch (error.code) {
    case 'permission-denied':
      return const AuthFailure('Bạn không có quyền thực hiện thao tác này');
    case 'unavailable':
    case 'deadline-exceeded':
      return const NetworkFailure();
    default:
      return UnknownFailure(error.message ?? 'Đã xảy ra lỗi');
  }
}
