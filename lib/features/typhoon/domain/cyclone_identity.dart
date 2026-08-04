/// Name matching and nearest-cyclone selection for multi-typhoon UI.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';

/// Trimmed value, or `null` when absent/blank.
///
/// CWA sends `""` (not `null`) for a storm that has no name yet, so a plain
/// `??` chain silently keeps the empty string — see [cycloneDisplayName].
String? presentText(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

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

/// Stable selection key from a storm's identity fields.
///
/// Primary key is always the CWA tropical-depression number (`TD15`), which
/// exists even before a system is named. This avoids empty-name breakage when
/// the nearest active system is an unnamed depression.
///
/// Falls back to names only when `tdNo` is unexpectedly absent.
String cycloneKeyOf({String? name, String? cwaName, String? tdNo}) {
  final td = presentText(tdNo);
  if (td != null) return 'TD$td';
  return presentText(name) ?? presentText(cwaName) ?? '';
}

/// Stable wire key for selection — see [cycloneKeyOf].
String cycloneKey(TyphoonCyclone c) =>
    cycloneKeyOf(name: c.name, cwaName: c.cwaName, tdNo: c.tdNo);

/// Whether [key] selects the storm described by the `storm*` fields.
///
/// Matches by the storm's stable [cycloneKeyOf] and keeps name checks for
/// backward compatibility with older persisted selections.
bool cycloneMatchesKey({
  required String? key,
  required String? stormName,
  String? stormCwaName,
  String? stormTdNo,
}) {
  final k = presentText(key);
  if (k == null) return false;
  final stormKey = cycloneKeyOf(
    name: stormName,
    cwaName: stormCwaName,
    tdNo: stormTdNo,
  );
  if (cycloneNamesMatch(k, stormKey)) return true;
  if (cycloneNamesMatch(k, stormName) || cycloneNamesMatch(k, stormCwaName)) {
    return true;
  }
  return false;
}

/// Display name for a storm — CWA name preferred, else the international name.
///
/// `null` when the system is unnamed; the caller supplies the localized
/// "tropical depression" wording (this layer has no [BuildContext]).
String? cycloneDisplayName({String? cwaName, String? name}) =>
    presentText(cwaName) ?? presentText(name);

/// Strip leading zeros from a CWA `tdNo` / `tyNo` for display (`"014"` → `"14"`).
String? cycloneNumberLabel(String? raw) {
  final t = presentText(raw);
  if (t == null) return null;
  final n = int.tryParse(t);
  return n == null ? t : '$n';
}

/// Sheet / picker title parts.
///
/// - Named typhoon (`tyNo` + display name) → `isTyphoon: true`, use
///   「{name} TY {n}」.
/// - Otherwise with `tdNo` → `isTyphoon: false`, use 「熱帶性低氣壓 TD {n}」.
/// - Else fall back to [displayName] alone (caller localizes TD wording).
({bool isTyphoon, String? number, String? displayName}) cycloneTitleSpec({
  String? name,
  String? cwaName,
  String? tyNo,
  String? tdNo,
}) {
  final display = cycloneDisplayName(cwaName: cwaName, name: name);
  final ty = cycloneNumberLabel(tyNo);
  if (ty != null && display != null) {
    return (isTyphoon: true, number: ty, displayName: display);
  }
  final td = cycloneNumberLabel(tdNo);
  if (td != null) {
    return (isTyphoon: false, number: td, displayName: display);
  }
  return (isTyphoon: false, number: null, displayName: display);
}

/// Warning applies only when the CAP typhoon block names the selected storm
/// (or shares its `tdNo`) and the bulletin is not a lift (`Cancel`) / inactive
/// leftover.
///
/// Off-season `/warning` often returns the previous storm's `Cancel` — without
/// this check the UI would paint the wrong name's alert on the active cyclone.
bool warningAppliesTo(
  TyphoonWarning warning, {
  required String? name,
  String? cwaName,
  String? tdNo,
}) {
  if (!warning.active) return false;
  if (warning.msgType.toLowerCase() == 'cancel') return false;
  final warningTd = presentText(warning.tdNo);
  final selectedTd = presentText(tdNo);
  if (warningTd != null && selectedTd != null) {
    return warningTd == selectedTd;
  }
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

/// Track entry matching [key] (name, CWA name, or `TD…` number), else `null`.
TyphoonTrack? trackForKey(TrackPayload? payload, String? key) {
  if (payload == null) return null;
  for (final c in payload.cyclones) {
    if (cycloneMatchesKey(
      key: key,
      stormName: c.name,
      stormCwaName: c.cwaName,
      stormTdNo: c.tdNo,
    )) {
      return c;
    }
  }
  return null;
}

/// Index entry matching [key], else `null`.
TyphoonCyclone? cycloneForKey(CycloneIndex? index, String? key) {
  if (index == null) return null;
  for (final c in index.cyclones) {
    if (cycloneMatchesKey(
      key: key,
      stormName: c.name,
      stormCwaName: c.cwaName,
      stormTdNo: c.tdNo,
    )) {
      return c;
    }
  }
  return null;
}
