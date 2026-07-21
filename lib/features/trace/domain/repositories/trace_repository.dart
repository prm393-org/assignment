import 'package:chuoi_xanh_viet/features/trace/domain/entities/trace_info.dart';

abstract class TraceRepository {
  Future<TraceSaleUnit> resolveByCode(String code, {bool isPublic = true});

  Future<TraceSeasonDetail> getSeasonDetail(
    String seasonId, {
    bool isPublic = true,
  });

  Future<TraceVerifyResult> verifySeason(
    String seasonId, {
    bool isPublic = true,
  });
}
