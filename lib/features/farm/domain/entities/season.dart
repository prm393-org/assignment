import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class Season extends Equatable {
  const Season({
    required this.id,
    required this.farmId,
    required this.code,
    required this.cropName,
    required this.status,
    this.startDate,
    this.harvestStartDate,
    this.harvestEndDate,
    this.estimatedYield,
    this.actualYield,
    this.yieldUnit,
  });

  final String id;
  final String farmId;
  final String code;
  final String cropName;
  final String status;
  final String? startDate;
  final String? harvestStartDate;
  final String? harvestEndDate;
  final double? estimatedYield;
  final double? actualYield;
  final String? yieldUnit;

  factory Season.fromJson(Map<String, dynamic> json) => Season(
        id: readString(json, ['id']),
        farmId: readString(json, ['farmId', 'farm_id']),
        code: readString(json, ['code']),
        cropName: readString(json, ['cropName', 'crop_name']),
        status: readString(json, ['status'], 'planning'),
        startDate: readStringOrNull(json, ['startDate', 'start_date']),
        harvestStartDate:
            readStringOrNull(json, ['harvestStartDate', 'harvest_start_date']),
        harvestEndDate:
            readStringOrNull(json, ['harvestEndDate', 'harvest_end_date']),
        estimatedYield:
            readNum(json, ['estimatedYield', 'estimated_yield'])?.toDouble(),
        actualYield: readNum(json, ['actualYield', 'actual_yield'])?.toDouble(),
        yieldUnit: readStringOrNull(json, ['yieldUnit', 'yield_unit']),
      );

  @override
  List<Object?> get props => [id];
}
