T unwrapData<T>(dynamic body) {
  if (body is Map && body.containsKey('data') && body['data'] != null) {
    return body['data'] as T;
  }
  return body as T;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String readString(Map<String, dynamic> json, List<String> keys, [String fallback = '']) {
  for (final key in keys) {
    final v = json[key];
    if (v != null && '$v'.isNotEmpty) return '$v';
  }
  return fallback;
}

String? readStringOrNull(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final v = json[key];
    if (v == null) continue;
    final s = '$v';
    if (s.isEmpty) return null;
    return s;
  }
  return null;
}

num? readNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final v = json[key];
    if (v == null) continue;
    if (v is num) return v;
    return num.tryParse('$v');
  }
  return null;
}

double readDouble(Map<String, dynamic> json, List<String> keys, [double fallback = 0]) {
  return readNum(json, keys)?.toDouble() ?? fallback;
}

int readInt(Map<String, dynamic> json, List<String> keys, [int fallback = 0]) {
  return readNum(json, keys)?.toInt() ?? fallback;
}

bool readBool(Map<String, dynamic> json, List<String> keys, [bool fallback = false]) {
  for (final key in keys) {
    final v = json[key];
    if (v is bool) return v;
    if (v == 1 || v == '1' || v == 'true') return true;
    if (v == 0 || v == '0' || v == 'false') return false;
  }
  return fallback;
}

List<T> mapList<T>(dynamic raw, T Function(Map<String, dynamic>) mapper) {
  return asList(raw)
      .whereType<Map>()
      .map((e) => mapper(asMap(e)))
      .toList();
}

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  factory PaginatedResult.fromJson(
    dynamic raw,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final map = asMap(raw);
    final meta = asMap(map['meta'] ?? map['pagination']);
    final itemsRaw = map['items'] ?? map['data'] ?? map['results'] ?? raw;
    return PaginatedResult(
      items: mapList(itemsRaw, mapper),
      total: readInt(meta.isNotEmpty ? meta : map, ['total', 'totalCount']),
      page: readInt(meta.isNotEmpty ? meta : map, ['page'], 1),
      limit: readInt(meta.isNotEmpty ? meta : map, ['limit'], 20),
    );
  }
}
