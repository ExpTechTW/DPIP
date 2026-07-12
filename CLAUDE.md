# CLAUDE.md

Guidance for working in this repository. See `ARCHITECTURE.md` for the folder
structure, `api.md` for the API/region map, and `DESIGN.md` for the design
system (colours, spacing, radius, motion, typography, shared components).

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
  `core/` (logging, network, storage, models, geo, platform, settings),
  `features/<f>/{data,domain,presentation}`, `shared/`. Rules (enforced by
  `tool/check_layering.sh`): `core`/`shared` must not import `features`;
  `presentation` depends on `domain`, not `data`; a feature must not import
  another feature's `data`/`presentation` — share via `shared/` or a `domain`
  interface. App-wide state that several features consume lives outside any one
  feature (e.g. `core/settings/` for `ExperimentalSettings`).
- **Navigation:** route names/paths live in `shared/navigation/app_routes.dart`
  (`AppRoutes`). The router (`app/router/`) is the only place that imports page
  widgets; navigate by name — `context.pushNamed(AppRoutes.log)` — never import
  another feature's page to reach its route. Pages don't declare their own path.
- **Design system:** build UI from the tokens in `app/theme/`
  (`AppSpacing` / `AppRadius` / `AppMotion`), `ColorScheme` roles, and shared
  components (`shared/widgets/`). Never hardcode spacing, radius, duration, or
  colour where a token/role exists. Full reference: `DESIGN.md`.
- **State management:** `provider`. App-wide services are provided in
  `app/app.dart`; feature state lives in the feature's `presentation`.
- **Networking:** never call hosts directly — use the region-aware API surface
  (`api/redundant_api.dart`, `api/exclusive_api.dart`, `api/external_api.dart`).
  No DNS-balanced bare hosts. See `api.md`. `ApiClient` fails over to the next
  region **only** on transient/server faults (connection drop, timeout, 5xx) and
  logs each failover; a 4xx or a cancellation throws immediately (it would recur
  on every region). Pass a `CancelToken` to abort a superseded request. Fatal and
  handled errors forward to an optional `CrashSink` set on `Log` (Crashlytics
  wire-up point).
- **Data & errors (contract):** models are `@freezed` value types with generated
  `fromJson`/`toJson` (`@JsonKey` for wire names; `boolishInt`/`intFromBool` for
  0/1 bools) — template: `features/earthquake/domain/eew.dart`. A feature exposes
  a `Repository` **interface in `domain/`** returning `Result<T>`
  (`core/error/result.dart`); the impl lives in `data/`, owns JSON→model mapping,
  and converts transport/decode errors to a typed `Failure`
  (`core/error/failure.dart`) via `mapException` — never leak raw JSON or a
  `DioException` above the data layer, and never `try/catch`-swallow into a blank
  UI. `strict-casts`/`strict-raw-types` are on. Run `build_runner` after model
  changes; add a `fromJson` round-trip test.
- **Realtime (streaming feeds):** live feeds (EEW now, RTS later) flow through
  the polling spine in `core/realtime/`. A `RealtimeChannel<T>` polls a
  `RealtimeSource<T>` (returns `Result<T>`) on a fixed cadence and exposes
  `Stream<RealtimeState<T>>` with a `connecting`/`live`/`stale`/`offline`
  status. Freshness is a pure, golden-pinned function (`staleness.dart`) measured
  against a corrected `ServerClock` — a feed ages to stale/offline on its own
  when polls stop, and a failed poll keeps the last data (never blanks). Add a
  feed by implementing `RealtimeSource` (in `data/`) and subclassing
  `RealtimeNotifier` (in `presentation/`) — no engine change; transport stays
  HTTP polling behind the source seam. `RealtimeService` + `AppLifecycleListener`
  pause polling on background and resume (recompute status → resync clock →
  refetch) on foreground; background alerting is push's job. A safety-critical
  feed that is `stale`/`offline` must never be presented as current.
- **Async-state UI (contract):** render async/realtime state through the shared
  views in `shared/widgets/`, never a hand-rolled `FutureBuilder`/`Consumer` that
  drops the error or stale case into a blank screen. `AsyncView<T>` maps a
  one-shot `Future<Result<T>>` to loading/data/empty/error (with retry);
  `RealtimeView<T>` maps a `RealtimeState<T>`, adding connecting/stale/offline and
  a freshness banner so aged safety data is never shown as current. Building
  blocks: `LoadingView` / `ErrorView` / `EmptyView`. Template consumer:
  `features/earthquake/presentation/pages/earthquake_page.dart`.
- **Push notifications** (`core/notifications/`): `firebase_messaging` owns the
  FCM/APNs transport (token + message receipt) on both platforms; `awesome_
  notifications` renders the rich per-channel notification and routes taps.
  (Legacy used `awesome_notifications_fcm`, but that plugin's iOS pod breaks the
  rewrite's newer Flutter/scene build — one FCM plugin is simpler and builds
  clean.) Keep Firebase pinned (a newer major raises the min iOS target). Backend
  sends **data** messages (`channel`/`id`/`title`/`body`); foreground + data-only
  background messages display via awesome so each honours its channel; a
  `notification`-payload message is shown by the OS. Alert categories live in
  `notification_channels.dart` — bump `version` when one changes so Android
  re-creates it. Taps funnel through `NotificationTaps` (core carries the channel
  key; `app/` maps it to an `AppRoutes` tab). **External, not code:** upload an
  APNs auth key to the Firebase console for iOS; push only works on a physical
  device; permission is requested after the first frame for now (move to
  onboarding); backend token registration (`/v2/location`) needs the not-yet-
  ported location feature — the token is stored (`NotificationService.token`)
  meanwhile.
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

## CI & gates

`.github/workflows/ci.yml` runs on every push/PR and must stay green. It uses
the mise-pinned toolchain and runs, in order: the layering gate
(`tool/check_layering.sh`), `dart format --set-exit-if-changed`, a codegen-drift
check (`build_runner` + `git diff --exit-code` — committed `*.g.dart` /
`*.freezed.dart` must match a fresh build), `flutter analyze`, and
`flutter test`. Run these locally before pushing. Safety-critical seismic math
is pinned by golden tests (`test/features/earthquake/eew_estimator_test.dart`);
if you change the EEW estimator, update those goldens deliberately.

## Commits

- Keep commits focused; run `flutter analyze` (clean) before committing.
- Do **not** add `Co-Authored-By` / "Generated with" trailers.
