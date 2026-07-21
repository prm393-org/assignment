import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';

class MarketplaceFilter {
  const MarketplaceFilter({
    this.page = 1,
    this.limit = 20,
    this.searchTerm,
    this.province,
    this.shopId,
    this.sort,
    this.minPrice,
    this.maxPrice,
  });

  final int page;
  final int limit;
  final String? searchTerm;
  final String? province;
  final String? shopId;
  final String? sort;
  final double? minPrice;
  final double? maxPrice;

  MarketplaceFilter copyWith({
    int? page,
    int? limit,
    String? searchTerm,
    String? province,
    String? shopId,
    String? sort,
    double? minPrice,
    double? maxPrice,
    bool clearSearch = false,
    bool clearProvince = false,
    bool clearPrices = false,
  }) {
    return MarketplaceFilter(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      searchTerm: clearSearch ? null : (searchTerm ?? this.searchTerm),
      province: clearProvince ? null : (province ?? this.province),
      shopId: shopId ?? this.shopId,
      sort: sort ?? this.sort,
      minPrice: clearPrices ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrices ? null : (maxPrice ?? this.maxPrice),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketplaceFilter &&
          page == other.page &&
          limit == other.limit &&
          searchTerm == other.searchTerm &&
          province == other.province &&
          shopId == other.shopId &&
          sort == other.sort &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice;

  @override
  int get hashCode => Object.hash(
        page,
        limit,
        searchTerm,
        province,
        shopId,
        sort,
        minPrice,
        maxPrice,
      );
}

abstract class MarketplaceRepository {
  Future<PaginatedResult<Product>> getProducts({
    MarketplaceFilter filter = const MarketplaceFilter(),
  });

  Future<Product> getProductById(String productId);

  Future<ShopSummary> getShopById(String shopId);

  Future<PaginatedResult<ShopSummary>> getShops({
    MarketplaceFilter filter = const MarketplaceFilter(),
  });

  Future<PaginatedResult<Product>> getShopProducts(
    String shopId, {
    int page = 1,
    int limit = 20,
  });
}
