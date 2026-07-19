import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/farm.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/entities/season.dart';

abstract class FarmRepository {
  Future<List<Farm>> getMyFarms();
  Future<Farm> createFarm(Map<String, dynamic> body);
  Future<Farm> updateFarm(String id, Map<String, dynamic> body);
  Future<void> deleteFarm(String id);

  Future<List<Season>> getSeasons(String farmId);
  Future<Season> getSeasonById(String seasonId);
  Future<Season> createSeason(Map<String, dynamic> body);
  Future<Season> updateSeason(String id, Map<String, dynamic> body);
  Future<Season> updateSeasonStatus(String id, String status);

  Future<PaginatedResult<DiaryEntry>> getDiaries({
    String? seasonId,
    String? farmId,
    int page = 1,
  });
  Future<DiaryEntry> createDiary(Map<String, dynamic> body);
  Future<void> addDiaryAttachment(
    String diaryId, {
    required String fileUrl,
    required String mimeType,
  });
  Future<void> deleteDiaryAttachment(String attachmentId);
}
