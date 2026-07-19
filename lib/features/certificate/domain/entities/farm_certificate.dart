import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class FarmCertificate extends Equatable {
  const FarmCertificate({
    required this.id,
    required this.farmId,
    required this.type,
    required this.status,
    required this.fileUrl,
    this.certificateNo,
    this.issuer,
    this.issuedAt,
    this.expiresAt,
    this.farmName,
    this.reviewerNote,
  });

  final String id;
  final String farmId;
  final String type;
  final String status;
  final String fileUrl;
  final String? certificateNo;
  final String? issuer;
  final String? issuedAt;
  final String? expiresAt;
  final String? farmName;
  final String? reviewerNote;

  factory FarmCertificate.fromJson(Map<String, dynamic> json) {
    final farm = asMap(json['farm'] ?? json['farms']);
    return FarmCertificate(
      id: readString(json, ['id']),
      farmId: readString(json, ['farmId', 'farm_id']),
      type: readString(json, ['type']),
      status: readString(json, ['status']),
      fileUrl: readString(json, ['fileUrl', 'file_url']),
      certificateNo: readStringOrNull(json, ['certificateNo', 'certificate_no']),
      issuer: readStringOrNull(json, ['issuer']),
      issuedAt: readStringOrNull(json, ['issuedAt', 'issued_at']),
      expiresAt: readStringOrNull(json, ['expiresAt', 'expires_at']),
      farmName: readStringOrNull(farm, ['name']),
      reviewerNote: readStringOrNull(json, ['reviewerNote', 'reviewer_note', 'reject_reason']),
    );
  }

  @override
  List<Object?> get props => [id, status];
}
