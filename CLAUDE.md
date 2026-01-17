# CLAUDE.md

**Last Modified:** 2025-12-29

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Check for staleness**: If this file is older than 2 months, ask the user to confirm the instructions are still valid before proceeding.

## Communication Style

**Make responses concise and only reply with necessary information.** Avoid verbose explanations unless specifically requested.

## Git Workflow

**Check worktree status before any work**: Refuse to process any prompts if the git worktree is not clean. Ask the user to commit or stash changes first.

**Automatically commit any edits done by AI** with AI co-authorship:
```
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Project Overview

DPIP (Disaster Prevention Information Platform) is a Flutter-based mobile application developed by a Taiwan-based team. It integrates earthquake early warning (EEW) data from TREM-Net (Taiwan Real-time Earthquake Monitoring Network) and Central Weather Bureau data to provide users with disaster prevention information.

**Target Platforms:** Android and iOS

## AI Usage Policy

**IMPORTANT:** AI usage is **prohibited** in this repository except for **documentation purposes only**. All documentation must follow [Effective Dart](https://dart.dev/effective-dart) style guidelines.

- Do NOT use AI to generate or modify code
- Documentation is the ONLY acceptable use case for AI
- All documentation must adhere to Effective Dart conventions

## Development Environment

```console
Flutter 3.35.1 • channel stable
Framework • revision 20f8274939 • 2025-08-14 10:53:09 -0700
Engine • hash 6cd51c08a88e7bbe848a762c20ad3ecb8b063c0e
Tools • Dart 3.9.0 • DevTools 2.48.0
```

Required minimum:
- Flutter SDK >=3.38.0
- Dart SDK >=3.10.0 <4.0.0

## Build and Development Commands

### Install Dependencies
```bash
flutter pub get --no-example
```

### Generate Code (Required after model changes)
```bash
dart run build_runner build
```

For conflicting outputs:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Build Commands

**Android APK:**
```bash
flutter build apk --release
```

**Android for specific platforms:**
```bash
flutter build apk --release --target-platform android-arm64,android-x64
```

**iOS:**
```bash
flutter build ios --release
```

### Code Analysis

The project uses `package:lint/strict.yaml` with additional custom rules defined in `analysis_options.yaml`:
- `flutter_style_todos`: error
- `prefer_single_quotes`: warning
- `avoid_annotating_with_dynamic`: error
- `public_member_api_docs`: warning

Generated files (`**.freezed.dart`, `**.g.dart`) are excluded from analysis.

### Code Formatting

Format settings (page_width: 80, trailing_commas: preserve):
```bash
dart format lib/
```

## Architecture Overview

### Core Architecture Pattern

The app follows a **Provider-based state management** architecture with the following key components:

#### Global State Management (`lib/core/providers.dart`)

Five primary providers managed through `GlobalProviders`:
- `DpipDataModel` - Real-time earthquake and weather data
- `SettingsLocationModel` - User location preferences
- `SettingsMapModel` - Map display settings
- `SettingsNotificationModel` - Notification preferences
- `SettingsUserInterfaceModel` - UI settings and localization

These are initialized early in `main.dart` and provided app-wide via `MultiProvider`.

#### Navigation (`lib/router.dart`)

Uses **go_router** with type-safe routing via code generation (`router.g.dart`):
- TypedGoRoute for standard routes
- TypedShellRoute for nested navigation (e.g., settings)
- Route observation via `TalkerRouteObserver` for debugging

#### Application Initialization Sequence (`lib/main.dart`)

The app performs optimized cold start initialization:
1. `Global.init()` - Loads essential data (package info, preferences, GeoJSON, location database, time tables)
2. `Preference.init()` - Initializes SharedPreferences
3. `GlobalProviders.init()` - Sets up state management
4. Parallel loading of localizations (AppLocalizations, LocationNameLocalizations)
5. Conditional initialization based on first launch:
   - First launch: FCM and notifications initialized before runApp
   - Subsequent launches: Background initialization after runApp for faster startup
6. `CompassService` and `LocationServiceManager` initialized asynchronously

### Directory Structure

```
lib/
├── api/              # API client and data models
│   ├── exptech.dart      # Main API client with gzip/zstd compression
│   ├── route.dart        # API endpoint definitions
│   └── model/            # JSON-serializable data models (freezed/json_annotation)
├── app/              # Feature modules organized by screen
│   ├── home/             # Home page with timeline and weather
│   ├── map/              # MapLibre-based map with earthquake/weather layers
│   ├── settings/         # Settings screens (nested routing)
│   ├── welcome/          # Onboarding flow
│   ├── changelog/        # Changelog display
│   └── layout.dart       # Main app layout wrapper
├── core/             # Core services and initialization
│   ├── compass.dart      # Compass sensor service
│   ├── device_info.dart  # Device information
│   ├── eew.dart          # Earthquake Early Warning logic
│   ├── fcm.dart          # Firebase Cloud Messaging
│   ├── gps_location.dart # GPS location services
│   ├── i18n.dart         # Internationalization loaders
│   ├── notify.dart       # Local notification management (awesome_notifications)
│   ├── preference.dart   # SharedPreferences wrapper
│   ├── providers.dart    # Global state providers
│   ├── rts.dart          # Real-time seismic data
│   ├── service.dart      # Background services (LocationServiceManager)
│   └── update.dart       # App update checking
├── models/           # State management models
│   ├── data.dart         # DpipDataModel (ChangeNotifier)
│   ├── settings/         # Settings models
│   └── map/              # Map-specific models
├── utils/            # Utility functions and extensions
│   ├── constants.dart    # App-wide constants
│   ├── extensions/       # Extension methods (BuildContext, Response, etc.)
│   ├── functions.dart    # Helper functions
│   └── intensity_color.dart, radar_color.dart  # Color mapping utilities
├── widgets/          # Reusable UI components
├── app.dart          # DpipApp widget (MaterialApp wrapper)
├── global.dart       # Global singleton (packageInfo, location data, GeoJSON)
├── main.dart         # App entry point
└── router.dart       # Type-safe routing configuration
```

### Key Architectural Patterns

#### Data Loading and Compression

- **Compressed Assets**: Location data and time tables are gzip-compressed (`assets/*.json.gz`) and decompressed on load for reduced APK size
- **Network Compression**: API client supports gzip, deflate, and zstd compression via custom `_GzipClient`
- **GeoJSON Data**: Box and town boundaries loaded from `assets/box.json` and `assets/map/town.json.gz`

#### API Architecture (`lib/api/`)

- **Load Balancing**: Multiple API endpoints with random selection (`api-1.exptech.dev`, `api-2.exptech.dev`, `lb-1.exptech.dev` through `lb-4.exptech.dev`)
- **Model Generation**: Uses `json_annotation` and `freezed` for immutable data models
- **Type-Safe Routes**: All API endpoints centralized in `api/route.dart` with parameter validation

#### Notification System

Multi-channel notification system with granular control:
- EEW (Earthquake Early Warning)
- Earthquake reports (intensity, monitor, report)
- Weather alerts (thunderstorm, advisory, evacuation)
- Tsunami information
- Announcements

Notifications use `awesome_notifications` for local notifications and FCM for push notifications. Settings stored via `SettingsNotificationModel` and synced to backend.

#### Map Implementation

MapLibre GL-based map (`lib/app/map/`) with multiple layer managers:
- `managers/lightning.dart` - Lightning strike visualization
- `managers/precipitation.dart` - Precipitation data
- `managers/radar.dart` - Weather radar tiles
- `managers/temperature.dart` - Temperature overlays
- `managers/tsunami.dart` - Tsunami warning zones
- `managers/wind.dart` - Wind data

Supports query parameters for initial state (e.g., `/map?layers=radar,lightning&report=12345`).

#### Localization

Uses `i18n_extension` package with translations in `assets/translations/`. Supported locales:
- English (en)
- Japanese (ja)
- Korean (ko)
- Russian (ru)
- Vietnamese (vi)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)

Crowdin integration for community translations.

## Code Generation

This project uses code generation for:
- **Routing**: `go_router_builder` generates type-safe routes in `router.g.dart`
- **JSON Serialization**: `json_serializable` generates `.g.dart` files for models
- **Freezed Models**: `freezed` generates immutable data classes with `.freezed.dart` files

Always run `dart run build_runner build` after modifying:
- Route definitions in `router.dart`
- Models with `@JsonSerializable()` or `@freezed` annotations

## Third-Party Dependencies

### Custom Forks
Several packages use forked versions from ExpTechTW:
- `android_alarm_manager_plus` (from plus_plugins)
- `disable_battery_optimization`
- `flutter_icmp_ping`

### Key Dependencies
- `maplibre_gl` - Map rendering
- `awesome_notifications` + `awesome_notifications_fcm` - Notifications
- `firebase_core` + `firebase_messaging` - Push notifications (min iOS 15 support)
- `provider` - State management
- `go_router` - Navigation
- `freezed_annotation` + `json_annotation` - Code generation
- `geolocator` - GPS location
- `i18n_extension` - Internationalization
- `zstandard` - Compression support

## Firebase Configuration

The app uses Firebase for:
- Cloud Messaging (FCM) for push notifications
- Crashlytics (Android only) for crash reporting

Ensure Firebase configuration files exist:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Pull Request Guidelines

Based on `.github/pull_request_template.md`:
- Keep PRs small when possible
- Use descriptive commit messages
- Update relevant documentation and include screenshots
- Avoid force-pushing after review
- Use draft PRs for work in progress

PR Types:
- Refactoring (重構)
- New Feature (新功能)
- Bug Fix (錯誤修復)
- Optimization (最佳化)
- Documentation Update (技術文件更新)

UI Changes Checklist:
- Semantic variable naming
- AA color contrast compliance

## Debugging

The app includes comprehensive logging via `talker_flutter`:
- Route: `/debug/logs` (AppDebugLogsPage)
- All providers and core services log through `TalkerManager.instance`
- Cold start performance metrics logged in `main.dart`

## Performance Considerations

- **Lazy Initialization**: Non-critical services (DeviceInfo on Android, Compass, Location) initialize asynchronously after runApp
- **First Launch Detection**: Distinguishes first launch to prioritize critical initialization (FCM/notifications)
- **Parallel Loading**: Localizations and global data load concurrently
- **Asset Compression**: Reduces initial load time and APK size

## Important Constraints

- No existing test suite (no `test/` directory)
- Settings are organized with numbered prefixes in paths: `(1.eew)`, `(2.earthquake)`, `(3.weather)`, `(4.tsunami)`, `(5.basic)`
- Some legacy code exists in `app_old/` and `route/` directories
- HTTP proxy support available via settings (`lib/app/settings/proxy/`)
