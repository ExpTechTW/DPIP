import 'package:dpip/core/network/api_region.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's selected LB and Core regions and exposes the failover
/// order used by [ApiClient]. The selection is persisted so it survives
/// restarts.
///
/// This is the "state management" for endpoint selection: instead of relying on
/// DNS balancing, the app explicitly picks a region and controls failover.
class RegionSelection extends ChangeNotifier {
  RegionSelection(this._prefs)
    : _lb = _read(_prefs, _lbKey, LbRegion.values, LbRegion.tpe1),
      _core = _read(_prefs, _coreKey, CoreRegion.values, CoreRegion.tnn1);

  final SharedPreferences _prefs;

  static const String _lbKey = 'network:region:lb';
  static const String _coreKey = 'network:region:core';

  LbRegion _lb;
  CoreRegion _core;

  /// The selected LB (Taiwan edge) region.
  LbRegion get lb => _lb;

  /// The selected Core region.
  CoreRegion get core => _core;

  set lb(LbRegion value) {
    if (value == _lb) return;
    _lb = value;
    _prefs.setString(_lbKey, value.code);
    notifyListeners();
  }

  set core(CoreRegion value) {
    if (value == _core) return;
    _core = value;
    _prefs.setString(_coreKey, value.code);
    notifyListeners();
  }

  /// LB regions in failover order — the selected region first.
  List<LbRegion> get lbOrder => [
    _lb,
    ...LbRegion.values.where((r) => r != _lb),
  ];

  /// Core regions in failover order — the selected region first.
  List<CoreRegion> get coreOrder => [
    _core,
    ...CoreRegion.values.where((r) => r != _core),
  ];

  static T _read<T extends Enum>(
    SharedPreferences prefs,
    String key,
    List<T> values,
    T fallback,
  ) {
    final code = prefs.getString(key);
    for (final v in values) {
      if ((v as dynamic).code == code) return v;
    }
    return fallback;
  }
}
