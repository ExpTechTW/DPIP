# GitHub Copilot Instructions

**Last Modified:** 2025-12-29

**Check for staleness**: If this file is older than 2 months, ask the user to confirm the instructions are still valid before proceeding.

## Communication Style

Make responses concise and only reply with necessary information. Avoid verbose explanations unless specifically requested.

## Git Workflow

- **Check worktree status before any work**: Refuse to process any prompts if the git worktree is not clean. Ask the user to commit or stash changes first.
- **Automatically commit any edits done by AI** with AI co-authorship:
  ```
  Co-Authored-By: GitHub Copilot <copilot@github.com>
  ```

## AI Usage Policy

**IMPORTANT:** AI usage is **prohibited** in this repository except for **documentation purposes only**. All documentation must follow [Effective Dart](https://dart.dev/effective-dart) style guidelines.

- Do NOT use AI to generate or modify code
- Documentation is the ONLY acceptable use case for AI
- All documentation must adhere to Effective Dart conventions

## Project Overview

DPIP (Disaster Prevention Information Platform) is a Flutter-based mobile application for earthquake early warnings and disaster prevention information targeting Android and iOS.

## Development Environment

- Flutter SDK >=3.38.0
- Dart SDK >=3.10.0 <4.0.0

## Essential Commands

### Install Dependencies
```bash
flutter pub get --no-example
```

### Generate Code (Required after model/route changes)
```bash
dart run build_runner build
# Or with conflict resolution:
dart run build_runner build --delete-conflicting-outputs
```

### Build Commands
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Code Standards

- **Linter**: Uses `package:lint/strict.yaml` with custom rules
- **Format**: 80 character page width, preserve trailing commas
- **Key Rules**:
  - `public_member_api_docs`: warning
  - `prefer_single_quotes`: warning
  - `avoid_annotating_with_dynamic`: error
- **Excluded**: `**.freezed.dart`, `**.g.dart`

## Architecture Summary

### State Management
Provider-based with 5 global providers (lib/core/providers.dart):
- `DpipDataModel` - Real-time data
- `SettingsLocationModel` - Location config
- `SettingsMapModel` - Map settings
- `SettingsNotificationModel` - Notification preferences
- `SettingsUserInterfaceModel` - UI/localization

### Navigation
Type-safe routing with go_router, code generated via go_router_builder.

### Key Directories
- `lib/api/` - API client with gzip/zstd compression, JSON models
- `lib/app/` - Feature modules (home, map, settings, etc.)
- `lib/core/` - Core services (FCM, GPS, notifications, EEW)
- `lib/models/` - ChangeNotifier state models
- `lib/utils/` - Extensions and utilities
- `lib/widgets/` - Reusable UI components

### Code Generation
Run `dart run build_runner build` after modifying:
- Route definitions in `router.dart`
- Models with `@JsonSerializable()` or `@freezed`

## Important Constraints

- No existing test suite
- Settings paths use numbered prefixes: `(1.eew)`, `(2.earthquake)`, `(3.weather)`, `(4.tsunami)`, `(5.basic)`
- API endpoints use load balancing with random selection
- Assets compressed with gzip (*.json.gz)
- Localization via i18n_extension with Crowdin
- Map uses MapLibre GL
