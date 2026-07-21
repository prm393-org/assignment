import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/storage/json_list_notifier.dart';
import 'package:chuoi_xanh_viet/features/farm/data/local/pending_diary_entry.dart';
import 'package:chuoi_xanh_viet/features/farm/domain/repositories/farm_repository.dart';

class PendingDiaryQueueNotifier extends JsonListNotifier<PendingDiaryEntry> {
  @override
  String get storageKey => 'pending_diary_queue';

  @override
  Map<String, dynamic> toJson(PendingDiaryEntry item) => item.toJson();

  @override
  PendingDiaryEntry fromJson(Map<String, dynamic> json) =>
      PendingDiaryEntry.fromJson(json);

  Future<void> enqueue(PendingDiaryEntry entry) async {
    state = [...state, entry];
    await persist();
  }

  Future<void> _remove(String localId) async {
    state = state.where((e) => e.localId != localId).toList();
    await persist();
  }

  /// Retries every queued entry against the real REST repository. Stops at
  /// the first [NetworkFailure]/[AuthFailure] (still offline or signed
  /// out — every remaining entry would fail the same way) and leaves the
  /// rest queued; any other failure means just that entry is broken, so it
  /// stays queued too but doesn't block the ones behind it. Returns how
  /// many entries were synced.
  Future<int> flush(FarmRepository repo) async {
    var synced = 0;
    for (final entry in [...state]) {
      try {
        final created = await repo.createDiary({
          'seasonId': entry.seasonId,
          'farmId': entry.farmId,
          'eventType': entry.eventType,
          'eventDate': entry.eventDate,
          'description': entry.description,
          if (entry.imageUrl != null)
            'extraData': {
              'imageUrls': [entry.imageUrl],
            },
        });
        if (entry.imageUrl != null) {
          try {
            await repo.addDiaryAttachment(
              created.id,
              fileUrl: entry.imageUrl!,
              mimeType: 'image/jpeg',
            );
          } catch (_) {
            // Attachment endpoint may be missing; extraData already sent.
          }
        }
        await _remove(entry.localId);
        synced++;
      } on NetworkFailure {
        break;
      } on AuthFailure {
        break;
      } catch (_) {
        continue;
      }
    }
    return synced;
  }
}

final pendingDiaryQueueProvider =
    StateNotifierProvider<PendingDiaryQueueNotifier, List<PendingDiaryEntry>>(
  (ref) => PendingDiaryQueueNotifier(),
);
