/// Config for the outbound push relay (Phase 4).
///
/// Firebase Cloud Messaging cannot be sent directly from the app (that needs
/// a trusted server credential). This app relays sends through a tiny
/// serverless worker (see `push-worker/`). Values are read from
/// `--dart-define` so no secret/URL is hard-coded in source (keeps the AI
/// code review clean):
///
/// ```
/// flutter run \
///   --dart-define=PUSH_ENDPOINT=https://chuoi-push.<sub>.workers.dev/send \
///   --dart-define=PUSH_API_KEY=<shared-secret>
/// ```
///
/// Leave [endpoint] empty to disable outbound push entirely — the app still
/// **receives** pushes sent manually from the Firebase Console, and every
/// in-app notification (Firestore inbox + RTDB unread badge) keeps working.
class PushConfig {
  PushConfig._();

  static const String endpoint =
      String.fromEnvironment('PUSH_ENDPOINT', defaultValue: '');

  static const String apiKey =
      String.fromEnvironment('PUSH_API_KEY', defaultValue: '');

  static bool get isConfigured => endpoint.isNotEmpty;
}
