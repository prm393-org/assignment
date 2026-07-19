import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/trace/data/repositories/trace_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/trace/domain/repositories/trace_repository.dart';

final traceRepositoryProvider = Provider<TraceRepository>((ref) {
  return TraceRepositoryImpl(ref.watch(dioProvider));
});
