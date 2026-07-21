import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

/// A diary entry created while offline, queued locally until `createDiary`
/// can be retried. The image (if any) is already uploaded by the time this
/// is queued — `diary_dashboard_screen.dart` uploads eagerly on picking,
/// before the diary entry itself is ever submitted — so the queue only
/// needs to remember the resulting URL, not a local file path.
class PendingDiaryEntry extends Equatable {
  const PendingDiaryEntry({
    required this.localId,
    required this.farmId,
    required this.seasonId,
    required this.eventType,
    required this.eventDate,
    this.description,
    this.imageUrl,
  });

  final String localId;
  final String farmId;
  final String seasonId;
  final String eventType;
  final String eventDate;
  final String? description;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'farmId': farmId,
        'seasonId': seasonId,
        'eventType': eventType,
        'eventDate': eventDate,
        'description': description,
        'imageUrl': imageUrl,
      };

  factory PendingDiaryEntry.fromJson(Map<String, dynamic> json) =>
      PendingDiaryEntry(
        localId: readString(json, ['localId']),
        farmId: readString(json, ['farmId']),
        seasonId: readString(json, ['seasonId']),
        eventType: readString(json, ['eventType']),
        eventDate: readString(json, ['eventDate']),
        description: readStringOrNull(json, ['description']),
        imageUrl: readStringOrNull(json, ['imageUrl']),
      );

  @override
  List<Object?> get props => [localId];
}
