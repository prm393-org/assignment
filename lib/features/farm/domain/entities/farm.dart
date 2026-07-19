import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class Farm extends Equatable {
  const Farm({
    required this.id,
    required this.name,
    required this.areaHa,
    required this.cropMain,
    required this.province,
    required this.district,
    required this.ward,
    this.address,
    this.latitude,
    this.longitude,
    this.inCooperative = false,
    this.provinceCode,
    this.districtCode,
    this.wardCode,
  });

  final String id;
  final String name;
  final double areaHa;
  final String cropMain;
  final String province;
  final String district;
  final String ward;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool inCooperative;
  final int? provinceCode;
  final int? districtCode;
  final int? wardCode;

  factory Farm.fromJson(Map<String, dynamic> json) => Farm(
        id: readString(json, ['id']),
        name: readString(json, ['name']),
        areaHa: readDouble(json, ['areaHa', 'area_ha']),
        cropMain: readString(json, ['cropMain', 'crop_main']),
        province: readString(json, ['province']),
        district: readString(json, ['district']),
        ward: readString(json, ['ward']),
        address: readStringOrNull(json, ['address']),
        latitude: readNum(json, ['latitude'])?.toDouble(),
        longitude: readNum(json, ['longitude'])?.toDouble(),
        inCooperative: readBool(json, ['inCooperative', 'in_cooperative']),
        provinceCode: readNum(json, ['provinceCode', 'province_code'])?.toInt(),
        districtCode: readNum(json, ['districtCode', 'district_code'])?.toInt(),
        wardCode: readNum(json, ['wardCode', 'ward_code'])?.toInt(),
      );

  String get locationLabel => [ward, district, province]
      .where((e) => e.isNotEmpty)
      .join(', ');

  @override
  List<Object?> get props => [id];
}
