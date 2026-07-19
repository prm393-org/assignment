import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class AgriTrend extends Equatable {
  const AgriTrend({
    required this.summary,
    required this.generatedAt,
    this.hotCrops = const [],
    this.alerts = const [],
  });

  final String summary;
  final String generatedAt;
  final List<Map<String, String>> hotCrops;
  final List<Map<String, String>> alerts;

  factory AgriTrend.fromJson(Map<String, dynamic> json) {
    return AgriTrend(
      summary: readString(json, ['summary']),
      generatedAt: readString(json, ['generatedAt', 'generated_at']),
      hotCrops: asList(json['hotCrops'] ?? json['hot_crops']).whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'name': readString(m, ['name']),
          'reason': readString(m, ['reason']),
          'sentiment': readString(m, ['sentiment']),
        };
      }).toList(),
      alerts: asList(json['alerts']).whereType<Map>().map((e) {
        final m = asMap(e);
        return {
          'type': readString(m, ['type']),
          'severity': readString(m, ['severity']),
          'message': readString(m, ['message']),
        };
      }).toList(),
    );
  }

  @override
  List<Object?> get props => [generatedAt, summary];
}
