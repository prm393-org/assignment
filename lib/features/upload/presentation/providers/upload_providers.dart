import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/upload/data/repositories/upload_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/upload/domain/repositories/upload_repository.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepositoryImpl(ref.watch(dioProvider));
});
