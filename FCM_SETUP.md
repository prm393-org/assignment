# FCM — Push Notifications (Task 4.6)

Free, no credit card. Two delivery channels:

| Channel | When | Cost | Needs |
|---------|------|------|-------|
| **In-app** — Firestore inbox + live badge | app open | 0đ | nothing extra (already worked) |
| **Device push** — system-tray notification | app closed/background | 0đ | Cloudflare Worker *or* manual Console send |

The 5 required pushes all fire through topics (no server credential in the app):

| Push | Trigger | Topic |
|------|---------|-------|
| Đơn mới → farmer | consumer creates order | `shop_<shopId>` |
| Cập nhật trạng thái đơn → consumer | farmer updates/cancels order | `order_<orderId>` |
| Duyệt/từ chối chứng nhận → farmer | admin approve/reject | `farm_<farmId>` |
| Broadcast từ admin | admin broadcast | `broadcast` or `role_<audience>` |
| Chat / forum reply | send message / comment | `ub_<peerId>` / `u_<authorUid>` |

Every signed-in user auto-subscribes at login (see `messagingBindingProvider`);
farmers also subscribe to their shops + farms; buyers subscribe to each order at
checkout.

---

## Firebase Console (one-time)

1. **Cloud Messaging** — already enabled (project `prm301-asm`); nothing to turn on.
2. Confirm `android/app/google-services.json` exists (it does).
3. `AndroidManifest.xml` already has `POST_NOTIFICATIONS` + the default channel.

Nothing here costs money and nothing needs Blaze.

---

## Test in 2 stages

### Stage A — receiving works (no worker yet)

1. `flutter run`, sign in (grant the notification permission when asked).
2. Get the device token from logs:
   ```bash
   flutter run | grep FCM_TOKEN
   ```
3. Firebase Console → **Messaging → New campaign / Test message** → paste the
   token → send. You should see:
   - a **system notification** if the app is in the background,
   - an **in-app banner** (SnackBar) if it's in the foreground.
4. Send a campaign to topic **`broadcast`** (Target → Topic → `broadcast`) —
   every signed-in device gets it.
5. Tap a notification → the app deep-links to the right screen
   (via the existing `resolveNotificationRoute`).

At this point FCM integration is already demonstrable for grading.

### Stage B — automatic event pushes (deploy the worker)

Follow [`push-worker/README.md`](push-worker/README.md): deploy the Cloudflare
Worker (free, no card), set `PUSH_API_KEY` + `FIREBASE_SERVICE_ACCOUNT`, then run
the app with:

```bash
flutter run \
  --dart-define=PUSH_ENDPOINT=https://chuoi-push.<sub>.workers.dev/send \
  --dart-define=PUSH_API_KEY=<secret>
```

Then verify each event with two devices/accounts:

| Test | Do this | Expect |
|------|---------|--------|
| Đơn mới | consumer places an order from a shop | farmer of that shop gets a push |
| Trạng thái đơn | farmer changes the order status | that buyer gets a push |
| Chứng nhận | admin approves/rejects a farm cert | the farm's farmer gets a push |
| Broadcast | admin sends a broadcast | all (or the role) get a push |
| Chat/Forum | send a chat message / comment on a post | the peer / post author gets a push |

---

## Firestore rules (token storage)

Add to `firestore.rules` so a signed-in user can store their own token + mapping:

```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
match /fcm_tokens/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

(Optional — only used for single-device Console tests; topic pushes don't need it.)

---

## Notes / limitations (for the report)

- **No credit card / no Cloud Functions.** Sending is done by a free Cloudflare
  Worker that holds the service account server-side, so no secret ships in the APK.
- Foreground pushes show an in-app SnackBar (Android doesn't auto-show a tray
  notification while the app is focused); background/terminated use the system tray.
- Cross-user targeting avoids the backend↔Firebase id mismatch by using topics
  keyed on ids the sender already has (shopId/orderId/farmId/peerId).
- Files added: `core/firebase/messaging_service.dart`, `fcm_topics.dart`,
  `fcm_token_store.dart`, `push_sender.dart`, `core/config/push_config.dart`,
  `features/notification/presentation/providers/messaging_providers.dart`,
  `push-worker/`.
