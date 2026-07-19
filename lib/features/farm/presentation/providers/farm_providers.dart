import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/farm/data/repositories/farm_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/season.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/repositories/farm_repository.dart';

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepositoryImpl(ref.watch(dioProvider));
});

final myFarmsProvider = FutureProvider.autoDispose<List<Farm>>((ref) {
  return ref.watch(farmRepositoryProvider).getMyFarms();
});

final farmSeasonsProvider =
    FutureProvider.autoDispose.family<List<Season>, String>((ref, farmId) {
  return ref.watch(farmRepositoryProvider).getSeasons(farmId);
});

final seasonDetailProvider =
    FutureProvider.autoDispose.family<Season, String>((ref, id) {
  return ref.watch(farmRepositoryProvider).getSeasonById(id);
});

final seasonDiariesProvider = FutureProvider.autoDispose
    .family<PaginatedResult<DiaryEntry>, String>((ref, seasonId) {
  return ref.watch(farmRepositoryProvider).getDiaries(seasonId: seasonId);
});

final farmDiariesProvider = FutureProvider.autoDispose
    .family<PaginatedResult<DiaryEntry>, String>((ref, farmId) {
  return ref.watch(farmRepositoryProvider).getDiaries(farmId: farmId);
});
