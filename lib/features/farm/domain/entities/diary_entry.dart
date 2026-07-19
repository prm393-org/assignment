import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class DiaryEntry extends Equatable {
  const DiaryEntry({
    required this.id,
    required this.seasonId,
    required this.farmId,
    required this.eventType,
    required this.eventDate,
    this.description,
  });

  final String id;
  final String seasonId;
  final String farmId;
  final String eventType;
  final String eventDate;
  final String? description;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: readString(json, ['id']),
        seasonId: readString(json, ['seasonId', 'season_id']),
        farmId: readString(json, ['farmId', 'farm_id']),
        eventType: readString(json, ['eventType', 'event_type']),
        eventDate: readString(json, ['eventDate', 'event_date']),
        description: readStringOrNull(json, ['description']),
      );

  @override
  List<Object?> get props => [id];
}

const diaryEventLabels = <String, String>{
  'land_prep': 'Làm đất',
  'sowing': 'Gieo trồng',
  'fertilizing': 'Bón phân',
  'pesticide': 'Phun thuốc',
  'irrigation': 'Tưới nước',
  'harvesting': 'Thu hoạch',
  'packing': 'Đóng gói',
  'other': 'Khác',
};
