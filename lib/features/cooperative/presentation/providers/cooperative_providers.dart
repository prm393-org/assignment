import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_providers.dart';
import 'package:chuoi_xanh_viet/features/cooperative/data/repositories/cooperative_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/cooperative/domain/entities/htx_item.dart';
import 'package:chuoi_xanh_viet/features/cooperative/domain/repositories/cooperative_repository.dart';

final cooperativeRepositoryProvider = Provider<CooperativeRepository>((ref) {
  return CooperativeRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(authRepositoryProvider),
  );
});

final htxListProvider =
    FutureProvider.autoDispose.family<List<HtxItem>, String?>((ref, search) {
  return ref.watch(cooperativeRepositoryProvider).listHtx(search: search);
});

final htxListForFarmProvider =
    FutureProvider.autoDispose.family<List<HtxItem>, String>((ref, farmId) {
  return ref.watch(cooperativeRepositoryProvider).listHtx(farmId: farmId);
});
