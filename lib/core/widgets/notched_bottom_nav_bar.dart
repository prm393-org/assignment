import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/shell_navigation_models.dart';

const kNotchedBottomNavBarHeight = 80.0;

const _notchRadius = 35.0;
const _notchMargin = 3.0;
const _notchDepth = 16.0;
const _centerButtonSize = 68.0;
const _navIconSize = 24.0;
const _navItemPadding = 8.0;
const _barHeight = kNotchedBottomNavBarHeight;
const _centerButtonBottom = 33.0;

class NotchedBottomNavBar extends StatelessWidget {
  const NotchedBottomNavBar({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.centerAction,
    required this.onCenterTap,
  });

  final List<NotchedNavItem> leftItems;
  final List<NotchedNavItem> rightItems;
  final ShellCenterAction centerAction;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    final centerGap = (_notchRadius + _notchMargin) * 2;

    return SizedBox(
      height: _barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NotchedNavBarPainter(
                notchRadius: _notchRadius,
                notchMargin: _notchMargin,
                notchDepth: _notchDepth,
                backgroundColor: AppColors.surface,
                shadowColor: AppColors.hairline.withValues(alpha: 0.85),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.sm,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final item in leftItems) _NavItemTile(item: item),
                    ],
                  ),
                ),
                SizedBox(width: centerGap),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final item in rightItems) _NavItemTile(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: _centerButtonBottom,
            child: _CenterQrButton(
              action: centerAction,
              onTap: onCenterTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({required this.item});

  final NotchedNavItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.selected ? AppColors.forest : AppColors.muted;
    final icon = item.selected
        ? (item.destination.selectedIcon ?? item.destination.icon)
        : item.destination.icon;

    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(_navItemPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _navIconSize, color: color),
            const SizedBox(height: 2),
            Text(
              item.destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: item.selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterQrButton extends StatelessWidget {
  const _CenterQrButton({
    required this.action,
    required this.onTap,
  });

  final ShellCenterAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _centerButtonSize,
        height: _centerButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(60, 60),
              painter: _DashedCirclePainter(
                color: AppColors.forest,
                strokeWidth: 2,
                dashWidth: 4,
                dashSpace: 3,
              ),
            ),
            Icon(
              action.icon,
              color: AppColors.forest,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchedNavBarPainter extends CustomPainter {
  _NotchedNavBarPainter({
    required this.notchRadius,
    required this.notchMargin,
    required this.notchDepth,
    required this.backgroundColor,
    required this.shadowColor,
  });

  final double notchRadius;
  final double notchMargin;
  final double notchDepth;
  final Color backgroundColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = _createNotchedPath(size);
    canvas.drawPath(path.shift(const Offset(0, -3)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  Path _createNotchedPath(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final totalNotchRadius = notchRadius + notchMargin;
    final navBarTop = notchDepth;
    const cornerRadius = 10.0;
    const topLeftRadius = 1.0;
    const topRightRadius = 2.0;
    const bottomRightRadius = 2.0;
    const bottomLeftRadius = 2.0;

    path.moveTo(0, navBarTop + topLeftRadius);
    path.quadraticBezierTo(0, navBarTop, topLeftRadius, navBarTop);
    path.lineTo(centerX - totalNotchRadius - cornerRadius, navBarTop);
    path.quadraticBezierTo(
      centerX - totalNotchRadius,
      navBarTop,
      centerX - totalNotchRadius,
      navBarTop + cornerRadius,
    );
    path.arcToPoint(
      Offset(centerX + totalNotchRadius, navBarTop + cornerRadius),
      radius: Radius.circular(totalNotchRadius + cornerRadius * 0.15),
      clockwise: false,
    );
    path.quadraticBezierTo(
      centerX + totalNotchRadius,
      navBarTop,
      centerX + totalNotchRadius + cornerRadius,
      navBarTop,
    );
    path.lineTo(size.width - topRightRadius, navBarTop);
    path.quadraticBezierTo(
      size.width,
      navBarTop,
      size.width,
      navBarTop + topRightRadius,
    );
    path.lineTo(size.width, size.height - bottomRightRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - bottomRightRadius,
      size.height,
    );
    path.lineTo(bottomLeftRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - bottomLeftRadius);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _NotchedNavBarPainter oldDelegate) {
    return oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchMargin != notchMargin ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final dashAngle = (2 * math.pi) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweep = dashWidth / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}

/// Bottom space occupied by consumer notched nav (bar + home indicator).
double consumerShellBottomInset(BuildContext context) {
  return kNotchedBottomNavBarHeight + MediaQuery.paddingOf(context).bottom;
}

/// Places FAB above the consumer shell bottom nav.
class FabAboveShellNavLocation extends FloatingActionButtonLocation {
  const FabAboveShellNavLocation({this.horizontalPadding = 16, this.gap = 16});

  final double horizontalPadding;
  final double gap;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final bottom =
        kNotchedBottomNavBarHeight + scaffoldGeometry.minInsets.bottom + gap;
    return Offset(
      scaffoldGeometry.scaffoldSize.width - fabSize.width - horizontalPadding,
      scaffoldGeometry.scaffoldSize.height - fabSize.height - bottom,
    );
  }
}
