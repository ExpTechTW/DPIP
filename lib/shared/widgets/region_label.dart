/// Display labels for Home areas, derived from a township **code** on demand.
///
/// Names are never stored on a [HomeArea] — they're resolved here from the
/// [TownDirectory] each time, so a locale change or a renamed town is always
/// correct. Keeping this in one pure function means the region bar and the home
/// body can't drift apart on how an area is named.
library;

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';

/// The badge label for [area]: 全國 / 所在地 / the saved town's name.
///
/// The current-location slot always reads 所在地 even with no GPS fix — the
/// "can't get location" wording ([AppLocalizations.regionCurrentUnavailable])
/// belongs to the body, not the switcher, so the slot never disappears.
String regionAreaLabel(
  AppLocalizations l10n,
  TownDirectory directory,
  HomeArea area,
) {
  return switch (area) {
    NationwideArea() => l10n.regionNationwide,
    CurrentArea() => l10n.regionCurrent,
    SavedArea(:final code) => directory.byCode(code)?.townName ?? code,
  };
}
