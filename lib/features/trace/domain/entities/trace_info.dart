import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class TraceSaleUnit extends Equatable {
  const TraceSaleUnit({
    required this.id,
    required this.seasonId,
    required this.code,
    this.quantity,
    this.unit,
    this.shortCode,
    this.qrUrl,
    this.status,
  });

  final String id;
  final String seasonId;
  final String code;
  final String? quantity;
  final String? unit;
  final String? shortCode;
  final String? qrUrl;
  final String? status;

  factory TraceSaleUnit.fromJson(Map<String, dynamic> json) => TraceSaleUnit(
        id: readString(json, ['id']),
        seasonId: readString(json, ['seasonId', 'season_id']),
        code: readString(json, ['code']),
        quantity: readStringOrNull(json, ['quantity']),
        unit: readStringOrNull(json, ['unit']),
        shortCode: readStringOrNull(json, ['shortCode', 'short_code']),
        qrUrl: readStringOrNull(json, ['qrUrl', 'qr_url']),
        status: readStringOrNull(json, ['status']),
      );

  @override
  List<Object?> get props => [id];
}

class TraceSeasonDetail extends Equatable {
  const TraceSeasonDetail({
    required this.seasonCode,
    required this.cropName,
    required this.farmName,
    this.ownerName,
    this.province,
    this.status,
    this.diaries = const [],
  });

  final String seasonCode;
  final String cropName;
  final String farmName;
  final String? ownerName;
  final String? province;
  final String? status;
  final List<Map<String, String>> diaries;

  factory TraceSeasonDetail.fromJson(Map<String, dynamic> json) {
    final season = asMap(json['season']);
    final farm = asMap(json['farm']);
    final owner = asMap(json['owner']);
    final diariesRaw = asList(json['diaries']);
    return TraceSeasonDetail(
      seasonCode: readString(season, ['code']),
      cropName: readString(season, ['cropName', 'crop_name']),
      farmName: readString(farm, ['name']),
      ownerName: readStringOrNull(owner, ['fullName', 'full_name']),
      province: readStringOrNull(farm, ['province']),
      status: readStringOrNull(season, ['status']),
      diaries: diariesRaw.whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'eventType': readString(m, ['eventType', 'event_type']),
          'eventDate': readString(m, ['eventDate', 'event_date']),
          'description': readString(m, ['description']),
        };
      }).toList(),
    );
  }

  @override
  List<Object?> get props => [seasonCode, farmName];
}
