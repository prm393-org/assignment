import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chuoi_xanh_viet/core/firebase/messaging_service.dart';
import 'package:chuoi_xanh_viet/core/router/app_router.dart';
import 'package:chuoi_xanh_viet/core/theme/app_theme.dart';
import 'package:chuoi_xanh_viet/features/chat/presentation/providers/chat_providers.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/providers/messaging_providers.dart';

class ChuoiXanhVietApp extends ConsumerWidget {
  const ChuoiXanhVietApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep presence + Crashlytics user binding app-wide.
    ref.watch(presenceBindingProvider);
    // Register FCM on sign-in and route/surface incoming pushes app-wide.
    ref.watch(messagingBindingProvider);
    ref.watch(fcmMessageListenerProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Chuỗi Xanh Việt',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
