import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chuoi_xanh_viet/core/error/firestore_exception_mapper.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/firebase/firestore_refs.dart';
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
  CartNotifier(this._ref) : super(const []) {
    final uid = _ref.read(currentFirebaseUidProvider);
    _bindUser(uid);
    _uidSub = _ref.listen<String?>(currentFirebaseUidProvider, (
      previous,
      next,
    ) {
      if (previous == next) return;
      if (previous == null && next != null) {
        _migrateGuestCartTo(next);
      } else {
        _bindUser(next);
      }
    });
  }

  final Ref _ref;
  static const _key = 'cart_storage';

  String? _boundUid;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
  ProviderSubscription<String?>? _uidSub;

  /// Guests (no Firebase uid) keep the pre-Firestore local-only behavior.
  /// Signed-in users get a live Firestore listener instead, which is what
  /// makes the cart show up on a second device.
  void _bindUser(String? uid) {
    _boundUid = uid;
    _firestoreSub?.cancel();
    _firestoreSub = null;
    if (uid == null) {
      _hydrate();
      return;
    }
    _firestoreSub = FirestoreRefs.cartItemsRef(uid).snapshots().listen((
      snapshot,
    ) {
      state = snapshot.docs
          .map((d) => CartItem.fromJson(d.data()))
          .toList();
    });
  }

  /// Runs once, right when a guest logs in: folds whatever was sitting in
  /// the local SharedPreferences cart into the user's Firestore cart
  /// (summing quantities for items already present there) before switching
  /// this notifier over to the Firestore-backed mode.
  Future<void> _migrateGuestCartTo(String uid) async {
    final guestItems = state;
    _bindUser(uid);
    if (guestItems.isEmpty) return;
    try {
      final ref = FirestoreRefs.cartItemsRef(uid);
      final batch = FirebaseFirestore.instance.batch();
      for (final item in guestItems) {
        final doc = ref.doc(item.productId);
        final existing = await doc.get();
        if (existing.exists) {
          final existingQty = readInt(existing.data() ?? {}, ['quantity']);
          final max = item.stockQty?.toInt() ?? 9999;
          final mergedQty = (existingQty + item.quantity).clamp(1, max);
          batch.set(doc, item.copyWith(quantity: mergedQty).toJson());
        } else {
          batch.set(doc, item.toJson());
        }
      }
      await batch.commit();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Best-effort merge — if it fails, the guest cart is simply not
      // folded in yet; nothing is lost since SharedPreferences still has it.
    }
  }

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
    CartItem effective;
    final idx = state.indexWhere((e) => e.productId == item.productId);
    if (idx >= 0) {
      final existing = state[idx];
      final max = existing.stockQty?.toInt() ?? 9999;
      final next = (existing.quantity + quantity).clamp(1, max);
      effective = existing.copyWith(quantity: next);
      final copy = [...state];
      copy[idx] = effective;
      state = copy;
    } else {
      effective = item.copyWith(quantity: quantity);
      state = [...state, effective];
    }
    await _writeItem(effective);
  }

  Future<void> updateQuantity(String productId, int delta) async {
    CartItem? updated;
    state = [
      for (final i in state)
        if (i.productId == productId)
          (updated = i.copyWith(
            quantity: (i.quantity + delta).clamp(
              1,
              i.stockQty?.toInt() ?? 9999,
            ),
          ))
        else
          i,
    ];
    if (updated != null) await _writeItem(updated);
  }

  Future<void> removeItem(String productId) async {
    state = state.where((e) => e.productId != productId).toList();
    await _deleteItems([productId]);
  }

  Future<void> removeByShop(String shopId) async {
    final removedIds = state
        .where((e) => e.shopId == shopId)
        .map((e) => e.productId)
        .toList();
    state = state.where((e) => e.shopId != shopId).toList();
    await _deleteItems(removedIds);
  }

  Future<void> clear() async {
    final removedIds = state.map((e) => e.productId).toList();
    state = const [];
    await _deleteItems(removedIds);
  }

  Future<void> _writeItem(CartItem item) async {
    final uid = _boundUid;
    if (uid == null) {
      await _persist();
      return;
    }
    try {
      await FirestoreRefs.cartItemsRef(
        uid,
      ).doc(item.productId).set(item.toJson());
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  Future<void> _deleteItems(List<String> productIds) async {
    final uid = _boundUid;
    if (uid == null) {
      await _persist();
      return;
    }
    if (productIds.isEmpty) return;
    try {
      final ref = FirestoreRefs.cartItemsRef(uid);
      final batch = FirebaseFirestore.instance.batch();
      for (final id in productIds) {
        batch.delete(ref.doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _uidSub?.close();
    super.dispose();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity);
});
