import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/constants/app_spacing.dart';
import 'package:chuoi_xanh_viet/core/theme/app_colors.dart';
import 'package:chuoi_xanh_viet/core/widgets/ui_kit.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.roleLinks = const []});

  final List<ProfileLink> roleLinks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;
    final isGuest = !auth.isAuthenticated;
    final initial = (user?.fullName.isNotEmpty == true)
        ? user!.fullName.characters.first.toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        actions: [
          if (!isGuest)
            TextButton(
              onPressed: () => context.push('/profile/edit'),
              child: const Text('Sửa'),
            ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.mint, AppColors.mintDeep],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    isGuest ? '?' : initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGuest ? 'Khách' : (user?.fullName ?? 'Khách'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      if (isGuest)
                        Text(
                          'Dùng chợ và xem sản phẩm không cần đăng nhập. '
                          'Đăng nhập để đặt hàng, xem đơn và tin nhắn.',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else ...[
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (user?.phone != null && user!.phone.isNotEmpty)
                          Text(
                            user.phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (user?.authRole != null) ...[
                          const SizedBox(height: 8),
                          Chip(label: Text(roleLabel(user!.authRole!))),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isGuest) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Đăng ký'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Tiện ích', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final link in roleLinks)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(link.icon, color: AppColors.forest, size: 20),
                    ),
                    title: Text(link.label),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      if (isGuest &&
                          (link.path.contains('cart') ||
                              link.path.contains('orders') ||
                              link.path.contains('chat'))) {
                        context.push('/login');
                        return;
                      }
                      context.push(link.path);
                    },
                  ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.forest,
                      size: 20,
                    ),
                  ),
                  title: const Text('Tin nhắn'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      context.push(isGuest ? '/login' : '/chat'),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.forest,
                      size: 20,
                    ),
                  ),
                  title: const Text('Thông báo'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    if (isGuest) {
                      context.push('/login');
                      return;
                    }
                    final base = roleHomePath(auth.role);
                    context.push('$base/notifications');
                  },
                ),
              ],
            ),
          ),
          if (!isGuest) ...[
            const SizedBox(height: AppSpacing.lg),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/welcome');
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class ProfileLink {
  const ProfileLink({
    required this.label,
    required this.path,
    required this.icon,
  });
  final String label;
  final String path;
  final IconData icon;
}
