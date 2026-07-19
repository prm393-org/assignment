# Chuỗi Xanh Việt — Flutter Mobile

Rebuild từ React Native (`chuoi-xanh-viet-mobile`) sang Flutter + Clean Architecture.

## Stack

- Flutter 3.x + Material 3 + Riverpod + Dio + go_router
- Socket.IO chat realtime
- API: `http://178.128.98.214:8001/v1/api`

## Roles

| Role | Shell |
|------|--------|
| Consumer (guest browse) | `/consumer` |
| Farmer | `/farmer` |
| Admin | `/admin` |

## Features (P0–P2)

- Auth: welcome, login, register, farmer-applicant, forgot/reset password
- Consumer: marketplace, cart, checkout COD/PayOS/VNPay, orders, forum, chat, notifications, trace/QR, profile edit
- Farmer: farms (GPS/VN address), seasons + status, diary + media, join HTX, shop manage (tabs), earnings, certificates, AI, agri-trend, trace
- Admin: dashboard, users, certificates, broadcast, audit logs
- Shared: upload, Socket.IO chat

## Build APK

```bash
flutter pub get
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`
