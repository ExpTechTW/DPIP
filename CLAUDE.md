# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

DPIP (Disaster Prevention Information Platform) — a Flutter app for Taiwan earthquake early warning and disaster information, integrating TREM-Net and CWA data.

## Commands

```bash
# Install dependencies
flutter pub get --no-example

# Format
dart format .

# Lint
dart analyze .

# Code generation (required after editing routes, @JsonSerializable, or @freezed models)
dart run build_runner build

# Update translations
bash tools/update_translations.sh

# Run
flutter run

# Build
flutter build apk --release
flutter build ios --release
```

There is no test suite.

## Architecture

**State management:** Provider (`ChangeNotifier`). Global providers are registered in `lib/core/providers.dart`:
- `DpipDataModel` — earthquake/weather data
- `SettingsLocationModel`, `SettingsMapModel`, `SettingsNotificationModel`, `SettingsUserInterfaceModel`

**Routing:** go_router with type-safe routes via `@TypedGoRoute`. Routes are defined in `router.dart` and code-generated into `router.g.dart`. Run `build_runner` after route changes.

**Feature modules** live under `lib/app/` (home, map, settings, changelog, debug, welcome). Each is self-contained with its own widgets subfolder.

**API layer** (`lib/api/`): Dio HTTP client with caching. Models use `@JsonSerializable` + `@freezed` — regenerate with `build_runner` after changes.

**Core services** (`lib/core/`): FCM, GPS, local notifications, EEW logic (`eew.dart`), compass, i18n, device info.

**Assets:** JSON data files are gzip-compressed (`*.json.gz`) and decompressed at runtime. GLSL shaders (`fog.frag`, `thunderstorm.frag`) are used for map effects.

## Key Conventions

- **Settings naming:** Notification settings use numbered prefixes — `(1.eew)`, `(2.earthquake)`, `(3.weather)`, `(4.tsunami)`, `(5.basic)` — to control display order.
- **Linting:** Extends `package:lint/strict.yaml`. Line width 100, preserve trailing commas, prefer single quotes.
- **Documentation:** Every public member must have a doc comment (`///`). Every file must have a top-level library doc comment (`/// ...` before any `library` or first declaration). Follow Effective Dart: document usage and behavior from the caller's perspective, not internal implementation. Use `[...]` for code references, avoid restating the name.
- **Dot shorthand:** Always use Dart dot shorthand (e.g., `.value` instead of `EnumType.value`) wherever the type can be inferred from context.
- **Widget extraction:** When a build method nests too deeply, extract the subtree into a private widget class (`_FooWidget`) in the same file rather than keeping it inline.
- **Class member order** (top to bottom), within each group sort alphabetically `A→Z` then `a→z`:
  1. Class fields
  2. Primary constructor
  3. Named constructors
  4. Uninitialized variables / private fields
  5. Private methods
  6. Public methods
  7. Overriding methods — widgets follow lifecycle order: `initState` → `build` → `dispose`
  8. Static fields
  9. Static members
- **Extensions:** Always prefer extension methods from `lib/utils/extensions/` over verbose equivalents. Avoid `.of(context)` calls — use `BuildContext` extensions instead:
  - `context.theme` → `Theme.of(context)`
  - `context.colors` → `Theme.of(context).colorScheme`
  - `context.texts` → `Theme.of(context).textTheme`
  - `context.dimension` → `MediaQuery.sizeOf(context)`
  - `context.padding` → `MediaQuery.paddingOf(context)`
  - `context.brightness` → `MediaQuery.platformBrightnessOf(context)`
  - `context.navigator` → `Navigator.of(context)`
  - `context.scaffoldMessenger` → `ScaffoldMessenger.of(context)`
  - `context.router` → `GoRouter.of(context)`
  - `context.popUntil(path)` → `GoRouter.of(context).popUntil(path)`
  - `context.bottomSheetConstraints` → Material 3 bottom sheet constraints
- **Generated files** (`**.freezed.dart`, `**.g.dart`) are excluded from analysis — do not edit them manually.
- **Localization:** Uses `i18n_extension`. Translations are managed via Crowdin; only zh-Hant is updated locally via the translation script.
- **Maps:** MapLibre GL with multiple layer managers. Dynamic color (Material You) via `dynamic_color`.
