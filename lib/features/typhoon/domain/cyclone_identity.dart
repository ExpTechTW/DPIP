/// Name matching and nearest-cyclone selection for multi-typhoon UI.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';

/// Case-insensitive trim; treats empty as no match.
bool cycloneNamesMatch(String? a, String? b) {
  if (a == null || b == null) return false;
  final x = a.trim().toLowerCase();
  final y = b.trim().toLowerCase();
  if (x.isEmpty || y.isEmpty) return false;
  return x == y;
}

/// Whether [storm] is the same cyclone as [name]/[cwaName] (cross fields).
bool sameCyclone({
  required String? name,
  String? cwaName,
  required String? stormName,
  String? stormCwaName,
}) {
  return cycloneNamesMatch(name, stormName) ||
      cycloneNamesMatch(name, stormCwaName) ||
      cycloneNamesMatch(cwaName, stormName) ||
      cycloneNamesMatch(cwaName, stormCwaName);
}

/// Stable wire key for selection — international [TyphoonCyclone.name].
String cycloneKey(TyphoonCyclone c) => c.name;

/// Warning applies only when the CAP typhoon block names the selected storm
/// and the bulletin is not a lift (`Cancel`) / inactive leftover.
///
/// Off-season `/warning` often returns the previous storm's `Cancel` — without
/// this check the UI would paint the wrong name's alert on the active cyclone.
bool warningAppliesTo(
  TyphoonWarning warning, {
  required String? name,
  String? cwaName,
}) {
  if (!warning.active) return false;
  if (warning.msgType.toLowerCase() == 'cancel') return false;
  final t = warning.typhoon;
  if (t == null) return false;
  return sameCyclone(
    name: name,
    cwaName: cwaName,
    stormName: t.name,
    stormCwaName: t.cwaName,
  );
}

/// Index of the cyclone closest to [origin] (default: Taiwan). Empty → `-1`.
int indexOfNearestCyclone(
  List<TyphoonCyclone> cyclones, {
  LatLng origin = const LatLng(23.7, 121.0),
}) {
  if (cyclones.isEmpty) return -1;
  var best = 0;
  var bestD = double.infinity;
  for (var i = 0; i < cyclones.length; i++) {
    final c = cyclones[i];
    final d = origin.distanceTo(LatLng(c.latitude, c.longitude));
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

/// Track entry matching [key] (international name or CWA name), else `null`.
TyphoonTrack? trackForKey(TrackPayload? payload, String? key) {
  if (payload == null || key == null || key.isEmpty) return null;
  for (final c in payload.cyclones) {
    if (sameCyclone(name: key, stormName: c.name, stormCwaName: c.cwaName)) {
      return c;
    }
  }
  return null;
}

/// Index entry matching [key], else `null`.
TyphoonCyclone? cycloneForKey(CycloneIndex? index, String? key) {
  if (index == null || key == null || key.isEmpty) return null;
  for (final c in index.cyclones) {
    if (sameCyclone(name: key, stormName: c.name, stormCwaName: c.cwaName)) {
      return c;
    }
  }
  return null;
}
