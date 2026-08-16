# DPIP Architecture

A clean, **feature-first + layered** architecture. The goal is that any feature
can be understood, tested, and changed in isolation, and that cross-cutting
concerns live in exactly one place.

## Top-level layout

```
lib/
├── main.dart              # entry point → bootstrap()
├── bootstrap.dart         # init platform services (Firebase, prefs, SNTP, DI) then runApp
├── app/                   # app shell: wiring, not features
│   ├── app.dart           # root MaterialApp.router + providers
│   ├── router/            # go_router route table (central AppRoutes registry)
│   ├── shell/             # bottom-nav shell (StatefulShellRoute)
│   └── theme/             # Material 3 tokens (spacing/radius/motion/colour/glass)
├── core/                  # cross-cutting, feature-agnostic building blocks
│   ├── di/                # SharedDeps assembly + coreProviders (provider wiring)
│   ├── error/             # Result + Failure hierarchy
│   ├── geo/               # location services, township directory/boundaries
│   ├── logging/           # the Log facade
│   ├── meshtastic/        # LoRa mesh: BLE transport, link keeper, DPIP data plane
│   ├── models/            # shared value types (LatLng, …)
│   ├── network/           # ApiClient + ApiTier + ApiPaths, region failover,
│   │                      # SSE, ETag cache, meteor delta decode
│   ├── notifications/     # FCM/APNs + awesome channels, tap routing seam
│   ├── platform/          # native-first device_info / compass / battery / tier
│   ├── realtime/          # polling spine (channel/state/clock/staleness/SSE)
│   ├── settings/          # typed Prefs facade + persisted/ephemeral controllers
│   ├── storage/           # SQLite stores (ETag cache, network usage)
│   └── weather/           # weather-condition / icon mapping
├── features/              # one folder per feature, each self-contained
│   │                      # changelog · disaster_map · earthquake · events ·
│   │                      # home · location · log · map · meshtastic · more ·
│   │                      # notification · onboarding · settings · sponsor ·
│   │                      # typhoon · weather
│   └── <feature>/
│       ├── data/          # datasources, repository impls, JSON→model mapping
│       ├── domain/        # @freezed entities, repository interfaces (pure Dart)
│       └── presentation/  # pages/, widgets/, controllers (state)
└── shared/                # reused across ≥2 features
    ├── map/               # the reusable MapLibre surface (BaseMap, layers, timeline)
    ├── navigation/        # AppRoutes (route names/paths)
    ├── seismic/           # intensity/report colour scales
    └── widgets/           # AsyncView/RealtimeView, region bar, …
```

## Layer rules

- **presentation** depends on **domain**; never on **data** directly.
- **data** implements **domain** repository interfaces and maps exceptions to
  `core/error` `Failure`s.
- **domain** is pure Dart (no Flutter, no Dio) — the most testable layer.
- **core** and **shared** must not import from **features**.
- Features must not import each other's internals; share via `shared/` or a
  `domain` contract.
- App-wide state several features consume lives outside any one of them —
  `core/settings/` for `ExperimentalSettings`, for instance.

All five are enforced by `tool/check_layering.sh`, which CI runs first.

## Conventions

- Route names/paths live in `shared/navigation/app_routes.dart` (`AppRoutes`);
  pages don't declare their own path. The router (`app/router/`) is the only
  place that imports a page widget — navigate by name
  (`context.pushNamed(AppRoutes.log)`), never by importing another feature's
  page to reach its route. The layering gate rejects it.
- Models use `@freezed` / `@JsonSerializable`; run
  `dart run build_runner build` after changing them.
- One public declaration = one clear responsibility; extract private widgets
  (`_Foo`) rather than deeply nesting `build`.

## Adding a feature

1. `lib/features/<name>/{data,domain,presentation}`.
2. Define the `domain` `@freezed` entity + `Repository` interface returning
   `Result<T>` (pure Dart — the gate forbids Flutter/Dio/data imports here).
3. Implement `data`: a thin datasource calling `core/network`'s `ApiClient`
   (with its own `ApiTier`) + a repository impl that maps errors via
   `guardResult`.
4. Build `presentation` (page + controller); add the route to `AppRoutes` and
   the table in `app/router`.

