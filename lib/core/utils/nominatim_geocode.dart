import 'package:dio/dio.dart';

class GeocodeResult {
  const GeocodeResult({
    required this.latitude,
    required this.longitude,
    this.displayName,
  });

  final double latitude;
  final double longitude;
  final String? displayName;
}

class NominatimGeocode {
  NominatimGeocode({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://nominatim.openstreetmap.org',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'ChuoiXanhViet/1.0 (flutter-mobile)',
                },
              ),
            );

  final Dio _dio;

  Future<GeocodeResult?> search(String query) async {
    if (query.trim().isEmpty) return null;
    final res = await _dio.get('/search', queryParameters: {
      'q': query,
      'format': 'json',
      'limit': 1,
      'countrycodes': 'vn',
    });
    final list = res.data is List ? res.data as List : const [];
    if (list.isEmpty || list.first is! Map) return null;
    final m = list.first as Map;
    final lat = double.tryParse('${m['lat']}');
    final lon = double.tryParse('${m['lon']}');
    if (lat == null || lon == null) return null;
    return GeocodeResult(
      latitude: lat,
      longitude: lon,
      displayName: m['display_name']?.toString(),
    );
  }

  Future<GeocodeResult?> reverse(double lat, double lng) async {
    final res = await _dio.get('/reverse', queryParameters: {
      'lat': lat,
      'lon': lng,
      'format': 'json',
    });
    if (res.data is! Map) return null;
    final m = res.data as Map;
    return GeocodeResult(
      latitude: lat,
      longitude: lng,
      displayName: m['display_name']?.toString(),
    );
  }
}
