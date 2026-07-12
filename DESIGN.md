# DESIGN.md

The DPIP design system — the single reference for the app's visual and
foundational conventions. Keep the UI consistent by building from these tokens
and components; **never hardcode a value that has a token.** See `CLAUDE.md` for
process rules and `ARCHITECTURE.md` for the folder layout.

Everything here lives under `lib/app/theme/` (tokens + theme) and
`lib/shared/widgets/` (shared components). Cross-cutting infrastructure —
logging and localization — is covered at the end.

## Principles

- **Theme-driven.** Colours, typography, and shape come from `ThemeData` /
  `ColorScheme` so light and dark modes and future re-themes are free.
- **Tokens, not magic numbers.** Spacing, radius, and motion come from
  `AppSpacing` / `AppRadius` / `AppMotion`. A bare `16`, `Radius.circular(20)`,
  or `Duration(milliseconds: 220)` in UI code is a smell.
- **One component, one place.** Reusable UI (e.g. `SectionHeader`) lives in
  `shared/widgets/`; don't copy-paste it into features.

## Colour & theme

- Source of truth: `AppTheme` (`lib/app/theme/app_theme.dart`) — Material 3,
  `ColorScheme.fromSeed(seedColor: 0xFF00696D)` for both brightnesses.
- **Use `ColorScheme` roles**, never literal colours:
  `Theme.of(context).colorScheme.{primary, surface, surfaceContainer,
  surfaceContainerHigh, surfaceContainerHighest, onSurface, onSurfaceVariant,
  outline, error, …}`.
- Translucency via `color.withValues(alpha: …)` (not the deprecated
  `withOpacity`). Convert a colour to a MapLibre hex with `Color.toHexRgb()`
  (`lib/shared/color_hex.dart`).
- The map backdrop mirrors the theme: sea = `surface`, land = `surfaceContainer`,
  county/town = `surfaceContainerHigh`, borders = `outline`.
- Literal colours are allowed **only** where no theme role applies: shader
  fallback/mood colours (`weather_sky.frag` / `weather_sky_background.dart`) and
  the one sheet shadow.

## Spacing — `AppSpacing`

4px grid. `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32`.

```dart
padding: const EdgeInsets.all(AppSpacing.lg),          // screen / card padding
padding: const EdgeInsets.only(bottom: AppSpacing.md), // gap between rows
```

## Radius — `AppRadius`

`sm 8 · md 16 · lg 20`, plus ready-made `BorderRadius`: `small`, `medium`,
`large`, and `topSheet` (top-rounded for bottom sheets).

```dart
borderRadius: AppRadius.medium,   // cards
borderRadius: AppRadius.topSheet, // draggable sheet
```

## Motion — `AppMotion`

`fast 150ms · medium 220ms · slow 400ms`. Continuous/background animations
(e.g. the weather shader ticker) set their own periods.

```dart
controller.animateTo(target, duration: AppMotion.medium, curve: Curves.easeOut);
```

## Typography

Use `Theme.of(context).textTheme` roles (`titleLarge`, `bodyMedium`,
`labelMedium`, …) with `copyWith` for one-off tweaks — never a bare `TextStyle`
with a hardcoded `fontSize`.

## Icons

Built-in Material `Icons` only (no icon packages). **Outlined** by default
(`Icons.foo_outlined`) for rows/actions/inactive; **filled** (`Icons.foo`) for
the selected/active state (e.g. bottom-nav `selectedIcon`). Every menu row has a
leading icon.

## Elevation & shadow

Prefer Material `elevation` / tonal surfaces. The home sheet's custom top-edge
shadow is the one bespoke shadow; add more only with a clear reason.

## Shared components — `lib/shared/widgets/`

- `SectionHeader(title)` — the small primary-tinted header above a settings/menu
  group. Use it for every section instead of re-styling a `Text`.

Map foundations live in `lib/shared/map/` (`BaseMap`, `map_style`,
`map_snapshot`); see `api.md` for the tile/radar endpoints.

## Logging (infrastructure)

Always log through `Log` (`lib/core/logging/log.dart`):
`Log.debug / info / warning / error / handle`. **Never** `print` / `debugPrint`
(`avoid_print` fails analysis). In-app viewer: More → 實驗性功能 is above it; the
log page is backed by the same `Log` history.

## Localization (infrastructure)

Every user-facing string goes through `AppLocalizations`
(`AppLocalizations.of(context).<key>`). ARB sources in `lib/l10n/`
(`app_en.arb` template, `app_zh.arb` Traditional Chinese default); generated code
in `lib/l10n/gen/`. Add a language by dropping in `app_<locale>.arb`. Never
hardcode display text.
