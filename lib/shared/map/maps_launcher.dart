/// Opening a map point in an external map app (Google Maps / Apple Maps),
/// with a platform-default shortcut and a user-facing app picker.
///
/// Scheme knowledge lives here (and nowhere else): the native app deep links,
/// the platform default, and the choice sheet. It only takes a coordinate +
/// optional label, so any surface (the DPM detail sheet today, a station sheet
/// tomorrow) can hand a point over without knowing a thing about URI schemes.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A map point to hand to an external map app.
@immutable
class MapLaunchTarget {
  const MapLaunchTarget({required this.lat, required this.lng, this.label});

  final double lat;
  final double lng;

  /// Shown as the dropped-pin label (the facility name), when known.
  final String? label;
}

/// The two native map apps we can deep-link to on both platforms.
enum MapApp {
  google,
  apple;

  /// The OS's home map app — Apple Maps on iOS, Google Maps elsewhere.
  /// The default for a one-tap open, so a tap goes to the app the user
  /// actually thinks of as "the map" on their device.
  static MapApp ofPlatform([TargetPlatform? platform]) =>
      switch (platform ?? defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => MapApp.apple,
        _ => MapApp.google,
      };

  /// The localised app name, e.g. for the choice sheet.
  String label(AppLocalizations l10n) => switch (this) {
    MapApp.google => l10n.mapAppGoogleMaps,
    MapApp.apple => l10n.mapAppAppleMaps,
  };
}

/// Deep-link URL for [app] at [target].
///
/// Both are cross-platform web endpoints that hand off to the native app when
/// installed, so no `comgooglemaps://` / Apple-scheme fallback dance is needed.
/// Google gets the `lat,lng(label)` pin syntax (a named marker at the exact
/// point); Apple gets `q` plus an explicit `ll` + `z` so the map frames the
/// point even before the query resolves.
String mapsAppUrl(MapApp app, MapLaunchTarget target) {
  final center = '${target.lat},${target.lng}';
  return switch (app) {
    MapApp.google =>
      'https://www.google.com/maps/search/?api=1&query=${_enc(target.label == null ? center : '$center(${target.label})')}',
    MapApp.apple =>
      'https://maps.apple.com/?q=${_enc(target.label ?? center)}&ll=$center&z=17',
  };
}

/// Opens [target] in [app], leaving the app. Returns false when no handler
/// exists (e.g. a desktop without the app).
Future<bool> openInMapApp(MapApp app, MapLaunchTarget target) => launchUrl(
  Uri.parse(mapsAppUrl(app, target)),
  mode: LaunchMode.externalApplication,
);

/// Dials [phone] in the platform's phone app via a `tel:` URI. Returns false
/// when the device has no handler (no SIM / a desktop).
///
/// The string is a raw display number (`02-12345678`, `+886 9xx`), so it is
/// stripped down to the characters a phone dialler accepts rather than handed
/// to the OS verbatim — an encoded space or stray bracket is what turns a tap
/// into "no app can open this".
Future<bool> callPhoneNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^\d+#*]'), '');
  if (digits.isEmpty) return Future.value(false);
  // `Uri.parse` keeps the extension marker (`#`/`*`) and `+` verbatim —
  // `Uri(scheme: 'tel', path: …)` would percent-encode `#` into `%23`.
  return launchUrl(
    Uri.parse('tel:$digits'),
    mode: LaunchMode.externalApplication,
  );
}

/// One-tap open in the platform's home map app.
Future<bool> openInDefaultMapApp(MapLaunchTarget target) =>
    openInMapApp(MapApp.ofPlatform(), target);

/// Bottom sheet letting the user pick a map app (or copy the coordinates) for
/// [target]. The platform's home app is listed first and marked 預設. Returns
/// the chosen app, or null if the sheet was dismissed or the user copied the
/// coordinates.
Future<MapApp?> showMapAppPicker(BuildContext context, MapLaunchTarget target) {
  final l10n = AppLocalizations.of(context);
  final defaultApp = MapApp.ofPlatform();
  return showModalBottomSheet<MapApp>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.dpmOpenInMaps,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final app in [
            defaultApp,
            ...MapApp.values.where((a) => a != defaultApp),
          ])
            ListTile(
              leading: Icon(
                app == MapApp.google
                    ? Icons.map_outlined
                    : Icons.navigation_outlined,
              ),
              title: Text(
                app == defaultApp
                    ? l10n.mapAppDefault(app.label(l10n))
                    : app.label(l10n),
              ),
              onTap: () => Navigator.pop(sheetContext, app),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: Text(l10n.mapAppCopyCoordinates),
            onTap: () {
              final copied = '${target.lat},${target.lng}';
              Clipboard.setData(ClipboardData(text: copied));
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.mapAppCoordinatesCopied)),
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// The whole "open in a map app" flow: picker, then open, then report.
///
/// [showMapAppPicker] only *returns* the chosen app — opening it is this
/// function's job, because a picker that forgets to open (as callers did when
/// the sheet was first wired up) reads as "maps don't work" to a user who just
/// picked one. Returns when the sheet was dismissed, the coordinates were
/// copied, the app opened, or the open failed with a snackbar.
Future<void> pickAndOpenMapApp(
  BuildContext context,
  MapLaunchTarget target,
) async {
  final app = await showMapAppPicker(context, target);
  if (app == null || !context.mounted) return;
  final opened = await openInMapApp(app, target);
  if (!opened && context.mounted) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.mapAppOpenFailed(app.label(l10n)))),
    );
  }
}

String _enc(String s) => Uri.encodeComponent(s);
