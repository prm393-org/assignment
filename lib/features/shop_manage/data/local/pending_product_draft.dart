import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

/// A product creation queued locally while offline. Like
/// [PendingDiaryEntry], the image (if any) is already uploaded by the time
/// this is queued — `add_product_screen.dart` uploads eagerly on picking —
/// so only the resulting URL needs to be remembered here.
class PendingProductDraft extends Equatable {
  const PendingProductDraft({
    required this.localId,
    required this.shopId,
    required this.saleUnitId,
    this.name,
    required this.price,
    this.stockQty,
    this.imageUrl,
  });

  final String localId;
  final String shopId;
  final String saleUnitId;
  final String? name;
  final double price;
  final double? stockQty;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'shopId': shopId,
        'saleUnitId': saleUnitId,
        'name': name,
        'price': price,
        'stockQty': stockQty,
        'imageUrl': imageUrl,
      };

  factory PendingProductDraft.fromJson(Map<String, dynamic> json) =>
      PendingProductDraft(
        localId: readString(json, ['localId']),
        shopId: readString(json, ['shopId']),
        saleUnitId: readString(json, ['saleUnitId']),
        name: readStringOrNull(json, ['name']),
        price: readDouble(json, ['price']),
        stockQty: readNum(json, ['stockQty'])?.toDouble(),
        imageUrl: readStringOrNull(json, ['imageUrl']),
      );

  @override
  List<Object?> get props => [localId];
}
