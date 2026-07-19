import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';
import 'package:chuoi_xanh_viet/features/review/presentation/providers/review_providers.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';

class ShopDetailManageScreen extends ConsumerStatefulWidget {
  const ShopDetailManageScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<ShopDetailManageScreen> createState() =>
      _ShopDetailManageScreenState();
}

class _ShopDetailManageScreenState
    extends ConsumerState<ShopDetailManageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _editShop() async {
    final shop = await ref.read(managedShopProvider(widget.shopId).future);
    final name = TextEditingController(text: shop.name);
    final desc = TextEditingController(text: shop.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa gian hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Tên gian hàng'),
            ),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(shopManageRepositoryProvider).updateShop(widget.shopId, {
        'name': name.text.trim(),
        'description': desc.text.trim(),
      });
      ref.invalidate(managedShopProvider(widget.shopId));
      ref.invalidate(myShopsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật gian hàng')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _editProduct(Product p) async {
    final name = TextEditingController(text: p.name);
    final price = TextEditingController(text: '${p.price}');
    final stock = TextEditingController(
      text: p.stockQty != null ? '${p.stockQty}' : '',
    );
    final desc = TextEditingController(text: p.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sửa sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              TextField(
                controller: price,
                decoration: const InputDecoration(labelText: 'Giá'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stock,
                decoration: const InputDecoration(labelText: 'Tồn kho'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(shopManageRepositoryProvider).updateProduct(
        widget.shopId,
        p.id,
        {
          'name': name.text.trim(),
          'price': double.tryParse(price.text) ?? p.price,
          'stock_qty': double.tryParse(stock.text),
          'description': desc.text.trim(),
        },
      );
      ref.invalidate(managedShopProductsProvider(widget.shopId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật sản phẩm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá sản phẩm'),
        content: Text('Xoá "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(shopManageRepositoryProvider)
          .deleteProduct(widget.shopId, p.id);
      ref.invalidate(managedShopProductsProvider(widget.shopId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá sản phẩm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is Failure ? e.message : '$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(managedShopProvider(widget.shopId));

    return Scaffold(
      appBar: AppBar(
        title: Text(shopAsync.valueOrNull?.name ?? 'Quản lý gian hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editShop,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Sản phẩm'),
            Tab(text: 'Đơn hàng'),
            Tab(text: 'Đánh giá'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (_, __) {
          if (_tabs.index != 0) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () =>
                context.push('/farmer/shop/${widget.shopId}/add-product'),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProductsTab(
            shopId: widget.shopId,
            onEdit: _editProduct,
            onDelete: _deleteProduct,
          ),
          _OrdersTab(shopId: widget.shopId),
          _ReviewsTab(shopId: widget.shopId),
        ],
      ),
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab({
    required this.shopId,
    required this.onEdit,
    required this.onDelete,
  });

  final String shopId;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(managedShopProductsProvider(shopId));
    return AsyncBody(
      value: async.asLike,
      onRetry: () => ref.invalidate(managedShopProductsProvider(shopId)),
      isEmpty: (list) => list.isEmpty,
      emptyMessage: 'Chưa có sản phẩm',
      builder: (list) => ListView.separated(
        padding: AppSpacing.screen,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final p = list[i];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.hairline),
            ),
            tileColor: AppColors.surface,
            title: Text(p.name),
            subtitle: Text(
              '${Formatters.money(p.price)} · Tồn: ${p.stockQty ?? 0}'
              '${p.isActive ? '' : ' · Ẩn'}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit(p);
                if (v == 'delete') onDelete(p);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xoá')),
              ],
            ),
            onTap: () => onEdit(p),
          );
        },
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopOrdersProvider);
    return AsyncBody(
      value: async.asLike,
      onRetry: () => ref.invalidate(shopOrdersProvider),
      isEmpty: (page) =>
          page.items.where((o) => o.shopId == shopId).isEmpty,
      emptyMessage: 'Chưa có đơn hàng',
      builder: (page) {
        final items = page.items.where((o) => o.shopId == shopId).toList();
        return ListView.separated(
          padding: AppSpacing.screen,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) {
            final o = items[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.hairline),
              ),
              tileColor: AppColors.surface,
              title: Text('Đơn #${o.id.length > 8 ? o.id.substring(0, 8) : o.id}'),
              subtitle: Text('${o.status} · ${Formatters.dateTime(o.createdAt)}'),
              trailing: Text(Formatters.money(o.totalAmount)),
              onTap: () => context.push('/farmer/orders/${o.id}'),
            );
          },
        );
      },
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  const _ReviewsTab({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopReviewsProvider(shopId));
    return AsyncBody(
      value: async.asLike,
      onRetry: () => ref.invalidate(shopReviewsProvider(shopId)),
      isEmpty: (page) => page.items.isEmpty,
      emptyMessage: 'Chưa có đánh giá',
      builder: (page) => ListView.separated(
        padding: AppSpacing.screen,
        itemCount: page.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) {
          final r = page.items[i];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.hairline),
            ),
            tileColor: AppColors.surface,
            title: Text(r.reviewerName ?? 'Khách'),
            subtitle: Text(
              '${'★' * r.rating}${'☆' * (5 - r.rating)}\n'
              '${r.comment ?? ''}\n'
              '${r.productName ?? ''}',
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
