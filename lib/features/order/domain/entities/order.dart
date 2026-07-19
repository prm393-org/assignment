import 'package:equatable/equatable.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/core/utils/media_url.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.productName,
    this.unit,
    this.imageUrl,
    this.myReviewId,
    this.myReviewRating,
  });

  final String id;
  final String productId;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final String productName;
  final String? unit;
  final String? imageUrl;
  final String? myReviewId;
  final int? myReviewRating;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = asMap(json['product'] ?? json['products']);
    final review = asMap(json['myReview'] ?? json['my_review']);
    return OrderItem(
      id: readString(json, ['id']),
      productId: readString(json, ['productId', 'product_id']),
      qty: readDouble(json, ['qty', 'quantity'], 1),
      unitPrice: readDouble(json, ['unitPrice', 'unit_price']),
      lineTotal: readDouble(json, ['lineTotal', 'line_total']),
      productName: readString(product, ['name'], 'Sản phẩm'),
      unit: readStringOrNull(product, ['unit']),
      imageUrl: resolveMediaUrl(readStringOrNull(product, ['imageUrl', 'image_url'])),
      myReviewId: review.isEmpty ? null : readStringOrNull(review, ['id']),
      myReviewRating: review.isEmpty ? null : readInt(review, ['rating']),
    );
  }

  @override
  List<Object?> get props => [id];
}

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.shopId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.createdAt,
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
    this.note,
    this.shopName,
    this.items = const [],
    this.sellerPayout,
    this.checkoutUrl,
  });

  final String id;
  final String shopId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final String createdAt;
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress;
  final String? note;
  final String? shopName;
  final List<OrderItem> items;
  final double? sellerPayout;
  final String? checkoutUrl;

  factory OrderEntity.fromJson(Map<String, dynamic> json) {
    final shop = asMap(json['shop'] ?? json['shops']);
    final nestedOrder = asMap(json['order']);
    final source = nestedOrder.isNotEmpty ? {...nestedOrder, ...json} : json;
    return OrderEntity(
      id: readString(source, ['id']),
      shopId: readString(source, ['shopId', 'shop_id']),
      status: readString(source, ['status']),
      paymentMethod:
          readString(source, ['paymentMethod', 'payment_method'], 'cod'),
      paymentStatus: readString(source, ['paymentStatus', 'payment_status']),
      totalAmount: readDouble(source, ['totalAmount', 'total_amount']),
      createdAt: readString(source, ['createdAt', 'created_at']),
      shippingName:
          readStringOrNull(source, ['shippingName', 'shipping_name']),
      shippingPhone:
          readStringOrNull(source, ['shippingPhone', 'shipping_phone']),
      shippingAddress:
          readStringOrNull(source, ['shippingAddress', 'shipping_address']),
      note: readStringOrNull(source, ['note']),
      shopName: readStringOrNull(shop, ['name']) ??
          readStringOrNull(asMap(source['shop'] ?? source['shops']), ['name']),
      items: mapList(
        source['items'] ?? source['order_items'] ?? json['items'],
        OrderItem.fromJson,
      ),
      sellerPayout: readNum(source, [
        'sellerPayout',
        'seller_payout',
        'estimatedSellerPayout',
      ])?.toDouble(),
      checkoutUrl: readStringOrNull(json, ['checkoutUrl', 'checkout_url']) ??
          readStringOrNull(source, ['checkoutUrl', 'checkout_url']),
    );
  }

  @override
  List<Object?> get props => [id, status];
}

class ShopEarnings extends Equatable {
  const ShopEarnings({
    required this.finalizedSellerPayout,
    required this.totalGmvFinalized,
    required this.totalPlatformCommissionFinalized,
    required this.pipelineEstimatedPayout,
    required this.finalizedOrderCount,
    required this.pipelineOrderCount,
  });

  final double finalizedSellerPayout;
  final double totalGmvFinalized;
  final double totalPlatformCommissionFinalized;
  final double pipelineEstimatedPayout;
  final int finalizedOrderCount;
  final int pipelineOrderCount;

  factory ShopEarnings.fromJson(Map<String, dynamic> json) => ShopEarnings(
        finalizedSellerPayout: readDouble(json, ['finalizedSellerPayout']),
        totalGmvFinalized: readDouble(json, ['totalGmvFinalized']),
        totalPlatformCommissionFinalized:
            readDouble(json, ['totalPlatformCommissionFinalized']),
        pipelineEstimatedPayout: readDouble(json, ['pipelineEstimatedPayout']),
        finalizedOrderCount: readInt(json, ['finalizedOrderCount']),
        pipelineOrderCount: readInt(json, ['pipelineOrderCount']),
      );

  @override
  List<Object?> get props => [finalizedSellerPayout];
}
