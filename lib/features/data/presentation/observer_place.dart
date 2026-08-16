/// Which place the astronomy pages compute for.
///
/// Rise, set, twilight and pointing are all statements about a location, so
/// every astronomy page has to answer "where?" the same way and then *say* the
/// answer. A time with no place attached is just a number.
///
/// The order is: the township the user has selected, then the one GPS
/// reported, then the nearest township to a documented fallback. The fallback
/// is resolved through the directory rather than used as bare coordinates, so
/// the page always has a real township name to show — never a silent
/// assumption.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Used only when no township is known: Taipei City Hall.
const ({double lat, double lng}) fallbackPlace = (lat: 25.0330, lng: 121.5654);

/// The township this page's times belong to, or null if the directory is
/// empty (which only happens if the bundled asset failed to load).
Town? observerTown(BuildContext context) {
  final directory = context.read<TownDirectory>();
  final regions = context.watch<RegionStore>();
  final code = switch (regions.selected) {
    SavedArea(:final code) => code,
    CurrentArea(:final code) => code,
    NationwideArea() => null,
  };
  return directory.byCode(code ?? regions.currentCode) ??
      directory.nearest(fallbackPlace.lat, fallbackPlace.lng);
}
