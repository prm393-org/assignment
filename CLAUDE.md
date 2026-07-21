# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Chuỗi Xanh Việt** — a Flutter mobile rebuild (from a React Native app, `chuoi-xanh-viet-mobile`) of an agriculture supply-chain marketplace with three roles: **consumer**, **farmer**, and **admin**. Backend is a remote REST API (`http://178.128.98.214:8001/v1/api`) plus Firebase (Auth/Google Sign-In, Crashlytics, Analytics, Firestore, Realtime Database, Messaging) and a Socket.IO server for realtime chat.

## Commands

```bash
flutter pub get                    # install dependencies
flutter run                        # run on connected device/emulator
flutter analyze                    # static analysis (flutter_lints)
flutter test                       # run all tests
flutter test test/widget_test.dart # run a single test file
flutter build apk --release        # release APK -> build/app/outputs/flutter-apk/app-release.apk
```

There is no CI config and no `.env` handling — API host and Firebase config are committed as plain Dart constants (see below).

## Architecture

Feature-first Clean Architecture. Every feature under `lib/features/<name>/` is split into:

```
data/            # datasources (Dio/Firebase calls), DTOs, repository implementations
domain/          # entities, abstract repository contracts (no Flutter/data imports)
presentation/    # screens, widgets, Riverpod providers/notifiers
```

Actual data flow is **UI → Riverpod Provider/Notifier → Repository (interface) → DataSource**. There is no usecase layer in this codebase (despite what `.cursor/rules/flutter-ap.mdc` describes) — providers call repositories directly. Follow this existing pattern rather than introducing usecases.

Not every feature has all three layers — e.g. `cart` and `profile` are presentation-only (no backend-backed domain/data), since they're local/derived state.

### Shared core (`lib/core/`)

- `router/app_router.dart` — single `go_router` config (`appRouterProvider`). Auth/role gating happens in the top-level `redirect` callback, keyed off `authNotifierProvider` (bootstrapping / logged-in / `AuthRole`). Three role-scoped `StatefulShellRoute.indexedStack` sections (`/consumer/*`, `/farmer/*`, `/admin/*`) each wrap a bottom-nav `RoleShell`; routes outside those shells are pushed as normal `GoRoute`s. Guests (not logged in) can access `/consumer/*`, `/trace/*`, and `/qr-scan`.
- `network/dio_client.dart` — single `dioProvider`; attaches `Authorization: Bearer <token>` from `auth_token_holder.dart` on every request.
- `config/api_config.dart` — API host/prefix/timeouts as static constants (edit here to point at a different backend).
- `error/` — `failures.dart` (sealed `Failure` types: Network/Server/Auth/Validation/Unknown) + `exception_mapper.dart` (`mapDioException`, translates `DioException` → `Failure`, with Vietnamese user-facing messages). Repositories should map thrown exceptions through this rather than leaking `DioException`/raw errors into `domain`/`presentation`.
- `theme/` — `AppColors` (agri green palette) and `AppTheme.light`, the single `ThemeData`. No ad-hoc colors/fonts outside this.
- `widgets/` — shared UI: `RoleShell` (bottom nav shell used by all three roles), `ui_kit.dart`, `async_states.dart` (loading/empty/error patterns), `app_network_image.dart` (cached network images).
- `utils/` — `formatters.dart`, `json_helpers.dart` (safe JSON parsing for DTOs), `media_url.dart` (resolves relative media paths against `ApiConfig.apiHost`), `vietnam_address_api.dart` / `nominatim_geocode.dart` (VN address + geocoding lookups used by farm GPS/address features).

### Auth & roles

`AuthRole` (`lib/features/auth/domain/entities/auth_role.dart`) drives both routing and UI. `authNotifierProvider` (`lib/features/auth/presentation/providers/auth_notifier.dart`) holds an `AuthSession` (token + `AuthUser`) and exposes `isBootstrapping` / `isAuthenticated` / `role`, restored from `flutter_secure_storage` on startup. Login supports both email/password and Google Sign-In (Firebase Auth); `AuthRepositoryImpl` is constructed with `Firebase.apps.isEmpty ? null : FirebaseAuth.instance` so the app still runs if Firebase isn't initialized.

### Chat

Socket.IO client is wired at the app root: `ChuoiXanhVietApp` watches `chatSocketControllerProvider` unconditionally so the socket connects/reconnects app-wide, independent of which chat screen (if any) is on screen.

### Origin of the codebase

`scripts/gen_*.py` are one-off Python scaffolding scripts that generated the bulk of `lib/` (they write literal Dart source via `Path.write_text`). They are not part of the normal dev workflow/build — treat them as historical scaffolding, not a code-generation step to run.

## Code style (enforced by convention, see `.cursor/rules/flutter-ap.mdc`)

- Dependency rule: `presentation → domain ← data`; `domain` never imports Flutter or data-layer types.
- Naming: files `snake_case`, classes `PascalCase`, members `camelCase`, booleans `isX`/`hasX`.
- Imports ordered `dart:` → `package:` → relative; single quotes; no magic numbers.
- Prefer `StatelessWidget` + `const`; small single-responsibility widgets; `ListView.builder` for long lists.
- Spacing on the 4/8 scale (8, 12, 16, 24; see `core/constants/app_spacing.dart`); screen padding ≥ 16.
- Every data-driven screen handles loading / empty / error states (with retry where relevant) — see `core/widgets/async_states.dart`.
- Colors/fonts only via `AppTheme`/`AppColors`, never hardcoded inline.
- Keep responses/diffs minimal and scoped to the request — don't add unrelated docs, comments, or refactors.
