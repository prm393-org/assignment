import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Background / terminated isolate handler.
///
/// Must be a top-level function annotated `@pragma('vm:entry-point')`, or the
/// release build's tree-shaking removes it. This isolate shares no state with
/// the running app; the OS already renders `notification`-payload messages in
/// the system tray, so there is deliberately nothing to do here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// App-wide messenger key so a foreground push can show an in-app banner
/// without needing a `BuildContext`. Wired into `MaterialApp.router` in
/// `app.dart`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Thin wrapper over Firebase Cloud Messaging — **receive side only**.
/// Sending is done server-side by the relay worker (see `PushSender`); the
/// app never holds an FCM server credential.
class MessagingService {
  MessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  /// Received while the app is foregrounded (OS does *not* show a tray
  /// notification in this case — we surface an in-app banner instead).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// User tapped a tray notification and the app was in the background.
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The notification (if any) that cold-started the app from terminated.
  Future<RemoteMessage?> get initialMessage => _messaging.getInitialMessage();

  /// Fires when FCM rotates the device token.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Registers the background handler. Call once, before `runApp`.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Asks for the notification permission (Android 13+ shows a system
  /// dialog). Returns whether it is granted.
  Future<bool> requestPermission() async {
    try {
      return _granted(await _messaging.requestPermission());
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      return _granted(await _messaging.getNotificationSettings());
    } catch (_) {
      return false;
    }
  }

  static bool _granted(NotificationSettings s) =>
      s.authorizationStatus == AuthorizationStatus.authorized ||
      s.authorizationStatus == AuthorizationStatus.provisional;

  /// Device token — paste into Firebase Console → Messaging to send a test.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      // Emulators without Google Play Services throw here.
      return null;
    }
  }

  Future<void> subscribe(String topic) async {
    if (topic.isEmpty) return;
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (_) {}
  }

  Future<void> unsubscribe(String topic) async {
    if (topic.isEmpty) return;
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (_) {}
  }
}
