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

  Future<void> _reviewDialog({
    required String productId,
    String? reviewId,
    int initialRating = 5,
    String? initialComment,
  }) async {
    var rating = initialRating.clamp(1, 5);
    final commentCtrl = TextEditingController(text: initialComment ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(reviewId == null ? 'Đánh giá sản phẩm' : 'Sửa đánh giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setLocal(() => rating = i),
                      icon: Icon(
                        i <= rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: 'Nhận xét'),
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
              child: Text(reviewId == null ? 'Gửi' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final comment =
          commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim();
      if (reviewId == null) {
        await ref.read(reviewRepositoryProvider).createReview(
              orderId: widget.orderId,
              productId: productId,
              rating: rating,
              comment: comment,
            );
      } else {
        await ref.read(reviewRepositoryProvider).updateReview(
              reviewId: reviewId,
              rating: rating,
              comment: comment,
            );
      }
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reviewId == null ? 'Đã gửi đánh giá' : 'Đã cập nhật đánh giá',
            ),
          ),
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
    ref.listen(liveOrderStatusProvider(widget.orderId), (prev, next) {
      final status = next.valueOrNull;
      if (status == null || status.isEmpty) return;
      final prevStatus = prev?.valueOrNull;
      if (prevStatus == status) return;
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(myOrdersProvider);
      ref.invalidate(shopOrdersProvider);
    });
    ref.watch(liveOrderStatusProvider(widget.orderId));

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
              Text(
                'Trạng thái: ${o.status}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(Formatters.dateTime(o.createdAt)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                o.shopName ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${o.shippingName} · ${o.shippingPhone}'),
              Text(o.shippingAddress ?? ''),
              const Divider(height: 32),
              for (final item in o.items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: Text(
                    '${item.qty} × ${Formatters.money(item.unitPrice)}'
                    '${item.myReviewRating != null ? ' · ★ ${item.myReviewRating}' : ''}',
                  ),
                  trailing: !widget.isSeller && o.status == 'delivered'
                      ? TextButton(
                          onPressed: () => _reviewDialog(
                            productId: item.productId,
                            reviewId: item.myReviewId,
                            initialRating: item.myReviewRating ?? 5,
                          ),
                          child: Text(
                            item.myReviewId == null ? 'Đánh giá' : 'Sửa đánh giá',
                          ),
                        )
                      : Text(Formatters.money(item.lineTotal)),
                ),
              const Divider(),
              Text(
                'Tổng (gồm ship): ${Formatters.money(total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
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
