import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';

class AvailableSaleUnit {
  const AvailableSaleUnit({
    required this.id,
    required this.code,
    required this.quantity,
    required this.unit,
    this.cropName,
    this.shortCode,
  });

  final String id;
  final String code;
  final String quantity;
  final String unit;
  final String? cropName;
  final String? shortCode;
}

abstract class ShopManageRepository {
  Future<List<ShopSummary>> getMyShops();
  Future<ShopSummary> getShop(String id);
  Future<ShopSummary> createShop({
    required String farmId,
    required String name,
    String? description,
  });
  Future<ShopSummary> updateShop(String id, Map<String, dynamic> body);
  Future<List<AvailableSaleUnit>> getAvailableSaleUnits(String shopId);
  Future<List<Product>> getShopProducts(String shopId);
  Future<Product> addProduct(String shopId, Map<String, dynamic> body);
  Future<Product> updateProduct(
    String shopId,
    String productId,
    Map<String, dynamic> body,
  );
  Future<void> deleteProduct(String shopId, String productId);
}
