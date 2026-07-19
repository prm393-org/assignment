import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chuoi_xanh_viet/core/utils/json_helpers.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.shopId,
    required this.shopName,
    this.stockQty,
    this.imageUrl,
  });

  final String productId;
  final String productName;
  final double price;
  final String unit;
  final int quantity;
  final String shopId;
  final String shopName;
  final double? stockQty;
  final String? imageUrl;

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        productName: productName,
        price: price,
        unit: unit,
        quantity: quantity ?? this.quantity,
        shopId: shopId,
        shopName: shopName,
        stockQty: stockQty,
        imageUrl: imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'unit': unit,
        'quantity': quantity,
        'shopId': shopId,
        'shopName': shopName,
        'stockQty': stockQty,
        'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: readString(json, ['productId']),
        productName: readString(json, ['productName']),
        price: readDouble(json, ['price']),
        unit: readString(json, ['unit'], 'kg'),
        quantity: readInt(json, ['quantity'], 1),
        shopId: readString(json, ['shopId']),
        shopName: readString(json, ['shopName']),
        stockQty: readNum(json, ['stockQty'])?.toDouble(),
        imageUrl: readStringOrNull(json, ['imageUrl']),
      );

  @override
  List<Object?> get props => [productId, quantity];
}

class CartShopGroup {
  const CartShopGroup({
    required this.shopId,
    required this.shopName,
    required this.items,
  });

  final String shopId;
  final String shopName;
  final List<CartItem> items;

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
}

List<CartShopGroup> groupCartByShop(List<CartItem> items) {
  final map = <String, CartShopGroup>{};
  for (final item in items) {
    final existing = map[item.shopId];
    if (existing == null) {
      map[item.shopId] = CartShopGroup(
        shopId: item.shopId,
        shopName: item.shopName,
        items: [item],
      );
    } else {
      existing.items.add(item);
    }
  }
  return map.values.toList();
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []) {
    _hydrate();
  }

  static const _key = 'cart_storage';

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    final list = asList(jsonDecode(raw));
    state = list
        .whereType<Map>()
        .map((e) => CartItem.fromJson(asMap(e)))
        .toList();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addItem(CartItem item, {int quantity = 1}) async {
    final idx = state.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      final existing = state[idx];
      final max = existing.stockQty?.toInt() ?? 9999;
      final next = (existing.quantity + quantity).clamp(1, max);
      final copy = [...state];
      copy[idx] = existing.copyWith(quantity: next);
      state = copy;
    } else {
      state = [...state, item.copyWith(quantity: quantity)];
    }
    await _persist();
  }

  Future<void> updateQuantity(String productId, int delta) async {
    state = [
      for (final i in state)
        if (i.productId == productId)
          i.copyWith(
            quantity: (i.quantity + delta).clamp(
              1,
              i.stockQty?.toInt() ?? 9999,
            ),
          )
        else
          i,
    ];
    await _persist();
  }

  Future<void> removeItem(String productId) async {
    state = state.where((e) => e.productId != productId).toList();
    await _persist();
  }

  Future<void> removeByShop(String shopId) async {
    state = state.where((e) => e.shopId != shopId).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity);
});
