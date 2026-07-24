# push-worker — FCM relay (free, no credit card)

The Flutter app can't send FCM directly (that needs a server credential).
This tiny Cloudflare Worker holds a Firebase **service account** and forwards
topic-targeted pushes from the app to FCM HTTP v1. Cloudflare Workers' free
plan needs **no credit card**, so the whole push pipeline stays at 0đ.

It is **not** the business backend (`178.128.98.214`) — it's a ~150-line
endpoint you own, isolated from everything else.

## What you need

- A [Cloudflare](https://dash.cloudflare.com/sign-up) account (free, no card).
- Node.js (for `npx wrangler`).
- A Firebase **service account** JSON.

## 1. Get the service account JSON

Firebase Console → Project settings → **Service accounts** →
**Generate new private key**. This downloads a `*.json` file. Keep it secret —
never commit it.

## 2. Deploy the worker

```bash
cd push-worker
npx wrangler login          # opens the browser once
npx wrangler deploy         # prints your URL, e.g.
                            # https://chuoi-push.<your-subdomain>.workers.dev
```

## 3. Set the two secrets

```bash
# A shared secret you invent — the app sends it in the x-push-key header.
npx wrangler secret put PUSH_API_KEY
# Paste the ENTIRE service-account JSON when prompted (one line is fine).
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT
```

## 4. Point the app at it

Run the app with two `--dart-define`s (values from steps 2 and 3):

```bash
flutter run \
  --dart-define=PUSH_ENDPOINT=https://chuoi-push.<your-subdomain>.workers.dev/send \
  --dart-define=PUSH_API_KEY=<the-same-PUSH_API_KEY>
```

For a release APK:

```bash
flutter build apk --release \
  --dart-define=PUSH_ENDPOINT=https://chuoi-push.<your-subdomain>.workers.dev/send \
  --dart-define=PUSH_API_KEY=<the-same-PUSH_API_KEY>
```

If you skip this, the app still runs and still **receives** pushes you send
by hand from the Firebase Console — only the automatic event pushes are off.

## 5. Smoke test the worker directly

```bash
curl -X POST https://chuoi-push.<your-subdomain>.workers.dev/send \
  -H "x-push-key: <PUSH_API_KEY>" -H "content-type: application/json" \
  -d '{"topic":"broadcast","title":"Xin chào","body":"Test từ worker","link":"/consumer/home"}'
```

Any device that has opened the app while signed in is subscribed to
`broadcast` and should get the notification.

## Firestore rules (for token storage)

The app also stores each device's token and a uid→backend mapping. Add to
`firestore.rules` so a signed-in user can write their own docs:

```
match /users/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
match /fcm_tokens/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

Token storage is optional (only used for single-device Console tests); topic
pushes work without it.
