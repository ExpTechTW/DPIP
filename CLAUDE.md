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
- Format with `mise exec -- dart format lib`.

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
- Every file starts with a doc comment; one public declaration = one clear
  responsibility.

## Commits

- Keep commits focused; run `flutter analyze` (clean) before committing.
- Do **not** add `Co-Authored-By` / "Generated with" trailers.
