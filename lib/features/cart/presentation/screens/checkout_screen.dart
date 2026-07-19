import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _paymentMethod = 'cod';
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
      String? checkoutUrl;
      for (final g in groups) {
        final order = await repo.createOrder(
          shopId: g.shopId,
          items: [
            for (final i in g.items)
              {'product_id': i.productId, 'qty': i.quantity},
          ],
          shippingName: _name.text.trim(),
          shippingPhone: _phone.text.trim(),
          shippingAddress: _address.text.trim(),
          paymentMethod: _paymentMethod,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
        await ref.read(cartProvider.notifier).removeByShop(g.shopId);
        checkoutUrl ??= order.checkoutUrl;
      }
      if (!mounted) return;
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang mở trang thanh toán')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _paymentMethod == 'cod'
                  ? 'Đặt hàng thành công (COD)'
                  : 'Đặt hàng thành công',
            ),
          ),
        );
      }
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
          Text(
            'Đơn theo gian hàng',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
          Text(
            'Phương thức thanh toán',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          RadioListTile<String>(
            value: 'cod',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'cod'),
            title: const Text('Thanh toán khi nhận hàng (COD)'),
          ),
          RadioListTile<String>(
            value: 'payos',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'payos'),
            title: const Text('PayOS'),
          ),
          RadioListTile<String>(
            value: 'vnpay',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'vnpay'),
            title: const Text('VNPay'),
          ),
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
