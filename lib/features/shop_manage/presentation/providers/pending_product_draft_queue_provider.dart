import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/storage/json_list_notifier.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/data/local/pending_product_draft.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/domain/repositories/shop_manage_repository.dart';

class PendingProductDraftQueueNotifier
    extends JsonListNotifier<PendingProductDraft> {
  @override
  String get storageKey => 'pending_product_drafts';

  @override
  Map<String, dynamic> toJson(PendingProductDraft item) => item.toJson();

  @override
  PendingProductDraft fromJson(Map<String, dynamic> json) =>
      PendingProductDraft.fromJson(json);

  Future<void> enqueue(PendingProductDraft draft) async {
    state = [...state, draft];
    await persist();
  }

  Future<void> remove(String localId) async {
    state = state.where((e) => e.localId != localId).toList();
    await persist();
  }

  /// Same retry semantics as `PendingDiaryQueueNotifier.flush`: stops on
  /// [NetworkFailure]/[AuthFailure] (still offline/signed out), skips past
  /// any other failure without blocking the rest of the queue. Returns how
  /// many drafts were synced.
  Future<int> flush(ShopManageRepository repo) async {
    var synced = 0;
    for (final draft in [...state]) {
      try {
        await repo.addProduct(draft.shopId, {
          'sale_unit_id': draft.saleUnitId,
          'name': draft.name,
          'price': draft.price,
          'stock_qty': draft.stockQty,
          if (draft.imageUrl != null) 'image_url': draft.imageUrl,
        });
        await remove(draft.localId);
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

final pendingProductDraftQueueProvider = StateNotifierProvider<
    PendingProductDraftQueueNotifier, List<PendingProductDraft>>(
  (ref) => PendingProductDraftQueueNotifier(),
);
