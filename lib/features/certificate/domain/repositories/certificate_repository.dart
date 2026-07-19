import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/entities/farm_certificate.dart';

abstract class CertificateRepository {
  Future<PaginatedResult<FarmCertificate>> listMine({int page = 1});
  Future<FarmCertificate> create(Map<String, dynamic> body);
  Future<PaginatedResult<FarmCertificate>> listPendingAdmin({int page = 1});
  Future<FarmCertificate> approve(String id);
  Future<FarmCertificate> reject(String id, String reason);
}
