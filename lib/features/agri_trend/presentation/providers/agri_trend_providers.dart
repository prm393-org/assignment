import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/data/repositories/agri_trend_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/domain/entities/agri_trend.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/domain/repositories/agri_trend_repository.dart';

final agriTrendRepositoryProvider = Provider<AgriTrendRepository>((ref) {
  return AgriTrendRepositoryImpl(ref.watch(dioProvider));
});

final agriTrendProvider = FutureProvider.autoDispose<AgriTrend>((ref) {
  return ref.watch(agriTrendRepositoryProvider).getTrend();
});
