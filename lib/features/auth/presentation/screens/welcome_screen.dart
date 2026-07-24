import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkGreen,
                  AppColors.forest,
                  AppColors.forestBright,
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            top: size.height * 0.08,
            right: -size.width * 0.18,
            child: _Blob(size: size.width * 0.55, opacity: 0.07),
          ),
          Positioned(
            bottom: size.height * 0.18,
            left: -size.width * 0.2,
            child: _Blob(size: size.width * 0.5, opacity: 0.1, lime: true),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.onPrimary.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: Text(
                            'Nông sản  ·  Truy xuất  ·  Cộng đồng',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.onPrimary.withValues(
                                alpha: 0.22,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 48,
                            color: AppColors.lime,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Chuỗi Xanh Việt',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            'Kết nối nông hộ và người mua với chuỗi cung ứng minh bạch, hiện đại.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.onPrimary.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.darkGreen,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.go('/login'),
                    child: const Text('Đăng nhập'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.go('/register'),
                    child: const Text('Tạo tài khoản'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.go('/consumer/marketplace'),
                    child: Text(
                      'Khám phá chợ ngay',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
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

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.opacity, this.lime = false});

  final double size;
  final double opacity;
  final bool lime;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (lime ? AppColors.lime : Colors.white).withValues(
            alpha: opacity,
          ),
        ),
      ),
    );
  }
}
