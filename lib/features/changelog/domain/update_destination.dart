/// Where the update button goes, per install source.
///
/// Each entry is a pair: the app-scheme URL that opens the store app directly
/// on DPIP's page, and an `https` fallback for when that scheme is not
/// installed (no Play Store on the device, no TestFlight app) — a web page the
/// browser can always show beats a button that does nothing.
library;

import 'package:dpip/core/platform/install_source.dart';

/// A destination for "update now": try [scheme] first, then [web].
class UpdateDestination {
  const UpdateDestination({required this.scheme, required this.web});

  /// Store-app URL — opens the listing inside the store app.
  final String scheme;

  /// Browser fallback.
  final String web;
}

/// The App Store item id for DPIP (also the id TestFlight uses).
const String _appStoreId = '6468026362';

/// The Android application id.
const String _androidPackage = 'com.exptech.dpip';

/// Resolves the update destination for [source].
///
/// [releaseUrl] is the GitHub release page, used for a build that came from no
/// store at all — its assets are the only update path a sideload has. When it
/// is empty the releases list stands in.
UpdateDestination updateDestinationFor(
  InstallSource source, {
  String releaseUrl = '',
}) {
  switch (source) {
    case InstallSource.appStore:
      return const UpdateDestination(
        scheme: 'itms-apps://apps.apple.com/app/id$_appStoreId',
        web: 'https://apps.apple.com/tw/app/dpip/id$_appStoreId',
      );
    case InstallSource.testFlight:
      // TestFlight has no per-app deep link that works without a public join
      // code, so this opens the app itself — the tester's build list is one
      // screen, and DPIP is on it. Better than sending a tester to the App
      // Store, which would only ever offer them the stable build.
      return const UpdateDestination(
        scheme: 'itms-beta://beta.itunes.apple.com/v1/app/$_appStoreId',
        web: 'https://testflight.apple.com/',
      );
    case InstallSource.playStore:
      return const UpdateDestination(
        scheme: 'market://details?id=$_androidPackage',
        web: 'https://play.google.com/store/apps/details?id=$_androidPackage',
      );
    case InstallSource.development:
    case InstallSource.github:
    case InstallSource.unknown:
      final url = releaseUrl.isEmpty
          ? 'https://github.com/ExpTechTW/DPIP/releases'
          : releaseUrl;
      return UpdateDestination(scheme: url, web: url);
  }
}
