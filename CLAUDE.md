# CLAUDE.md

Guidance for working in this repository. See `ARCHITECTURE.md` for the folder
structure, `api.md` for the API/region map, and `DESIGN.md` for the design
system (colours, spacing, radius, motion, typography, shared components).

DPIP is a Taiwan disaster-prevention app, mid-rewrite (clean Flutter 3.47
baseline, feature-first architecture).

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
- The log is **persisted** to the `logs` table of the durable database with a
  rolling **24-hour** retention (`core/logging/log_store.dart`). Writes are
  buffered and flushed on a timer, on a burst, and when the app backgrounds —
  a log call never costs a database round-trip, and the store never throws
  (it is called from error handlers, where a failure would replace a
  diagnostic with a crash). Retention runs on write, not on read.
- In-app log viewer: the **App 日誌** page (More tab → `LogPage`), which shows
  the live session and replays the last 24 hours from the table on open, so it
  covers the launch that crashed rather than only the current one.

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
- **State management:** `provider`. `bootstrap()` assembles the shared
  infrastructure into a `SharedDeps` (`core/di/shared_deps.dart`) and hands it
  to each feature's `*Providers(deps)` aggregate (wired through
  `core/di/core_providers.dart`); feature state lives in the feature's
  `presentation`.
- **Networking:** never call hosts directly — use the region-aware `ApiClient`
  (`core/network/api_client.dart`) with an `ApiTier` from
  `core/network/api_region.dart` (LB vs Core, exclusive vs multi-active) and
  path constants from `core/network/api_paths.dart`. No DNS-balanced bare
  hosts. See `api.md`. `ApiClient` fails over to the next region **only** on
  transient/server faults (connection drop, timeout, 5xx) and logs each
  failover; a 4xx or a cancellation throws immediately (it would recur on every
  region). Pass a `CancelToken` to abort a superseded request. SSE streams go
  through `ApiClient.openStream` + `core/network/sse_client.dart`. Fatal and
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
  `RealtimeNotifier` (in `presentation/`) — no engine change; the transport
  lives entirely behind the source seam. EEW now streams over **SSE**
  (`sse_realtime_source.dart` holds one connection, buffers the latest event,
  and answers each poll from that buffer — `Ok` while connected, `Err` while
  reconnecting — so the channel/state/staleness are untouched); the `data:`
  payload is the same JSON the GET returned. A bursty feed (EEW, silent between
  events) uses connection-open liveness; a continuous feed (RTS, ~1 Hz) uses
  event-recency. `RealtimeService` + `AppLifecycleListener`
  pause polling on background and resume (recompute status → resync clock →
  refetch) on foreground; background alerting is push's job. A safety-critical
  feed that is `stale`/`offline` must never be presented as current.
- **Calibrated time:** the `ServerClock` corrects device time via real **SNTP**
  (`ntp_time_source.dart` → `flutter_ntp`, UDP/123, `time.exptech.com.tw` primary
  / `time.apple.com` backup — not an HTTP endpoint), anchored to a monotonic
  clock so a device-clock or timezone change can't move it (only a resync does).
  `RealtimeService` resyncs it every 60s (paused in background, resynced on
  resume). Read corrected time anywhere via the global `AppTime` facade
  (`AppTime.utc` / `AppTime.utc8`, the fixed-offset Taipei wall clock) — never
  `DateTime.now()` for anything the server timestamps.
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
  re-creates it. Permission requests go through
  `NotificationService`, which asks the plugin to prompt **only** when the OS
  status is `notDetermined`: once iOS has been told "no", awesome opens the
  settings page itself and parks its completion until the app returns, so the
  awaited Future can simply never come back. A decided state therefore returns
  `PermissionOutcome.needsSettings` without calling the plugin, and every
  request carries a timeout so a button can never be inert. Channels register
  as one batch; if that
  batch is rejected the service falls back to registering them individually, so
  one bad channel costs only itself and is named in the log instead of leaving
  the app with no channels *and* no push transport. (`initialize` needs at
  least one channel, so the fallback seeds itself with the first one that is
  accepted.) `tool/check_notification_sounds.sh` catches an unresolvable
  `resource://raw/<name>` before it ships. Taps funnel through `NotificationTaps` (core carries the channel
  key; `app/` maps it to an `AppRoutes` tab). **External, not code:** upload an
  APNs auth key to the Firebase console for iOS; push only works on a physical
  device; permission is requested after the first frame for now (move to
  onboarding). The push token registers through the location feature
  (`/v2/location`, `DeviceLocationReporter` in `core/geo/`) on meaningful moves.
