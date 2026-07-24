import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chuoi_xanh_viet/core/firebase/analytics_service.dart';
import 'package:chuoi_xanh_viet/core/widgets/async_states.dart';
import 'package:chuoi_xanh_viet/core/widgets/role_shell.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/screens/admin_audit_logs_screen.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/screens/admin_broadcast_screen.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/screens/admin_certificates_screen.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/screens/admin_home_screen.dart';
import 'package:chuoi_xanh_viet/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:chuoi_xanh_viet/features/agri_trend/presentation/screens/agri_trend_screen.dart';
import 'package:chuoi_xanh_viet/features/ai/presentation/screens/ai_assistant_screen.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/screens/login_screen.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/screens/register_screen.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/screens/splash_screen.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/screens/welcome_screen.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/screens/cart_screen.dart';
import 'package:chuoi_xanh_viet/features/cart/presentation/screens/checkout_screen.dart';
import 'package:chuoi_xanh_viet/features/certificate/presentation/screens/certificates_screen.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/screens/chat_thread_screen.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/screens/conversations_screen.dart';
import 'package:chuoi_xanh_viet/features/cooperative/presentation/screens/join_cooperative_confirm_screen.dart';
import 'package:chuoi_xanh_viet/features/cooperative/presentation/screens/join_cooperative_screen.dart';
import 'package:chuoi_xanh_viet/features/cooperative/presentation/screens/register_farmer_applicant_screen.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/screens/diary_dashboard_screen.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/screens/farm_detail_screen.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/screens/farm_form_screen.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/screens/farmer_home_screen.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/screens/farms_list_screen.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/screens/season_detail_screen.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/screens/create_forum_post_screen.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/screens/forum_list_screen.dart';
import 'package:chuoi_xanh_viet/features/forum/presentation/screens/forum_post_screen.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/screens/consumer_home_screen.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/screens/product_detail_screen.dart';
import 'package:chuoi_xanh_viet/features/marketplace/presentation/screens/shop_detail_screen.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/screens/notifications_screen.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/screens/earnings_screen.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/screens/order_detail_screen.dart';
import 'package:chuoi_xanh_viet/features/order/presentation/screens/orders_screen.dart';
import 'package:chuoi_xanh_viet/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:chuoi_xanh_viet/features/profile/presentation/screens/profile_screen.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/screens/add_product_screen.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/screens/shop_detail_manage_screen.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/screens/shop_manage_screen.dart';
import 'package:chuoi_xanh_viet/features/trace/presentation/screens/qr_scan_screen.dart';
import 'package:chuoi_xanh_viet/features/trace/presentation/screens/trace_resolve_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Guest may browse marketplace/forum read-only; write routes require login.
bool _isGuestBrowsePath(String loc) {
  if (loc.startsWith('/trace')) return true;
  if (loc == '/qr-scan') return true;

  const exact = {
    '/consumer/home',
    '/consumer/marketplace',
    '/consumer/forum',
    '/consumer/orders',
    '/consumer/me',
    '/consumer/cart',
    '/consumer/trace',
    '/consumer/trace/scan',
  };
  if (exact.contains(loc)) return true;
  if (loc.startsWith('/consumer/product/')) return true;
  if (loc.startsWith('/consumer/shop/')) return true;
  // Forum post detail (not create/edit).
  final forumDetail = RegExp(r'^/consumer/forum/([^/]+)$').firstMatch(loc);
  if (forumDetail != null) {
    final id = forumDetail.group(1)!;
    return id != 'create';
  }
  return false;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authNotifierProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;
      final bootstrapping = auth.isBootstrapping;
      final loggedIn = auth.isAuthenticated;
      final role = auth.role;
      final isAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/register-farmer-applicant' ||
          loc == '/welcome' ||
          loc == '/';

      if (bootstrapping) {
        return loc == '/' ? null : '/';
      }
      if (!loggedIn) {
        final isGuestOk =
            _isGuestBrowsePath(loc) || (isAuthRoute && loc != '/');
        if (loc == '/') return '/welcome';
        if (isGuestOk) return null;
        return '/login';
      }
      if (loc == '/' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/register-farmer-applicant' ||
          loc == '/welcome') {
        return roleHomePath(role);
      }
      if (loc.startsWith('/consumer') &&
          role != AuthRole.consumer &&
          role != AuthRole.cooperative) {
        return roleHomePath(role);
      }
      if (loc.startsWith('/farmer') && role != AuthRole.farmer) {
        return roleHomePath(role);
      }
      if (loc.startsWith('/admin') && role != AuthRole.admin) {
        return roleHomePath(role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          initialToken: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: '/register-farmer-applicant',
        builder: (_, _) => const RegisterFarmerApplicantScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/qr-scan',
        redirect: (_, _) => '/consumer/trace/scan',
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => RoleShell(
          navigationShell: shell,
          destinations: const [
            ShellDestination(
              path: '/consumer/home',
              label: 'Trang chủ',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
            ),
            ShellDestination(
              path: '/consumer/marketplace',
              label: 'Chợ',
              icon: Icons.storefront_outlined,
              selectedIcon: Icons.storefront,
            ),
            ShellDestination(
              path: '/consumer/forum',
              label: 'Diễn đàn',
              icon: Icons.forum_outlined,
              selectedIcon: Icons.forum,
            ),
            ShellDestination(
              path: '/consumer/orders',
              label: 'Đơn',
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
            ),
            ShellDestination(
              path: '/consumer/me',
              label: 'Tôi',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumer/home',
              builder: (_, _) => const ConsumerHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumer/marketplace',
              builder: (_, state) => MarketplaceScreen(
                initialQuery: state.uri.queryParameters['q'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumer/forum',
              builder: (_, _) => const ForumListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumer/orders',
              builder: (_, _) => const OrdersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumer/me',
              builder: (_, _) => const ProfileScreen(
                roleLinks: [
                  ProfileLink(
                    label: 'Sửa hồ sơ',
                    path: '/profile/edit',
                    icon: Icons.edit_outlined,
                  ),
                  ProfileLink(
                    label: 'Giỏ hàng',
                    path: '/consumer/cart',
                    icon: Icons.shopping_cart_outlined,
                  ),
                  ProfileLink(
                    label: 'Truy xuất nguồn gốc',
                    path: '/consumer/trace',
                    icon: Icons.qr_code_2,
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/consumer/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/consumer/shop/:id',
        builder: (_, state) =>
            ShopDetailScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/consumer/cart', builder: (_, _) => const CartScreen()),
      GoRoute(
        path: '/consumer/checkout',
        builder: (_, _) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/consumer/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/consumer/forum/create',
        builder: (_, _) => const CreateForumPostScreen(),
      ),
      GoRoute(
        path: '/consumer/forum/:id/edit',
        builder: (_, state) => CreateForumPostScreen(
          editPostId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/consumer/forum/:id',
        builder: (_, state) => ForumPostScreen(
          postId: state.pathParameters['id']!,
          basePath: '/consumer',
        ),
      ),
      GoRoute(
        path: '/consumer/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/consumer/trace',
        builder: (_, state) => TraceResolveScreen(
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/consumer/trace/scan',
        builder: (_, _) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/trace/season/:id',
        builder: (_, state) => TraceDetailScreen(
          seasonId: state.pathParameters['id']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => RoleShell(
          navigationShell: shell,
          destinations: const [
            ShellDestination(
              path: '/farmer/home',
              label: 'Trang chủ',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
            ),
            ShellDestination(
              path: '/farmer/farms',
              label: 'Nông trại',
              icon: Icons.agriculture_outlined,
              selectedIcon: Icons.agriculture,
            ),
            ShellDestination(
              path: '/farmer/forum',
              label: 'Diễn đàn',
              icon: Icons.forum_outlined,
              selectedIcon: Icons.forum,
            ),
            ShellDestination(
              path: '/farmer/shop',
              label: 'Gian hàng',
              icon: Icons.storefront_outlined,
              selectedIcon: Icons.storefront,
            ),
            ShellDestination(
              path: '/farmer/me',
              label: 'Tôi',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/farmer/home',
              builder: (_, _) => const FarmerHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/farmer/farms',
              builder: (_, _) => const FarmsListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/farmer/forum',
              builder: (_, _) =>
                  const ForumListScreen(basePath: '/farmer'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/farmer/shop',
              builder: (_, _) => const ShopManageScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/farmer/me',
              builder: (_, _) => const ProfileScreen(
                roleLinks: [
                  ProfileLink(
                    label: 'Sửa hồ sơ',
                    path: '/profile/edit',
                    icon: Icons.edit_outlined,
                  ),
                  ProfileLink(
                    label: 'Nhật ký',
                    path: '/farmer/diary',
                    icon: Icons.menu_book_outlined,
                  ),
                  ProfileLink(
                    label: 'Truy xuất',
                    path: '/farmer/trace',
                    icon: Icons.qr_code_2,
                  ),
                  ProfileLink(
                    label: 'Đơn bán',
                    path: '/farmer/orders',
                    icon: Icons.receipt_long,
                  ),
                  ProfileLink(
                    label: 'Doanh thu',
                    path: '/farmer/earnings',
                    icon: Icons.payments_outlined,
                  ),
                  ProfileLink(
                    label: 'Chứng nhận',
                    path: '/farmer/certificates',
                    icon: Icons.verified_outlined,
                  ),
                  ProfileLink(
                    label: 'Trợ lý AI',
                    path: '/farmer/ai',
                    icon: Icons.smart_toy_outlined,
                  ),
                  ProfileLink(
                    label: 'Xu hướng NN',
                    path: '/farmer/agri-trend',
                    icon: Icons.trending_up,
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/farmer/farms/create',
        builder: (_, _) => const FarmFormScreen(),
      ),
      GoRoute(
        path: '/farmer/farms/:id',
        builder: (_, state) =>
            FarmDetailScreen(farmId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/farms/:id/join-htx',
        builder: (_, state) => JoinCooperativeScreen(
          farmId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/farmer/farms/:id/join-htx/:htxId',
        builder: (_, state) => JoinCooperativeConfirmScreen(
          farmId: state.pathParameters['id']!,
          htxId: state.pathParameters['htxId']!,
        ),
      ),
      GoRoute(
        path: '/farmer/farms/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return Consumer(
            builder: (context, ref, _) {
              final async = ref.watch(myFarmsProvider);
              return async.when(
                loading: () => const Scaffold(
                  body: LoadingView(message: 'Đang tải nông trại…'),
                ),
                error: (e, _) => Scaffold(
                  appBar: AppBar(title: const Text('Sửa nông trại')),
                  body: ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(myFarmsProvider),
                  ),
                ),
                data: (farms) {
                  final farm = farms.where((f) => f.id == id).firstOrNull;
                  if (farm == null) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Sửa nông trại')),
                      body: EmptyState(
                        message: 'Không tìm thấy nông trại',
                        actionLabel: 'Quay lại',
                        onAction: () => context.pop(),
                      ),
                    );
                  }
                  return FarmFormScreen(farm: farm);
                },
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/farmer/seasons/:id',
        builder: (_, state) =>
            SeasonDetailScreen(seasonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/orders',
        builder: (_, _) => const OrdersScreen(isSeller: true),
      ),
      GoRoute(
        path: '/farmer/orders/:id',
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
          isSeller: true,
        ),
      ),
      GoRoute(
        path: '/farmer/earnings',
        builder: (_, _) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/farmer/certificates',
        builder: (_, _) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/farmer/ai',
        builder: (_, _) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/farmer/agri-trend',
        builder: (_, _) => const AgriTrendScreen(),
      ),
      GoRoute(
        path: '/farmer/shop/:id',
        builder: (_, state) =>
            ShopDetailManageScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/shop/:id/add-product',
        builder: (_, state) =>
            AddProductScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/diary',
        builder: (_, _) => const DiaryDashboardScreen(),
      ),
      GoRoute(
        path: '/farmer/trace',
        builder: (_, state) => TraceResolveScreen(
          initialCode: state.uri.queryParameters['code'],
          scanPath: '/farmer/trace/scan',
        ),
      ),
      GoRoute(
        path: '/farmer/trace/scan',
        builder: (_, _) =>
            const QrScanScreen(resultPath: '/farmer/trace'),
      ),
      GoRoute(
        path: '/farmer/forum/create',
        builder: (_, _) => const CreateForumPostScreen(),
      ),
      GoRoute(
        path: '/farmer/forum/:id/edit',
        builder: (_, state) => CreateForumPostScreen(
          editPostId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/farmer/forum/:id',
        builder: (_, state) => ForumPostScreen(
          postId: state.pathParameters['id']!,
          basePath: '/farmer',
        ),
      ),
      GoRoute(
        path: '/farmer/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => RoleShell(
          navigationShell: shell,
          destinations: const [
            ShellDestination(
              path: '/admin/home',
              label: 'Tổng quan',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
            ),
            ShellDestination(
              path: '/admin/users',
              label: 'Người dùng',
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
            ),
            ShellDestination(
              path: '/admin/me',
              label: 'Tôi',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/home',
              builder: (_, _) => const AdminHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/users',
              builder: (_, _) => const AdminUsersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/me',
              builder: (_, _) => const ProfileScreen(
                roleLinks: [
                  ProfileLink(
                    label: 'Sửa hồ sơ',
                    path: '/profile/edit',
                    icon: Icons.edit_outlined,
                  ),
                  ProfileLink(
                    label: 'Chứng nhận chờ',
                    path: '/admin/certificates',
                    icon: Icons.verified_user,
                  ),
                  ProfileLink(
                    label: 'Broadcast',
                    path: '/admin/broadcast',
                    icon: Icons.campaign,
                  ),
                  ProfileLink(
                    label: 'Audit logs',
                    path: '/admin/audit-logs',
                    icon: Icons.history,
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/admin/certificates',
        builder: (_, _) => const AdminCertificatesScreen(),
      ),
      GoRoute(
        path: '/admin/broadcast',
        builder: (_, _) => const AdminBroadcastScreen(),
      ),
      GoRoute(
        path: '/admin/audit-logs',
        builder: (_, _) => const AdminAuditLogsScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (_, _) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/consumer/chat',
        builder: (_, _) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/consumer/chat/:id',
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/farmer/chat',
        builder: (_, _) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/farmer/chat/:id',
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/chat',
        builder: (_, _) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/admin/chat/:id',
        builder: (_, state) => ChatThreadScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  String? lastScreen;
  void trackCurrentScreen() {
    if (router.routerDelegate.currentConfiguration.isEmpty) return;
    final state = router.routerDelegate.state;
    final screen = state.fullPath ?? state.matchedLocation;
    if (screen.isEmpty || screen == lastScreen) return;
    lastScreen = screen;
    unawaited(AnalyticsService.logScreenView(screen));
  }

  router.routerDelegate.addListener(trackCurrentScreen);
  WidgetsBinding.instance.addPostFrameCallback((_) => trackCurrentScreen());
  ref.onDispose(
    () => router.routerDelegate.removeListener(trackCurrentScreen),
  );
  return router;
});
