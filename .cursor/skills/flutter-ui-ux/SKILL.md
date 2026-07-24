---
name: flutter-ui-ux
description: >-
  Audits and implements Flutter UI/UX for Chuỗi Xanh Việt using AppColors,
  AppSpacing, ui_kit, and async_states. Use when building or polishing screens,
  fixing UI consistency, reviewing UX (loading/empty/error, forms, guest gates),
  or when the user mentions UI, UX, design, màn hình, theme, or polish.
---

# Flutter UI/UX — Chuỗi Xanh Việt

## When to use

- Tạo/sửa màn `lib/features/**/presentation/`
- Audit UX/UI, polish, đồng bộ design system
- Sửa form, empty/error, pull-to-refresh, guest/auth gates trên UI

## Canonical sources (read before inventing)

| Concern | Path |
|---------|------|
| Colors | `lib/core/theme/app_colors.dart` |
| Theme | `lib/core/theme/app_theme.dart` |
| Spacing | `lib/core/constants/app_spacing.dart` |
| Async UI | `lib/core/widgets/async_states.dart` |
| Kit | `lib/core/widgets/ui_kit.dart` |
| Images | `lib/core/widgets/app_network_image.dart` |
| Shell | `lib/core/widgets/role_shell.dart` |
| Routes | `lib/core/router/app_router.dart` |

Palette: agri green (`forest` / `mint` / `ink`). **Do not** use Cursor marketing cream/orange from `.cursor/rules/DESIGN.md`.

## Build / change workflow

1. Reuse `ui_kit` + `async_states` before custom chrome.
2. Wire colors/spacing via `AppColors` / `AppSpacing` / `textTheme` only.
3. Cover loading → empty (message + CTA if actionable) → error (+ retry) → success content.
4. Forms: `Form` + field `validator`; disable submit while loading; clear Vietnamese copy.
5. Lists: `ListView.builder` + `RefreshIndicator` when refetch exists.
6. Auth: guest may browse marketplace/trace; gate checkout, create post, notifications, chat write.
7. Keep diffs scoped; match existing screen patterns (home/marketplace/forum are the gold standard).

## Audit workflow

Copy and fill:

```
UX audit:
- [ ] CRITICAL — broken route / silent no-op / wrong form mode / guest hits write API
- [ ] HIGH — missing loading/empty/error, no validators, no refresh, hardcoded colors on main UI
- [ ] MEDIUM — Card vs SurfaceCard, empty without CTA, spacing off 4/8, weak a11y
- [ ] LOW — badges, branded splash, alias routes
```

Report format per finding:

```
SEVERITY | path | issue | fix
```

Suggested fix order: guest/router gates → broken navigation → silent failures → form validators → RefreshIndicator + empty CTAs → tokenize hex → Card→SurfaceCard.

## Screen checklist (quick)

- [ ] No `Color(0x…)` / ad-hoc `Colors.*` (except rare transparent)
- [ ] Screen padding ≥ `AppSpacing.lg`
- [ ] Async triad + retry where fetch fails
- [ ] Empty has CTA when user can act
- [ ] Form validators + loading on submit
- [ ] Pull-to-refresh on list screens
- [ ] Primary actions labeled / tooltipped
- [ ] Role path correct (`/consumer|farmer|admin/...`)

## Gold-standard references

Prefer patterns from:

- `consumer_home_screen.dart`, `marketplace_screen.dart`, `forum_list_screen.dart`
- Auth forms: `login_screen.dart`, `register_screen.dart`

## Out of scope

- Do not introduce new design libraries or full redesign unless asked.
- Do not add usecase layer; providers call repositories (project convention).
- Architecture rules stay in `flutter-ap.mdc`; this skill is UI/UX only.

## More detail

- Tokens & widget map: [reference.md](reference.md)
- Example audit lines: [examples.md](examples.md)
