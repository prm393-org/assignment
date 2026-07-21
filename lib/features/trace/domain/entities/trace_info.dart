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

class TraceAnchor extends Equatable {
  const TraceAnchor({
    required this.id,
    this.checkpointNo,
    this.checkpointType,
    this.txHash,
    this.txUrl,
    this.status,
    this.anchoredAt,
  });

  final String id;
  final int? checkpointNo;
  final String? checkpointType;
  final String? txHash;
  final String? txUrl;
  final String? status;
  final String? anchoredAt;

  factory TraceAnchor.fromJson(Map<String, dynamic> json) => TraceAnchor(
        id: readString(json, ['id']),
        checkpointNo: readNum(json, ['checkpointNo', 'checkpoint_no'])?.toInt(),
        checkpointType:
            readStringOrNull(json, ['checkpointType', 'checkpoint_type']),
        txHash: readStringOrNull(json, ['txHash', 'tx_hash']),
        txUrl: readStringOrNull(json, ['txUrl', 'tx_url']),
        status: readStringOrNull(json, ['status']),
        anchoredAt: readStringOrNull(json, ['anchoredAt', 'anchored_at']),
      );

  @override
  List<Object?> get props => [id];
}

class TraceVerifyResult extends Equatable {
  const TraceVerifyResult({
    required this.match,
    this.currentHash,
    this.onChainHash,
    this.anchor,
  });

  final bool match;
  final String? currentHash;
  final String? onChainHash;
  final TraceAnchor? anchor;

  factory TraceVerifyResult.fromJson(Map<String, dynamic> json) {
    final anchor = asMap(json['anchor']);
    return TraceVerifyResult(
      match: readBool(json, ['match']),
      currentHash: readStringOrNull(json, ['currentHash', 'current_hash']),
      onChainHash: readStringOrNull(json, ['onChainHash', 'on_chain_hash']),
      anchor: anchor.isEmpty ? null : TraceAnchor.fromJson(anchor),
    );
  }

  @override
  List<Object?> get props => [match, currentHash, onChainHash];
}

class TraceSeasonDetail extends Equatable {
  const TraceSeasonDetail({
    required this.seasonId,
    required this.seasonCode,
    required this.cropName,
    required this.farmName,
    this.ownerName,
    this.province,
    this.district,
    this.address,
    this.latitude,
    this.longitude,
    this.status,
    this.diaries = const [],
    this.anchors = const [],
  });

  final String seasonId;
  final String seasonCode;
  final String cropName;
  final String farmName;
  final String? ownerName;
  final String? province;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? status;
  final List<Map<String, String>> diaries;
  final List<TraceAnchor> anchors;

  bool get hasGeo =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  String? get mapQuery {
    final parts = [address, district, province]
        .whereType<String>()
        .where((e) => e.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  factory TraceSeasonDetail.fromJson(Map<String, dynamic> json) {
    final season = asMap(json['season']);
    final farm = asMap(json['farm']);
    final owner = asMap(json['owner']);
    final diariesRaw = asList(json['diaries']);
    final anchorsRaw = asList(json['anchors']);
    return TraceSeasonDetail(
      seasonId: readString(season, ['id']),
      seasonCode: readString(season, ['code']),
      cropName: readString(season, ['cropName', 'crop_name']),
      farmName: readString(farm, ['name']),
      ownerName: readStringOrNull(owner, ['fullName', 'full_name']),
      province: readStringOrNull(farm, ['province']),
      district: readStringOrNull(farm, ['district']),
      address: readStringOrNull(farm, ['address']),
      latitude: readNum(farm, ['latitude'])?.toDouble(),
      longitude: readNum(farm, ['longitude'])?.toDouble(),
      status: readStringOrNull(season, ['status']),
      diaries: diariesRaw.whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'eventType': readString(m, ['eventType', 'event_type']),
          'eventDate': readString(m, ['eventDate', 'event_date']),
          'description': readString(m, ['description']),
        };
      }).toList(),
      anchors: anchorsRaw
          .whereType<Map>()
          .map((e) => TraceAnchor.fromJson(asMap(e)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [seasonId, seasonCode, farmName];
}
