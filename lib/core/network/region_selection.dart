import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/settings/persisted.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's selected LB and Core regions and exposes the failover
/// order used by [ApiClient]. The selection is persisted so it survives
/// restarts.
///
/// This is the "state management" for endpoint selection: instead of relying on
/// DNS balancing, the app explicitly picks a region and controls failover.
class RegionSelection extends ChangeNotifier {
  RegionSelection(SharedPreferences prefs)
    : _lb = PersistedEnum(
        prefs,
        key: 'network:region:lb',
        values: LbRegion.values,
        fallback: LbRegion.tpe1,
        encode: (r) => r.code,
      ),
      _core = PersistedEnum(
        prefs,
        key: 'network:region:core',
        values: CoreRegion.values,
        fallback: CoreRegion.tnn1,
        encode: (r) => r.code,
      );

  final PersistedEnum<LbRegion> _lb;
  final PersistedEnum<CoreRegion> _core;

  /// The selected LB (Taiwan edge) region.
  LbRegion get lb => _lb.value;

  /// The selected Core region.
  CoreRegion get core => _core.value;

  set lb(LbRegion value) {
    if (_lb.set(value)) notifyListeners();
  }

  set core(CoreRegion value) {
    if (_core.set(value)) notifyListeners();
  }

  /// LB regions in failover order — the selected region first.
  List<LbRegion> get lbOrder => [
    _lb.value,
    ...LbRegion.values.where((r) => r != _lb.value),
  ];

  /// Core regions in failover order — the selected region first.
  List<CoreRegion> get coreOrder => [
    _core.value,
    ...CoreRegion.values.where((r) => r != _core.value),
  ];
}
