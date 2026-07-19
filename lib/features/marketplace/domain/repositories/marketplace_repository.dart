import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';

abstract class MarketplaceRepository {
  Future<PaginatedResult<Product>> getProducts({
    int page = 1,
    int limit = 20,
    String? searchTerm,
    String? shopId,
    String? sort,
  });

  Future<Product> getProductById(String productId);

  Future<ShopSummary> getShopById(String shopId);

  Future<PaginatedResult<Product>> getShopProducts(
    String shopId, {
    int page = 1,
    int limit = 20,
  });
}
