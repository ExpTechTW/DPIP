import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:flutter/foundation.dart';

/// A hand-off to the retained Home branch. Listeners only schedule consumption
/// after the frame; redirect itself must never mutate the selected region.
final class WidgetLocationRequests extends ChangeNotifier {
  WidgetLocationLink? _pending;

  void request(WidgetLocationLink? link) {
    _pending = link;
    notifyListeners();
  }

  WidgetLocationLink? takePending() {
    final request = _pending;
    _pending = null;
    return request;
  }
}

/// One Widget tap. Instances intentionally retain identity, so two taps on the
/// same target are two requests. Only the configured identifier is accepted.
final class WidgetLocationLink {
  WidgetLocationLink._(this.identifier);

  final String identifier;

  static const queryKey = 'widgetLocation';

  static WidgetLocationLink? parse(Uri uri) {
    final values = uri.queryParametersAll[queryKey];
    if (values == null || values.length != 1) return null;
    final identifier = values.single;
    // Match WidgetLocationCatalogLocation: exactly three ASCII digits.
    if (identifier != 'current-location' &&
        !RegExp(r'^region:[0-9]{3}$').hasMatch(identifier)) {
      return null;
    }
    return WidgetLocationLink._(identifier);
  }

  /// Resolve at consumption time: saved locations may have been removed while
  /// onboarding was visible. Do not add a region or pass -1 into select(),
  /// whose clamping would silently select a different area.
  bool select(RegionStore regions, TownDirectory directory) {
    if (identifier == 'current-location') {
      regions.select(1);
      return true;
    }
    final code = identifier.substring('region:'.length);
    final position = regions.savedCodes.indexOf(code);
    if (position < 0 || directory.byCode(code) == null) return false;
    regions.select(position + 2);
    return true;
  }
}
