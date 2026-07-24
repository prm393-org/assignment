import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chuoi_xanh_viet/core/firebase/crashlytics_service.dart';
import 'package:chuoi_xanh_viet/core/firebase/current_uid_provider.dart';
import 'package:chuoi_xanh_viet/core/firebase/fcm_token_store.dart';
import 'package:chuoi_xanh_viet/core/firebase/fcm_topics.dart';
import 'package:chuoi_xanh_viet/core/firebase/messaging_service.dart';
import 'package:chuoi_xanh_viet/core/router/app_router.dart';
import 'package:chuoi_xanh_viet/features/auth/domain/entities/auth_role.dart';
import 'package:chuoi_xanh_viet/features/auth/presentation/providers/auth_notifier.dart';
import 'package:chuoi_xanh_viet/features/farm/presentation/providers/farm_providers.dart';
import 'package:chuoi_xanh_viet/features/notification/presentation/notification_navigation.dart';
import 'package:chuoi_xanh_viet/features/shop_manage/presentation/providers/shop_manage_providers.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

/// Registers FCM whenever a user signs in and cleans up on logout — the
/// direct analogue of `presenceBindingProvider`. Watched (not read) app-wide
/// from `app.dart` so it lives for the whole session.
///
/// Targeting is topic-only, so registration is just: ask permission, cache
/// the token (for Console tests), and subscribe to the topics that identify
/// this user. Farmers additionally subscribe to their shops (new-order push)
/// and farms (certificate push) so senders never need the farmer's uid.
final messagingBindingProvider = Provider<void>((ref) {
  final messaging = ref.watch(messagingServiceProvider);
  final subscribed = <String>{};
  String? registeredUid;
  String? registeredToken;
  StreamSubscription<String>? tokenRefreshSub;

  Future<void> subscribe(String topic) async {
    await messaging.subscribe(topic);
    subscribed.add(topic);
  }

  Future<void> registerFor(AuthState auth, String uid) async {
    registeredUid = uid;
    final role = auth.role;
    final backendId = auth.user?.id;

    await messaging.requestPermission();

    await subscribe(FcmTopics.broadcast);
    await subscribe(FcmTopics.userByFirebaseUid(uid));
    if (role != null) await subscribe(FcmTopics.role(role.name));
    if (backendId != null && backendId.isNotEmpty) {
      await subscribe(FcmTopics.userByBackendId(backendId));
    }

    if (role == AuthRole.farmer || role == AuthRole.cooperative) {
      try {
        final shops = await ref.read(shopManageRepositoryProvider).getMyShops();
        for (final s in shops) {
          await subscribe(FcmTopics.shop(s.id));
        }
      } catch (_) {}
      try {
        final farms = await ref.read(farmRepositoryProvider).getMyFarms();
        for (final f in farms) {
          await subscribe(FcmTopics.farm(f.id));
        }
      } catch (_) {}
    }

    final token = await messaging.getToken();
    registeredToken = token;
    if (token != null) {
      if (kDebugMode) debugPrint('FCM_TOKEN=$token');
      await FcmTokenStore.saveToken(
        firebaseUid: uid,
        token: token,
        backendUserId: backendId,
        role: role?.name,
        platform: _platform(),
      );
    }

    await tokenRefreshSub?.cancel();
    tokenRefreshSub = messaging.onTokenRefresh.listen((t) {
      registeredToken = t;
      unawaited(FcmTokenStore.saveToken(
        firebaseUid: uid,
        token: t,
        backendUserId: backendId,
        role: role?.name,
        platform: _platform(),
      ));
    });

    unawaited(
      CrashlyticsService.breadcrumb('fcm_registered role=${role?.name}'),
    );
  }

  Future<void> cleanup() async {
    await tokenRefreshSub?.cancel();
    tokenRefreshSub = null;
    final uid = registeredUid;
    final token = registeredToken;
    for (final topic in subscribed) {
      await messaging.unsubscribe(topic);
    }
    subscribed.clear();
    if (uid != null && token != null) {
      await FcmTokenStore.removeToken(firebaseUid: uid, token: token);
    }
    registeredUid = null;
    registeredToken = null;
  }

  ref.listen<AuthState>(authNotifierProvider, (prev, next) async {
    final uid = ref.read(currentFirebaseUidProvider);
    if (next.isAuthenticated && uid != null) {
      if (registeredUid == uid) return;
      await registerFor(next, uid);
    } else if (prev?.isAuthenticated == true && !next.isAuthenticated) {
      await cleanup();
    }
  }, fireImmediately: true);

  // The Firebase shadow sign-in can resolve slightly after the backend
  // session, so the uid may arrive on a later tick than `isAuthenticated`.
  ref.listen<String?>(currentFirebaseUidProvider, (prev, next) async {
    final auth = ref.read(authNotifierProvider);
    if (auth.isAuthenticated && next != null && next != registeredUid) {
      await registerFor(auth, next);
    }
  });

  ref.onDispose(() {
    // ignore: discarded_futures
    tokenRefreshSub?.cancel();
  });
});

/// Surfaces incoming pushes: a foreground push shows an in-app banner; a
/// tapped push (from background or a cold start) deep-links via the existing
/// [resolveNotificationRoute]. Watched app-wide from `app.dart`.
final fcmMessageListenerProvider = Provider<void>((ref) {
  final messaging = ref.watch(messagingServiceProvider);

  void openLink(String? link) {
    if (link == null || link.isEmpty) return;
    final role = ref.read(authNotifierProvider).role;
    final route = resolveNotificationRoute(link, role: role);
    if (route == null) return;
    ref.read(appRouterProvider).go(route);
  }

  void showForeground(RemoteMessage m) {
    final n = m.notification;
    final title = n?.title ?? m.data['title']?.toString() ?? 'Thông báo';
    final body = n?.body ?? m.data['body']?.toString() ?? '';
    final link = m.data['link']?.toString();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title — $body'),
        action: (link == null || link.isEmpty)
            ? null
            : SnackBarAction(label: 'Xem', onPressed: () => openLink(link)),
      ),
    );
  }

  final foreground = messaging.onMessage.listen(showForeground);
  final opened = messaging.onMessageOpenedApp
      .listen((m) => openLink(m.data['link']?.toString()));
  // A notification that cold-started the app from terminated.
  messaging.initialMessage.then((m) {
    if (m != null) openLink(m.data['link']?.toString());
  });

  ref.onDispose(() {
    foreground.cancel();
    opened.cancel();
  });
});

String _platform() => kIsWeb ? 'web' : defaultTargetPlatform.name;