## Native config

Platform integration (Firebase, APNs critical-alerts, signing, permissions) is
restored per-need in `android/` and `ios/`. Firebase initializes from the
generated `lib/firebase_options.dart` (`DefaultFirebaseOptions`) — not the
native plists — so init never depends on a bundle resource; Android also keeps
`google-services.json` for the GMS plugin.

---

# Contracts

Each of these is a rule the code is expected to follow, not a description of
what it happens to do. They live here so there is one copy: `CLAUDE.md` and
`AGENTS.md` point at this file rather than restating it.

## Logging

Always log through `Log` (`lib/core/logging/log.dart`):
`Log.debug / info / warning / error / handle`. **Never `print` or
`debugPrint`** — `avoid_print` is an error in `analysis_options.yaml`, so it
fails analysis.

Uncaught Flutter/async errors are captured automatically
(`Log.installErrorHandlers()` in `bootstrap.dart`). The log is **persisted** to
the `logs` table with a rolling 24-hour retention (`core/logging/log_store.dart`)
and a row-count backstop under it, so no clock event can empty it. Writes are
buffered and flushed on a timer, on a burst, and when the app backgrounds — a
log call never costs a database round trip, and the store never throws (it is
called from error handlers, where a failure would replace a diagnostic with a
crash).

In-app viewer: the **App 日誌** page (More tab → `LogPage`), which replays the
last 24 hours from the table on open, so it covers the launch that crashed
rather than only the current one.

## State management

`provider`. `bootstrap()` assembles the shared
infrastructure into a `SharedDeps` (`core/di/shared_deps.dart`) and hands it
to each feature's `*Providers(deps)` aggregate (wired through
`core/di/core_providers.dart`); feature state lives in the feature's
`presentation`.

## Networking

never call hosts directly — use the region-aware `ApiClient`
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

## Data & errors

models are `@freezed` value types with generated
`fromJson`/`toJson` (`@JsonKey` for wire names; `boolishInt`/`intFromBool` for
0/1 bools) — template: `features/earthquake/domain/eew.dart`. A feature exposes
a `Repository` **interface in `domain/`** returning `Result<T>`
(`core/error/result.dart`); the impl lives in `data/`, owns JSON→model mapping,
and converts transport/decode errors to a typed `Failure`
(`core/error/failure.dart`) via `mapException` — never leak raw JSON or a
`DioException` above the data layer, and never `try/catch`-swallow into a blank
UI. `strict-casts`/`strict-raw-types` are on. Run `build_runner` after model
changes; add a `fromJson` round-trip test.

## Realtime feeds

live feeds (EEW now, RTS later) flow through
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

## Calibrated time

the `ServerClock` corrects device time via real **SNTP**
(`ntp_time_source.dart` → `flutter_ntp`, UDP/123, `time.exptech.com.tw` primary
/ `time.apple.com` backup — not an HTTP endpoint), anchored to a monotonic
clock so a device-clock or timezone change can't move it (only a resync does).
`RealtimeService` resyncs it every 60s (paused in background, resynced on
resume). Read corrected time anywhere via the global `AppTime` facade
(`AppTime.utc` / `AppTime.utc8`, the fixed-offset Taipei wall clock) — never
`DateTime.now()` for anything the server timestamps.

## Async-state UI

render async/realtime state through the shared
views in `shared/widgets/`, never a hand-rolled `FutureBuilder`/`Consumer` that
drops the error or stale case into a blank screen. `AsyncView<T>` maps a
one-shot `Future<Result<T>>` to loading/data/empty/error (with retry);
`RealtimeView<T>` maps a `RealtimeState<T>`, adding connecting/stale/offline and
a freshness banner so aged safety data is never shown as current. Building
blocks: `LoadingView` / `ErrorView` / `EmptyView`. Template consumer:
`features/earthquake/presentation/pages/earthquake_page.dart`.

## Push notifications

(`core/notifications/`): `firebase_messaging` owns the
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

## LoRa mesh

the off-grid path. Three layers, each with
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

## Native-first

prefer platform channels / built-ins over third-party
plugins where practical (e.g. `core/platform/` device_info, compass).

## Persistence

everything persisted lives in **SQLite**, split
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
