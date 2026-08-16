/// Opens this app's page in the system settings.
///
/// One implementation, because the alternatives are not equivalent and one of
/// them does not work. `awesome_notifications`' own settings page silently did
/// nothing on iOS — the call returned, logged, and no navigation happened —
/// which turned the "Open Settings" button into the second dead end in the
/// same flow. `permission_handler` is the canonical cross-platform route
/// (`UIApplication.openSettingsURLString` on iOS, the app-details intent on
/// Android) and is already a dependency.
///
/// Every permission surface routes through here, so the button either works
/// everywhere or fails everywhere — never one row silently.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Returns whether the settings page was actually opened, which is the part
/// worth logging: a `false` here is the difference between "the user chose not
/// to grant it" and "the button does nothing".
Future<bool> openAppSettingsPage() async {
  try {
    final opened = await ph.openAppSettings();
    Log.info('permission: openAppSettings -> $opened');
    return opened;
  } catch (error, stackTrace) {
    Log.handle(error, stackTrace, 'openAppSettings');
    return false;
  }
}
