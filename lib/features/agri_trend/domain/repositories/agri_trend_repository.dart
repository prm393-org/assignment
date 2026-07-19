import 'package:chuoi_xanh_viet/features/agri_trend/domain/entities/agri_trend.dart';

abstract class AgriTrendRepository {
  Future<AgriTrend> getTrend({bool refresh = false});
}
