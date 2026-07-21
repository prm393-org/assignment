import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/error/failures.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/utils/async_ext.dart';
import 'package:chuoi_xanh_viet/core/utils/formatters.dart';
import 'package:chuoi_xanh_viet/core/widgets/app_network_image.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';
import 'package:chuoi_xanh_viet/features/marketplace/domain/entities/product.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:chuoi_xanh_viet/features/review/presentation/providers/review_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  bool _openingChat = false;

  bool get _canBuy {
    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) return true; // show CTAs; gate on tap
    final role = auth.role;
    return role == null || role == AuthRole.consumer;
  }

  bool _assertCanPurchase() {
    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để thêm vào giỏ hàng')),
      );
      context.push('/login');
      return false;
    }
    final role = auth.role;
    if (role == AuthRole.farmer ||
        role == AuthRole.admin ||
        role == AuthRole.cooperative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ tài khoản người mua mới có thể đặt hàng'),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _openFarmMap(ProductFarmInfo? farm) async {
    if (farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có vị trí trang trại')),
      );
      return;
    }
    final Uri uri;
    if (farm.hasGeo) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${farm.latitude},${farm.longitude}',
      );
    } else {
      final q = farm.mapQuery ?? farm.regionLine;
      if (q == null || q.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có vị trí trang trại')),
        );
        return;
      }
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
      );
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được bản đồ')),
      );
    }
  }

  Future<void> _messageFarmer(String? ownerUserId) async {
    if (ownerUserId == null || ownerUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy nông dân của gian hàng này'),
        ),
      );
      return;
    }
    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để chat với nông dân')),
      );
      context.push('/login');
      return;
    }
    setState(() => _openingChat = true);
    try {
      final conversation = await ref
          .read(chatRepositoryProvider)
          .openConversation(ownerUserId);
      if (!mounted) return;
      context.push('/consumer/chat/${conversation.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Failure ? e.message : 'Không mở được cuộc trò chuyện',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _addToCart(Product p, {required bool goCart}) async {
    if (!_assertCanPurchase()) return;
    final stock = p.stockQty;
    if (stock != null && stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm đã hết hàng')),
      );
      return;
    }
    if (stock != null && _qty > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vượt tồn kho')),
      );
      return;
    }
    await ref.read(cartProvider.notifier).addItem(
          CartItem(
            productId: p.id,
            productName: p.name,
            price: p.price,
            unit: p.unit ?? 'kg',
            quantity: _qty,
            shopId: p.shopId.isNotEmpty ? p.shopId : (p.shop?.id ?? ''),
            shopName: p.shop?.name ?? 'Gian hàng',
            stockQty: p.stockQty,
            imageUrl: p.imageUrl,
          ),
          quantity: _qty,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm vào giỏ')),
    );
    if (goCart) context.push('/consumer/cart');
  }

  String _shopInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'GH';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.productId));
    final reviews = ref.watch(productReviewsProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
      ),
      body: AsyncBody(
        value: async.asLike,
        onRetry: () =>
            ref.invalidate(productDetailProvider(widget.productId)),
        builder: (p) {
          final shopId = p.shopId.isNotEmpty ? p.shopId : p.shop?.id;
          final shopPanel = shopId == null || shopId.isEmpty
              ? null
              : ref.watch(shopDetailProvider(shopId));
          final shopProducts = shopId == null || shopId.isEmpty
              ? null
              : ref.watch(shopProductsSimpleProvider(shopId));
          final stock = p.stockQty;
          final outOfStock = stock != null && stock <= 0;
          final unit = p.unit ?? 'đơn vị';
          final farm = p.shop?.farm ?? shopPanel?.asData?.value.farm;
          final certs = (p.shop?.certifications.isNotEmpty == true)
              ? p.shop!.certifications
              : (shopPanel?.asData?.value.certifications ?? const <String>[]);
          final reviewCount = reviews.asData?.value.total ?? p.reviewCount;
          final avg = p.averageRating;
          final productCount = shopProducts?.asData?.value.total ?? 0;
          final ownerId =
              farm?.ownerUserId ?? shopPanel?.asData?.value.ownerUserId;
          final shop = shopPanel?.asData?.value;
          final maxQty = stock?.toInt() ?? 9999;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeroImage(
                imageUrl: p.imageUrl,
                isVerified: p.shop?.isVerified == true ||
                    shop?.isVerified == true,
              ),
              Padding(
                padding: AppSpacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            reviewCount > 0 && avg != null
                                ? '★ ${avg.toStringAsFixed(1)} ($reviewCount)'
                                : 'Chưa có đánh giá',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: AppColors.hairline,
                        ),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: outOfStock
                              ? AppColors.error
                              : AppColors.forest,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          outOfStock
                              ? 'HẾT HÀNG'
                              : stock != null
                                  ? 'CÒN ${stock.toInt()} ${unit.toUpperCase()}'
                                  : 'CÒN HÀNG',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: outOfStock
                                ? AppColors.error
                                : AppColors.forest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PriceQtyCard(
                      price: p.price,
                      unit: unit,
                      qty: _qty,
                      canBuy: _canBuy && !outOfStock,
                      onMinus: () => setState(
                        () => _qty = (_qty - 1).clamp(1, maxQty),
                      ),
                      onPlus: () => setState(
                        () => _qty = (_qty + 1).clamp(1, maxQty),
                      ),
                      readOnly: !_canBuy,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle('THÔNG TIN SẢN PHẨM'),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      (p.description?.trim().isNotEmpty == true)
                          ? p.description!
                          : 'Nhà vườn chưa mô tả chi tiết.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (p.saleUnit?.traceValue != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _TraceQrBlock(
                        value: p.saleUnit!.traceValue!,
                        subtitle: p.saleUnit!.displayCode,
                        onOpen: () => context.push(
                          '/consumer/trace?code=${Uri.encodeComponent(p.saleUnit!.displayCode ?? p.saleUnit!.code)}',
                        ),
                      ),
                    ] else if (p.season != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InfoCard(
                        icon: Icons.qr_code_2_rounded,
                        label: 'TRUY XUẤT NGUỒN GỐC',
                        title: 'Xem truy xuất nguồn gốc',
                        subtitle: 'Mùa vụ: ${p.season!.code}',
                        onTap: () => context.push(
                          '/trace/season/${p.season!.id}',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _InfoCard(
                      icon: Icons.place_outlined,
                      label: 'CANH TÁC TẠI',
                      title: farm?.regionLine ?? '—',
                      subtitle: 'Bấm để xem bản đồ · chỉ đường',
                      enabled: farm != null &&
                          (farm.hasGeo ||
                              (farm.mapQuery ?? farm.regionLine) != null),
                      onTap: () => _openFarmMap(farm),
                    ),
                    if (p.season != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _InfoCard(
                        icon: Icons.calendar_month_outlined,
                        label: 'VỤ MÙA & CHUẨN',
                        title: '${p.season!.cropName} – ${p.season!.code}',
                        subtitle: [
                          if (Formatters.dateOrNull(p.season!.startDate) !=
                              null)
                            'Bắt đầu: ${Formatters.dateOrNull(p.season!.startDate)}',
                          if (Formatters.dateOrNull(
                                p.season!.harvestStartDate,
                              ) !=
                              null)
                            'Thu hoạch: ${Formatters.dateOrNull(p.season!.harvestStartDate)}',
                        ].join(' · '),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _ShopPanel(
                      shopName: p.shop?.name ?? shop?.name ?? 'Gian hàng',
                      initials: _shopInitials(
                        p.shop?.name ?? shop?.name ?? 'GH',
                      ),
                      activity: shop?.updatedAt != null
                          ? 'Hoạt động ${Formatters.activityAgo(shop!.updatedAt)}'
                          : 'Gian hàng Chuỗi Xanh Việt',
                      description:
                          shop?.description ?? p.shop?.description,
                      productCount: productCount,
                      region: farm?.regionLine,
                      certifications: certs,
                      chatLoading: _openingChat,
                      canChat: ownerId != null && ownerId.isNotEmpty,
                      onChat: () => _messageFarmer(ownerId),
                      onViewShop: () {
                        final id = shopId ?? p.shop?.id;
                        if (id == null || id.isEmpty) return;
                        context.push('/consumer/shop/$id');
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Đánh giá ($reviewCount)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (avg != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Trung bình: ${avg.toStringAsFixed(1)}★',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AsyncBody(
                      value: reviews.asLike,
                      emptyMessage: 'Chưa có đánh giá.',
                      isEmpty: (page) => page.items.isEmpty,
                      builder: (page) => Column(
                        children: [
                          for (final r in page.items.take(30))
                            _ReviewTile(
                              name: r.reviewerName ?? 'Người mua',
                              rating: r.rating,
                              comment: r.comment,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (p) {
          if (!_canBuy) return const SizedBox.shrink();
          final outOfStock = p.stockQty != null && p.stockQty! <= 0;
          return SafeArea(
            child: Container(
              padding: AppSpacing.screen,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          outOfStock ? null : () => _addToCart(p, goCart: false),
                      child: const Text('Thêm giỏ'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          outOfStock ? null : () => _addToCart(p, goCart: true),
                      child: const Text('Mua ngay'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl, required this.isVerified});

  final String? imageUrl;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = (w * 0.82).clamp(220.0, 360.0);
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.surfaceElevated,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? AppNetworkImage(url: imageUrl, height: h, borderRadius: BorderRadius.zero)
                : const Center(
                    child: Icon(
                      Icons.spa_outlined,
                      size: 56,
                      color: AppColors.muted,
                    ),
                  ),
          ),
          if (isVerified)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Đã xác minh nguồn gốc',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceQtyCard extends StatelessWidget {
  const _PriceQtyCard({
    required this.price,
    required this.unit,
    required this.qty,
    required this.canBuy,
    required this.onMinus,
    required this.onPlus,
    required this.readOnly,
  });

  final double price;
  final String unit;
  final int qty;
  final bool canBuy;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintDeep),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'GIÁ NÔNG HỘ',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
              ),
              const Spacer(),
              Text(
                readOnly ? 'Chỉ xem' : 'SỐ LƯỢNG',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: readOnly ? AppColors.muted : AppColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: Formatters.money(price),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                    children: [
                      TextSpan(
                        text: ' / $unit',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!readOnly)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: canBuy ? onMinus : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: canBuy ? onPlus : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final child = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.body),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}

class _TraceQrBlock extends StatelessWidget {
  const _TraceQrBlock({
    required this.value,
    this.subtitle,
    this.onOpen,
  });

  final String value;
  final String? subtitle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Text(
            'Truy xuất lô',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          QrImageView(
            data: value,
            size: 168,
            backgroundColor: Colors.white,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.forest,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Quét mã để xem nhật ký canh tác',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (onOpen != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpen,
              child: const Text('Mở trang truy xuất'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({
    required this.shopName,
    required this.initials,
    required this.activity,
    required this.chatLoading,
    required this.canChat,
    required this.onChat,
    required this.onViewShop,
    this.description,
    this.productCount = 0,
    this.region,
    this.certifications = const [],
  });

  final String shopName;
  final String initials;
  final String activity;
  final String? description;
  final int productCount;
  final String? region;
  final List<String> certifications;
  final bool chatLoading;
  final bool canChat;
  final VoidCallback onChat;
  final VoidCallback onViewShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.forest,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onViewShop,
                  child: Text(
                    shopName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(activity, style: Theme.of(context).textTheme.bodySmall),
                if (description != null && description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (productCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$productCount sản phẩm trong gian hàng',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (region != null && region!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Khu vực: $region',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (certifications.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in certifications)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.body,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: (!canChat || chatLoading) ? null : onChat,
                      icon: chatLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chat_outlined, size: 16),
                      label: Text(chatLoading ? 'Đang mở...' : 'Chat ngay'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onViewShop,
                      icon: const Icon(Icons.storefront_outlined, size: 16),
                      label: const Text('Xem gian hàng'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.name,
    required this.rating,
    this.comment,
  });

  final String name;
  final int rating;
  final String? comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceElevated,
                child: Icon(Icons.person, color: AppColors.muted, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '$rating★',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
