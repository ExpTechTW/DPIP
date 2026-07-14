/// Opens this app's page in the system Settings.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:geolocator/geolocator.dart';

/// Opens the app's own settings page in the OS Settings — where the user can
/// change any permission (notifications, location, …). Best-effort; never
/// throws.
///
/// Delegates to geolocator's `openAppSettings`, which is a generic "open my app
/// settings" call (`UIApplication.openSettingsURLString` on iOS, the app
/// details page on Android) — not location-specific — so it's the shared opener
/// for every permission banner, not just location.
Future<void> openAppSettings() async {
  try {
    await Geolocator.openAppSettings();
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'openAppSettings');
  }
}
