import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/network/dio_client.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/certificate/data/repositories/certificate_repository_impl.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/entities/farm_certificate.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/repositories/certificate_repository.dart';

final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepositoryImpl(ref.watch(dioProvider));
});

final myCertificatesProvider =
    FutureProvider.autoDispose<PaginatedResult<FarmCertificate>>((ref) {
  return ref.watch(certificateRepositoryProvider).listMine();
});

final pendingAdminCertificatesProvider =
    FutureProvider.autoDispose<PaginatedResult<FarmCertificate>>((ref) {
  return ref.watch(certificateRepositoryProvider).listPendingAdmin();
});
