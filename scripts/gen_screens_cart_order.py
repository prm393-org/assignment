# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r'd:\fpt\ky8\PRM393\assignment\lib')


def w(rel: str, content: str) -> None:
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + '\n', encoding='utf-8')
    print(rel)


w('features/cart/presentation/screens/cart_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final groups = groupCartByShop(items);
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: items.isEmpty
          ? const EmptyState(
              message: 'Giỏ hàng trống',
              icon: Icons.shopping_cart_outlined,
            )
          : ListView(
              padding: AppSpacing.screen,
              children: [
                for (final g in groups) ...[
                  Text(g.shopName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in g.items)
                    Card(
                      child: ListTile(
                        title: Text(item.productName),
                        subtitle: Text(Formatters.money(item.price)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(item.productId, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(item.productId, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .removeItem(item.productId),
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: AppSpacing.screen,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tạm tính'),
                        Text(
                          Formatters.money(subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => context.push('/consumer/checkout'),
                      child: const Text('Thanh toán'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
''')

w('features/cart/presentation/screens/checkout_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/config/api_config.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _name.text = user?.fullName ?? '';
    _phone.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _placeOrders() async {
    final items = ref.read(cartProvider);
    final groups = groupCartByShop(items);
    if (groups.isEmpty) return;
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin giao hàng')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      for (final g in groups) {
        await repo.createOrder(
          shopId: g.shopId,
          items: [
            for (final i in g.items)
              {'product_id': i.productId, 'qty': i.quantity},
          ],
          shippingName: _name.text.trim(),
          shippingPhone: _phone.text.trim(),
          shippingAddress: _address.text.trim(),
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
        await ref.read(cartProvider.notifier).removeByShop(g.shopId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đặt hàng thành công (COD)')),
      );
      context.go('/consumer/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final groups = groupCartByShop(items);
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final shipping = groups.length * ApiConfig.shippingFeePerShop;
    final total = subtotal + shipping;

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          Text('Giao hàng', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Họ tên người nhận'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Địa chỉ'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Đơn theo gian hàng', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final g in groups)
            Card(
              child: ListTile(
                title: Text(g.shopName),
                subtitle: Text('${g.items.length} sản phẩm'),
                trailing: Text(Formatters.money(g.subtotal)),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Thanh toán khi nhận hàng (COD)'),
          const SizedBox(height: AppSpacing.md),
          _row('Tạm tính', Formatters.money(subtotal)),
          _row('Phí ship (${groups.length} shop)', Formatters.money(shipping)),
          _row('Tổng cộng', Formatters.money(total), bold: true),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _loading || groups.isEmpty ? null : _placeOrders,
            child: Text(_loading ? 'Đang đặt...' : 'Xác nhận đặt hàng'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.forest : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
''')

w('features/order/presentation/screens/orders_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key, this.isSeller = false});

  final bool isSeller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(isSeller ? shopOrdersProvider : myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(isSeller ? 'Đơn bán' : 'Đơn hàng của tôi')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(isSeller ? shopOrdersProvider : myOrdersProvider),
        isEmpty: (page) => page.items.isEmpty,
        emptyMessage: 'Chưa có đơn hàng',
        builder: (page) => ListView.separated(
          padding: AppSpacing.screen,
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final o = page.items[i];
            final path = isSeller
                ? '/farmer/orders/${o.id}'
                : '/consumer/orders/${o.id}';
            return ListTile(
              onTap: () => context.push(path),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text(o.shopName ?? 'Đơn #${o.id.substring(0, 8)}'),
              subtitle: Text('${o.status} · ${Formatters.dateTime(o.createdAt)}'),
              trailing: Text(
                Formatters.money(o.totalAmount),
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
''')

w('features/order/presentation/screens/order_detail_screen.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/config/api_config.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';
import 'package:chuoi_xanh_viet/features/review/presentation/providers/review_providers.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.isSeller = false,
  });

  final String orderId;
  final bool isSeller;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Future<void> _cancel() async {
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(widget.orderId);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(widget.orderId, status);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(shopOrdersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _review(String productId) async {
    final ratingCtrl = TextEditingController(text: '5');
    final commentCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đánh giá sản phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ratingCtrl,
              decoration: const InputDecoration(labelText: 'Số sao (1-5)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Nhận xét'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(reviewRepositoryProvider).createReview(
            orderId: widget.orderId,
            productId: productId,
            rating: int.tryParse(ratingCtrl.text) ?? 5,
            comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
          );
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn')),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        builder: (o) {
          final total = o.totalAmount + ApiConfig.shippingFeePerShop;
          return ListView(
            padding: AppSpacing.screen,
            children: [
              Text('Trạng thái: ${o.status}',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(Formatters.dateTime(o.createdAt)),
              const SizedBox(height: AppSpacing.lg),
              Text(o.shopName ?? '', style: Theme.of(context).textTheme.titleMedium),
              Text('${o.shippingName} · ${o.shippingPhone}'),
              Text(o.shippingAddress ?? ''),
              const Divider(height: 32),
              for (final item in o.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: Text('${item.qty} × ${Formatters.money(item.unitPrice)}'),
                  trailing: (!widget.isSeller &&
                          o.status == 'delivered' &&
                          item.myReviewId == null)
                      ? TextButton(
                          onPressed: () => _review(item.productId),
                          child: const Text('Đánh giá'),
                        )
                      : Text(Formatters.money(item.lineTotal)),
                ),
              const Divider(),
              Text('Tổng (gồm ship): ${Formatters.money(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  )),
              const SizedBox(height: AppSpacing.xl),
              if (!widget.isSeller && o.status == 'pending')
                OutlinedButton(
                  onPressed: _cancel,
                  child: const Text('Huỷ đơn'),
                ),
              if (widget.isSeller) ...[
                if (o.status == 'pending')
                  FilledButton(
                    onPressed: () => _updateStatus('confirmed'),
                    child: const Text('Xác nhận đơn'),
                  ),
                if (o.status == 'confirmed')
                  FilledButton(
                    onPressed: () => _updateStatus('shipping'),
                    child: const Text('Đang giao'),
                  ),
                if (o.status == 'shipping')
                  FilledButton(
                    onPressed: () => _updateStatus('delivered'),
                    child: const Text('Đã giao'),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
''')

print('cart order screens done')
