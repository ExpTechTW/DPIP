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
- Base-map paint lives only in `MapColors` (`map_style.dart`) as light/dark
  `MapPalette`s — resolve with `MapColors.of(brightness)`, never ad-hoc hexes
  or `ColorScheme` roles for cartography. Dark: bg `#1f2025` / fill `#3F4045` /
  outline `#a9b4bc` / town `#6A6B72`. Light: bg `#E0E0E0` / fill `#ADADAD` /
  outline `#6B6B6B` / town `#9A9A9A`.
- Literal colours are also allowed where no theme role applies: shader
  fallback/mood colours (`weather_sky_background.dart`, `_fallbackColour`) and
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

## Glass over the weather backdrop

Content layered over the weather sky tints through `lib/app/theme/app_glass.dart`
(`glassSurface` / `glassOnSurface` / `inkOverWeather` …), driven by a `reveal`
dial: at rest a translucent theme surface, once revealed a pane of the sky
itself (sky colour at 20 % alpha, HSL-lightness shifted by time of day — see
`skyCardTint`). Ink follows the sky, not the theme. Shared surfaces built from
it: `shared/widgets/frosted_surface.dart`, `sheet_surface.dart`.

## Shared components — `lib/shared/widgets/`

- `SectionHeader(title)` — the small primary-tinted header above a settings/menu
  group. Use it for every section instead of re-styling a `Text`.

Map foundations live in `lib/shared/map/` (`BaseMap` in `base_map.dart`,
`map_style.dart` with `MapColors`/`MapPalette`, `map_tile_cache.dart`); see
`api.md` for the tile/radar endpoints.

## Icons

use Flutter's built-in Material `Icons` only — no third-party icon
packages. Default to the **outlined** variant (`Icons.foo_outlined`) for list
rows, actions, and inactive states; use the **filled** variant (`Icons.foo`)
for the selected/active state (e.g. the bottom-nav `selectedIcon`). Every
list row in a menu carries a leading icon.
The one exception is **weather**: Flutter's bundled font has no rain glyph at
all (nor mixed precipitation, nor hail), so weather surfaces draw from
`core/weather/weather_icons.dart` — a 6.7 KB subset of Material Symbols
Outlined bundled as a *font asset*, not a package. **Never hand-write an
`IconData` codepoint**: that file and the font are both generated by
`tool/build_weather_icons.py` from Google's `.codepoints` manifest, because a
guessed codepoint is a valid `IconData` that silently draws the wrong picture
— `rainy` was once declared as `0xf07c2`, which is `Icons.severe_cold`, and
every rainy hour rendered a snowflake. Add a glyph by adding its Material
Symbols *name* to `GLYPHS` and re-running the tool;
`test/core/weather/weather_icons_test.dart` rasterises every glyph and fails
on one that is missing or duplicated.

## Localization

every user-facing string goes through
`AppLocalizations` (`AppLocalizations.of(context).<key>`) — never hardcode
display text. ARB sources live in `lib/l10n/` (`app_en.arb` is the template,
`app_zh.arb` is Traditional Chinese, the Taiwan default; `zh_TW`,
`zh_Hant_HK` / `zh_Hans` cover HK/Simplified, plus ja/ko/th/vi/fil/id);
generated code is in `lib/l10n/gen/`. Each ARB **self-describes** with a
`languageName` key (the locale's own name), and the language picker
(`shared/widgets/language_picker.dart`) is built from
`AppLocalizations.supportedLocales` + that key — never a hardcoded list. So a
language is added by just dropping in `app_<locale>.arb` (with `languageName`);
the home/fallback locale is the one constant in
`core/settings/locale_config.dart`. Enforced by `tool/check_l10n.sh` (a CI
gate, no packages): ARB key-parity with the template + no hardcoded
CJK/kana/Hangul/Thai string literals in `features/*/presentation/**` or
`shared/widgets/**`. A genuinely non-display or throwaway literal is exempted
with `// l10n-ignore: <reason>` (that line/the one above) or
`l10n-ignore-file` in a file's header doc. Config in `l10n.yaml`.

---

Logging, and every other cross-cutting contract, lives in
[ARCHITECTURE.md](ARCHITECTURE.md#contracts).
