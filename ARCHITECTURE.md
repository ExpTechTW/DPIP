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
│   │                      # home · location · log · map · more · notification ·
│   │                      # onboarding · settings · sponsor · typhoon · weather
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

## Conventions

- Route names/paths live in `shared/navigation/app_routes.dart` (`AppRoutes`);
  pages don't declare their own path. Navigate by name (`context.goNamed`) so no
  feature imports another feature's page widget — the layering gate rejects it.
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
