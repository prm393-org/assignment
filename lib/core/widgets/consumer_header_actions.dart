import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/providers/cart_provider.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/providers/notification_providers.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/providers/order_providers.dart';

const _headerBadgeBackground = AppColors.forest;
const _headerBadgeForeground = AppColors.onPrimary;

/// QR + notifications + cart — shared across consumer shell tabs (not profile).
class ConsumerHeaderActions extends ConsumerWidget {
  const ConsumerHeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;
    final unreadNotif = isAuthenticated
        ? (ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0)
        : 0;
    final unreadChat =
        isAuthenticated ? ref.watch(unreadChatCountProvider) : 0;
    final cartCount = ref.watch(cartCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BadgedRoundAction(
          icon: Icons.notifications_none_rounded,
          badge: unreadNotif > 0 ? (unreadNotif > 99 ? '99+' : '$unreadNotif') : null,
          badgeBackground: _headerBadgeBackground,
          badgeForeground: _headerBadgeForeground,
          onTap: () {
            if (!isAuthenticated) {
              context.push('/login');
              return;
            }
            context.push('/consumer/notifications');
          },
        ),
        _BadgedRoundAction(
          icon: Icons.shopping_bag_outlined,
          badge: cartCount > 0 ? '$cartCount' : null,
          badgeBackground: _headerBadgeBackground,
          badgeForeground: _headerBadgeForeground,
          onTap: () => context.push('/consumer/cart'),
        ),
        _BadgedRoundAction(
          icon: Icons.chat_bubble_outline_rounded,
          badge: unreadChat > 0 ? (unreadChat > 99 ? '99+' : '$unreadChat') : null,
          badgeBackground: _headerBadgeBackground,
          badgeForeground: _headerBadgeForeground,
          onTap: () {
            if (!isAuthenticated) {
              context.push('/login');
              return;
            }
            context.push('/consumer/chat');
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

/// QR + notifications + đơn bán — farmer shell tabs (not profile).
class FarmerHeaderActions extends ConsumerWidget {
  const FarmerHeaderActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotif =
        ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
    final unreadChat = ref.watch(unreadChatCountProvider);
    final pendingOrders = ref.watch(shopOrdersProvider).valueOrNull?.items
            .where((o) => o.status.toLowerCase() == 'pending')
            .length ??
        0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundAction(
          icon: Icons.qr_code_scanner_rounded,
          onTap: () => context.push('/farmer/trace/scan'),
        ),
        _BadgedRoundAction(
          icon: Icons.notifications_none_rounded,
          badge: unreadNotif > 0 ? (unreadNotif > 99 ? '99+' : '$unreadNotif') : null,
          badgeBackground: _headerBadgeBackground,
          badgeForeground: _headerBadgeForeground,
          onTap: () => context.push('/farmer/notifications'),
        ),
        _BadgedRoundAction(
          icon: Icons.receipt_long_outlined,
          badge: pendingOrders > 0
              ? (pendingOrders > 99 ? '99+' : '$pendingOrders')
              : null,
          badgeBackground: _headerBadgeBackground,
          badgeForeground: _headerBadgeForeground,
          onTap: () => context.push('/farmer/orders'),
        ),
        _BadgedRoundAction(
          icon: Icons.chat_bubble_outline_rounded,
          badge: unreadChat > 0 ? (unreadChat > 99 ? '99+' : '$unreadChat') : null,
          badgeBackground: _headerBadgeBackground,
          badgeForeground: _headerBadgeForeground,
          onTap: () => context.push('/farmer/chat'),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

class ConsumerTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ConsumerTabAppBar({
    super.key,
    required this.subtitle,
    required this.title,
  });

  final String subtitle;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return _RoleTabAppBar(
      subtitle: subtitle,
      title: title,
      actions: const ConsumerHeaderActions(),
    );
  }
}

class FarmerTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FarmerTabAppBar({
    super.key,
    required this.subtitle,
    required this.title,
  });

  final String subtitle;
  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return _RoleTabAppBar(
      subtitle: subtitle,
      title: title,
      actions: const FarmerHeaderActions(),
    );
  }
}

class _RoleTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _RoleTabAppBar({
    required this.subtitle,
    required this.title,
    required this.actions,
  });

  final String subtitle;
  final String title;
  final Widget actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      titleSpacing: AppSpacing.lg,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: [actions],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceElevated,
          foregroundColor: AppColors.ink,
        ),
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

class _BadgedRoundAction extends StatelessWidget {
  const _BadgedRoundAction({
    required this.icon,
    required this.onTap,
    this.badge,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final Color badgeBackground;
  final Color badgeForeground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              foregroundColor: AppColors.ink,
            ),
            onPressed: onTap,
            icon: Icon(icon),
          ),
          if (badge != null)
            Positioned(
              right: 6,
              top: 6,
              child: IgnorePointer(
                child: _CountBadge(
                  label: badge!,
                  background: badgeBackground,
                  foreground: badgeForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
