import 'package:dio/dio.dart';

class VnProvince {
  const VnProvince({required this.code, required this.name});
  final int code;
  final String name;
}

class VnDistrict {
  const VnDistrict({required this.code, required this.name});
  final int code;
  final String name;
}

class VnWard {
  const VnWard({required this.code, required this.name});
  final int code;
  final String name;
}

class VietnamAddressApi {
  VietnamAddressApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://provinces.open-api.vn/api',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  Future<List<VnProvince>> getProvinces() async {
    final res = await _dio.get('/p/');
    final list = res.data is List ? res.data as List : const [];
    return list.whereType<Map>().map((e) {
      return VnProvince(
        code: int.tryParse('${e['code']}') ?? 0,
        name: '${e['name'] ?? ''}',
      );
    }).where((e) => e.code > 0).toList();
  }

  Future<List<VnDistrict>> getDistricts(int provinceCode) async {
    final res = await _dio.get('/p/$provinceCode', queryParameters: {
      'depth': 2,
    });
    final data = res.data is Map ? res.data as Map : const {};
    final districts = data['districts'] is List ? data['districts'] as List : const [];
    return districts.whereType<Map>().map((e) {
      return VnDistrict(
        code: int.tryParse('${e['code']}') ?? 0,
        name: '${e['name'] ?? ''}',
      );
    }).where((e) => e.code > 0).toList();
  }

  Future<List<VnWard>> getWards(int districtCode) async {
    final res = await _dio.get('/d/$districtCode', queryParameters: {
      'depth': 2,
    });
    final data = res.data is Map ? res.data as Map : const {};
    final wards = data['wards'] is List ? data['wards'] as List : const [];
    return wards.whereType<Map>().map((e) {
      return VnWard(
        code: int.tryParse('${e['code']}') ?? 0,
        name: '${e['name'] ?? ''}',
      );
    }).where((e) => e.code > 0).toList();
  }
}
