import 'dart:async';

import 'package:dio/dio.dart';
import 'package:chuoi_xanh_viet/core/error/exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/firebase/fcm_topics.dart';
import 'package:chuoi_xanh_viet/core/firebase/push_sender.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/entities/farm_certificate.dart';
import 'package:chuoi_xanh_viet/features/certificate/domain/repositories/certificate_repository.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  CertificateRepositoryImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<FarmCertificate>> listMine({int page = 1}) async {
    try {
      final res = await _dio.get('/certificate/farm/mine', queryParameters: {
        'page': page,
        'limit': 20,
      });
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        FarmCertificate.fromJson,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FarmCertificate> create(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/certificate/farm', data: body);
      return FarmCertificate.fromJson(asMap(unwrapData(res.data)));
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<PaginatedResult<FarmCertificate>> listPendingAdmin({
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        '/certificate/farm/pending/admin',
        queryParameters: {'page': page, 'limit': 20},
      );
      return PaginatedResult.fromJson(
        unwrapData(res.data),
        FarmCertificate.fromJson,
      );
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FarmCertificate> approve(String id) async {
    try {
      final res = await _dio.post('/certificate/farm/$id/approve', data: {});
      final cert = FarmCertificate.fromJson(asMap(unwrapData(res.data)));
      // Push approval to the owning farm (farmer subscribed to farm_<id>).
      unawaited(PushSender.sendToTopic(
        topic: FcmTopics.farm(cert.farmId),
        title: 'Chứng nhận được duyệt',
        body: cert.farmName != null
            ? 'Chứng nhận cho ${cert.farmName} đã được duyệt.'
            : 'Chứng nhận của bạn đã được duyệt.',
        link: '/farmer/certificates',
      ));
      return cert;
    } catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<FarmCertificate> reject(String id, String reason) async {
    try {
      final res = await _dio.post(
        '/certificate/farm/$id/reject',
        data: {'reason': reason},
      );
      final cert = FarmCertificate.fromJson(asMap(unwrapData(res.data)));
      unawaited(PushSender.sendToTopic(
        topic: FcmTopics.farm(cert.farmId),
        title: 'Chứng nhận bị từ chối',
        body: reason.isNotEmpty
            ? 'Lý do: $reason'
            : 'Chứng nhận của bạn đã bị từ chối.',
        link: '/farmer/certificates',
      ));
      return cert;
    } catch (e) {
      throw mapDioException(e);
    }
  }
}
