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
│   ├── app.dart           # root MaterialApp.router
│   ├── router/            # go_router route table (aggregates feature routes)
│   └── theme/             # Material 3 light/dark theming
├── core/                  # cross-cutting, feature-agnostic building blocks
│   ├── constants/         # app-wide constants (endpoints, keys)
│   ├── network/           # Dio client + interceptors
│   ├── error/             # Failure hierarchy
│   ├── theme/             # shared design tokens
│   └── utils/             # extensions & helpers
├── features/              # one folder per feature, each self-contained
│   └── <feature>/
│       ├── data/          # datasources, DTO models, repository implementations
│       ├── domain/        # entities, repository interfaces, use cases
│       └── presentation/  # pages/, widgets/, controllers (state)
└── shared/                # widgets/models reused across ≥2 features
    ├── widgets/
    └── models/
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

- Each page exposes `static const path` / `name` for its route; `app/router`
  aggregates them.
- Models use `@freezed` / `@JsonSerializable`; run
  `dart run build_runner build` after changing them.
- One public declaration = one clear responsibility; extract private widgets
  (`_Foo`) rather than deeply nesting `build`.

## Adding a feature

1. `lib/features/<name>/{data,domain,presentation}`.
2. Define the `domain` entity + repository interface.
3. Implement `data` (datasource + repository) against the API via `core/network`.
4. Build `presentation` (page + controller); register the route in `app/router`.

## Native config

Platform integration (Firebase, APNs critical-alerts, signing, permissions) is
restored per-need in `android/` and `ios/`. Firebase reads native
`google-services.json` / `GoogleService-Info.plist`; `Firebase.initializeApp()`
in `bootstrap.dart` needs no generated options file.
