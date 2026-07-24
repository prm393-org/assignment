# UI kit & tokens reference

## AppColors (agri)

| Token | Role |
|-------|------|
| `forest` / `forestSoft` / `darkGreen` | Primary / accent |
| `lime` | Highlight |
| `mint` / `mintDeep` | Soft fills |
| `canvas` / `canvasSoft` / `surface` / `surfaceElevated` | Backgrounds |
| `ink` / `body` / `muted` | Text hierarchy |
| `hairline` / `hairlineStrong` | Borders |
| `error` / `success` / `warning` | Semantic |
| `onPrimary` | Text/icon on green |
| `shadow` | Soft green-tinted shadow |

Add new soft tints (e.g. status chip fills) to `AppColors` — do not leave hex in widgets.

## AppSpacing

| Token | px |
|-------|-----|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 24 |
| `xxl` | 32 |
| `screen` | `EdgeInsets.all(lg)` |

## async_states

| Widget | Use |
|--------|-----|
| `LoadingView` | Full-pane loading |
| `EmptyState` | Message + optional `actionLabel` / `onAction` |
| `ErrorState` | Message + `onRetry` |
| `AsyncBody<T>` | Bridges `AsyncValue`-like → triad |

## ui_kit

| Widget | Use |
|--------|-----|
| `SurfaceCard` | Default elevated/surface container |
| `PageHeader` | Screen title + subtitle/actions |
| `SectionHeader` | Section title row |
| `SoftHeroBanner` | Home/welcome hero strip |
| `ProductCard` | Marketplace product tile |
| `QuickActionCard` | Shortcut tile |
| `StatPill` | Compact metric |
| `IconBadge` | Icon in soft circle |
| `StatusChip` | Status label (pending/ok/error) |

## Guest vs authenticated (UI)

**Browse OK (guest):** consumer home, marketplace, product/shop detail, trace/QR (when routed).

**Gate / login redirect:** checkout, place order, forum create/edit, notifications list (API), start chat, profile edit, farmer/admin write screens.

Align AppBar icons and FABs with the same gates — do not show dead-end entry points.
