import 'package:chuoi_xanh_viet/features/auth/domain/repositories/auth_repository.dart';
import 'package:chuoi_xanh_viet/features/cooperative/domain/entities/htx_item.dart';

abstract class CooperativeRepository {
  Future<List<HtxItem>> listHtx({String? search, String? farmId});

  Future<AuthSession> registerFarmerApplicant({
    required String cooperativeUserId,
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    required String farmName,
  });

  Future<void> requestJoin({
    required String cooperativeUserId,
    required String farmId,
  });
}
