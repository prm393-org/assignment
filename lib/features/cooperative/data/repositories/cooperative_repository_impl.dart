import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/network/auth_token_holder.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_user.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/repositories/auth_repository.dart';
import 'package:chuoi_xanh_viet/features/cooperative/domain/entities/htx_item.dart';
import 'package:chuoi_xanh_viet/features/cooperative/domain/repositories/cooperative_repository.dart';

class CooperativeRepositoryImpl implements CooperativeRepository {
  CooperativeRepositoryImpl(this._dio, this._authRepo);

  final Dio _dio;
  final AuthRepository _authRepo;

  @override
  Future<List<HtxItem>> listHtx({String? search, String? farmId}) async {
    try {
      final res = await _dio.get(
        '/cooperative/htx',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (farmId != null && farmId.isNotEmpty) 'farmId': farmId,
        },
      );
      final data = unwrapData(res.data);
      if (data is List) return mapList(data, HtxItem.fromJson);
      return PaginatedResult.fromJson(data, HtxItem.fromJson).items;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<AuthSession> registerFarmerApplicant({
    required String cooperativeUserId,
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    required String farmName,
  }) async {
    try {
      final res = await _dio.post(
        '/cooperative/register-farmer-applicant',
        data: {
          'cooperative_user_id': cooperativeUserId,
          'cooperativeUserId': cooperativeUserId,
          'email': email,
          'full_name': fullName,
          'fullName': fullName,
          'phone': phone,
          'password': password,
          'confirm_password': confirmPassword,
          'confirmPassword': confirmPassword,
          'farm_name': farmName,
          'farmName': farmName,
        },
      );
      final session = _parseSession(asMap(res.data));
      await _authRepo.persistSession(session);
      return session;
    } catch (e) {
      if (e is Failure) rethrow;
      throw mapDioException(e);
    }
  }

  @override
  Future<void> requestJoin({
    required String cooperativeUserId,
    required String farmId,
  }) async {
    try {
      await _dio.post('/cooperative/join-request', data: {
        'cooperative_user_id': cooperativeUserId,
        'cooperativeUserId': cooperativeUserId,
        'farm_id': farmId,
        'farmId': farmId,
      });
    } catch (e) {
      throw mapDioException(e);
    }
  }

  AuthSession _parseSession(Map<String, dynamic> body) {
    final data = body.containsKey('data') ? asMap(body['data']) : body;
    final token = readStringOrNull(
          data,
          ['accessToken', 'access_token', 'token'],
        ) ??
        readStringOrNull(body, ['accessToken', 'access_token', 'token']);
    final rawUser = asMap(data['user'] ?? body['user'] ?? data['profile']);
    if (token == null || token.isEmpty || rawUser.isEmpty) {
      throw const AuthFailure('Không nhận được token từ server');
    }
    authTokenHolder.accessToken = token;
    return AuthSession(
      accessToken: token,
      user: AuthUser.fromJson(rawUser),
    );
  }
}