- **LoRa mesh (`core/meshtastic/`):** the off-grid path. Three layers, each with
  one job. `MeshtasticService` (domain) is the **transport** — connect/scan,
  packet streams, `sendData`, and the radio's channel/region config; its BLE
  impl lives in `data/` over the vendored `third_party/meshtastic_flutter`
  (locally forked — see its CHANGELOG). `MeshLink` (created in `bootstrap`, not
  by a page) owns the **session**: the chosen radio is persisted and *is* the
  intent to stay connected, so it survives page changes, drops and app
  restarts; only `detach()` stops it. It also provisions the radio after every
  connect. `DpipMeshGateway` is the **data plane**: DPIP disaster payloads ride
  `PRIVATE_APP` (256) inside a 5-byte versioned envelope (`dpip_mesh.dart`) on
  the fixed `DPIP` channel (PSK `AQ==`, region `TW`) — never on
  `TEXT_MESSAGE_APP`, which belongs to the user's chat. A feed broadcasts by
  handing over a `DpipMeshPacket` and receives by listening to `inbound`; it
  never sees Bluetooth. Wire codes and the envelope layout are pinned by tests
  — changing one is a protocol break, so bump the version instead. Mesh
  delivery is **best-effort** (lossy, duty-cycle limited, unacknowledged): a
  safety-critical feed may add it as a path, never rely on it as the only one.
  Radio writes go through local admin messages (`from == 0` exempts them from
  the remote-admin session key); a channel write is read back before it counts,
  and a region change is confirmed by the user because the firmware reboots the
  radio and takes every other channel with it.
- **Native-first:** prefer platform channels / built-ins over third-party
  plugins where practical (e.g. `core/platform/` device_info, compass).
- **Icons:** use Flutter's built-in Material `Icons` only — no third-party icon
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
- **Localization (i18n):** every user-facing string goes through
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
- **Persistence (contract):** everything persisted lives in **SQLite**, split
  into two files by *durability*: `dpip.db` in application-support (settings,
  `tle`, `mesh_*`) and `http_etag_cache.db` in the platform cache directory
  (`http_cache`, `net_bucket`). The split is the point — the OS may empty the
  cache directory whenever it wants space, so nothing that cannot be re-fetched
  may live there, and `AppDatabase.clearCache()` holds no handle to the durable
  file, which makes "clear cache deleted my settings" unavailable rather than
  merely avoided. Tables are one-per-category and each is owned by exactly one
  store (`core/storage/app_database.dart` documents the map).
  Settings go through the typed `SettingsStore` facade
  (`core/settings/settings_store.dart`), keyed by a `SettingKey<T>` from the
  `SettingKeys` registry (`core/settings/setting_keys.dart`) — **never a raw
  string**. `SettingKey`'s constructor is private, so a key can only be minted
  in the registry; `SettingsStore` has no `String`-taking overload, so an
  ad-hoc key can't reach storage — the compiler rejects it, not review. Reads
  are synchronous (the table is loaded into memory once at bootstrap); writes
  are async and log rather than throw. Add a setting = add one `SettingKey<T>`;
  never change an existing key string without a migration. `shared_preferences`
  is **not a dependency** — nothing may import it — and only a table's owning
  store may import `sqflite`; both enforced by `tool/check_storage.sh`.
- Every file starts with a doc comment; one public declaration = one clear
  responsibility.

## CI & gates

`.github/workflows/ci.yml` runs on every push/PR and must stay green. It uses
the mise-pinned toolchain and runs, in order: the layering gate
(`tool/check_layering.sh`), the localization gate (`tool/check_l10n.sh`), the
storage gate (`tool/check_storage.sh`), the lockfile gate (`tool/check_pubspec_lock.sh`),
`dart format --set-exit-if-changed`, a codegen-drift check (`build_runner` +
`git diff --exit-code` — committed `*.g.dart` / `*.freezed.dart` must match a
fresh build), `flutter analyze`, and `flutter test`. The four bash gates need
only bash + python3 (no toolchain), so they fail fast. `android.yml` /
`ios.yml` build release artifacts, and `review.yml` adds an automated PR
review. Run these locally before pushing. Safety-critical seismic math is
pinned by golden tests (`test/features/earthquake/eew_estimator_test.dart`);
if you change the EEW estimator, update those goldens deliberately.

## Commits

- Keep commits focused; run `flutter analyze` (clean) before committing.
- Do **not** add `Co-Authored-By` / "Generated with" trailers.
