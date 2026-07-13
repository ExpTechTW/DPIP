# DPIP Architecture

A clean, **feature-first + layered** architecture. The goal is that any feature
can be understood, tested, and changed in isolation, and that cross-cutting
concerns live in exactly one place.

## Top-level layout

```
lib/
├── main.dart              # entry point → bootstrap()
├── bootstrap.dart         # init platform services (Firebase, DI) then runApp
├── app/                   # app shell: wiring, not features
│   ├── app.dart           # root MaterialApp.router + providers
│   ├── router/            # go_router route table (central AppRoutes registry)
│   ├── shell/             # bottom-nav shell (StatefulShellRoute)
│   └── theme/             # Material 3 theming + design tokens (spacing/radius/…)
├── core/                  # cross-cutting, feature-agnostic building blocks
│   ├── error/             # Result + Failure hierarchy
│   ├── geo/               # geometry helpers (point-in-polygon)
│   ├── logging/           # the Log facade
│   ├── models/            # shared value types (LatLng, …)
│   ├── network/           # Dio ApiClient, region selection, error→Failure
│   ├── notifications/     # FCM/APNs + awesome channels, tap routing seam
│   ├── platform/          # native-first device_info / compass
│   ├── realtime/          # polling spine (channel/state/clock/staleness)
│   └── settings/          # app-wide persisted/ephemeral state (provider)
├── features/              # one folder per feature, each self-contained
│   └── <feature>/
│       ├── data/          # datasources, repository impls, JSON→model mapping
│       ├── domain/        # @freezed entities, repository interfaces (pure Dart)
│       └── presentation/  # pages/, widgets/, controllers (state)
└── shared/                # reused across ≥2 features
    ├── map/               # the reusable MapLibre surface (layers, timeline)
    ├── navigation/        # AppRoutes (route names/paths)
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
restored per-need in `android/` and `ios/`. Firebase reads native
`google-services.json` / `GoogleService-Info.plist`; `Firebase.initializeApp()`
in `bootstrap.dart` needs no generated options file.
