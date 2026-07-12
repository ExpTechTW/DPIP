# CLAUDE.md

Guidance for working in this repository. See `ARCHITECTURE.md` for the folder
structure and `api.md` for the API/region map.

DPIP is a Taiwan disaster-prevention app, mid-rewrite on the `rewrite` branch
(clean Flutter 3.44 baseline, feature-first architecture).

## Toolchain

- Flutter/Dart are managed by **mise** — run tools via `mise exec -- flutter …`
  (e.g. `mise exec -- flutter analyze`).
- After changing `@freezed` / `@JsonSerializable` models:
  `mise exec -- dart run build_runner build --delete-conflicting-outputs`.
- After editing ARB files, localizations regenerate on the next build
  (`generate: true`); regenerate manually with `mise exec -- flutter gen-l10n`.
- Format with `mise exec -- dart format lib`.

## Running

- iOS simulator: `mise exec -- flutter run -d "iPhone 17 Pro"`. Select the
  device with `-d <name|id>` — a bare `flutter run ios` treats `ios` as a
  target Dart file and fails with `Target file "ios" not found`.
- If `flutter run` / `pub get` stalls at **Downloading packages**, resolve from
  the local cache first: `mise exec -- flutter pub get --offline`, then re-run.
- The visible simulator window in Xcode 26+ is **DeviceHub.app** (it replaced
  `Simulator.app`): `open "$(xcode-select -p)/../Applications/DeviceHub.app"`.
  `open -a Simulator` no longer works. `flutter run` boots the sim headless, so
  open DeviceHub separately to see/interact with it.

## Logging — required

- **Always log through `Log`** (`lib/core/logging/log.dart`):
  `Log.debug / info / warning / error / handle`.
- **Never use `print` or `debugPrint`.** `avoid_print` is set to **error** in
  `analysis_options.yaml`, so it fails analysis.
- Uncaught Flutter/async errors are captured automatically
  (`Log.installErrorHandlers()` in `bootstrap.dart`).
- In-app log viewer: the **App 日誌** page (More tab → `LogPage`), backed by the
  same `Log` history.

## Conventions

- **Architecture:** feature-first + layered — `app/` (shell, router, theme),
  `core/` (logging, network, storage, models, geo, platform), `features/<f>/
  {data,domain,presentation}`, `shared/`. `core`/`shared` must not import
  `features`; `presentation` depends on `domain`, not `data`.
- **State management:** `provider`. App-wide services are provided in
  `app/app.dart`; feature state lives in the feature's `presentation`.
- **Networking:** never call hosts directly — use the region-aware API surface
  (`api/redundant_api.dart`, `api/exclusive_api.dart`, `api/external_api.dart`).
  No DNS-balanced bare hosts. See `api.md`.
- **Native-first:** prefer platform channels / built-ins over third-party
  plugins where practical (e.g. `core/platform/` device_info, compass).
- **Icons:** use Flutter's built-in Material `Icons` only — no third-party icon
  packages. Default to the **outlined** variant (`Icons.foo_outlined`) for list
  rows, actions, and inactive states; use the **filled** variant (`Icons.foo`)
  for the selected/active state (e.g. the bottom-nav `selectedIcon`). Every
  list row in a menu carries a leading icon.
- **Localization (i18n):** every user-facing string goes through
  `AppLocalizations` (`AppLocalizations.of(context).<key>`) — never hardcode
  display text. ARB sources live in `lib/l10n/` (`app_en.arb` is the template,
  `app_zh.arb` is Traditional Chinese, the Taiwan default); generated code is in
  `lib/l10n/gen/`. Add a language by dropping in `app_<locale>.arb`. Config in
  `l10n.yaml`.
- Every file starts with a doc comment; one public declaration = one clear
  responsibility.

## Commits

- Keep commits focused; run `flutter analyze` (clean) before committing.
- Do **not** add `Co-Authored-By` / "Generated with" trailers.
