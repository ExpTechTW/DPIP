/// Persisted hidden map layers — the per-layer display switch.
library;

import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// Holds the ids of the map layers the user hid, persisted across launches.
///
/// A hidden layer disappears from every map surface's picker and never
/// renders; the default is an empty set — every layer a surface offers is
/// shown. Toggling lives in the layer-order editor (the tune icon in the
/// picker), which is also where a layer can be shown again. Surfaces resolve
/// the saved ids against their own layer set, so an id saved on one surface
/// but not offered by another is simply ignored there.
///
/// "Hidden" is the complement of "shown", not a third state: the map shows
/// exactly one overlay at a time, so hiding means "never offer it to me
/// again", not "keep it loaded but invisible".
class MapLayerVisibilityController extends ChangeNotifier {
  MapLayerVisibilityController(this._settings)
    : _hidden =
          (_settings.getStringList(SettingKeys.mapLayerHiddenIds) ?? const [])
              .toSet();

  final SettingsStore _settings;

  Set<String> _hidden;

  /// The hidden layer ids. Unmodifiable view — mutate through [setHidden].
  Set<String> get hiddenIds => Set.unmodifiable(_hidden);

  /// Whether the layer [id] is currently hidden.
  bool isHidden(String id) => _hidden.contains(id);

  /// Persists [hidden]'s new state for [id] and notifies watchers (the picker
  /// and every open map surface rebuild). No-op — no write, no notification —
  /// when the state already matches.
  Future<void> setHidden(String id, {required bool hidden}) async {
    if (hidden == _hidden.contains(id)) return;
    final next = Set.of(_hidden);
    hidden ? next.add(id) : next.remove(id);
    _hidden = next;
    await _settings.setStringList(
      SettingKeys.mapLayerHiddenIds,
      _hidden.toList(),
    );
    notifyListeners();
  }

  /// Persists [hidden]'s new state for every id in [ids] as one write and one
  /// notification — the order editor's per-category "show all" / "hide all"
  /// buttons use this so toggling several layers at once doesn't re-persist
  /// and rebuild once per layer. No-op when none of them change state.
  Future<void> setManyHidden(
    Iterable<String> ids, {
    required bool hidden,
  }) async {
    final next = Set.of(_hidden);
    var changed = false;
    for (final id in ids) {
      changed |= hidden ? next.add(id) : next.remove(id);
    }
    if (!changed) return;
    _hidden = next;
    await _settings.setStringList(
      SettingKeys.mapLayerHiddenIds,
      _hidden.toList(),
    );
    notifyListeners();
  }
}
