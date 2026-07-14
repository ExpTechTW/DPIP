import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's Home regions — nationwide, the current GPS township, and up to
/// [maxSaved] saved townships — plus which one is selected for the Home display.
///
/// **Codes only.** Saved regions persist as a list of township **codes**; the
/// current GPS location is a code set each session from the location service and
/// is *not* persisted. Display names are derived from the town directory by code
/// in the presentation layer, never stored here. Only the selection affects Home
/// (switched via the region bar / swipe); every launch defaults to 所在地.
///
/// Replaces the placeholder `AreaSelection`.
class RegionStore extends ChangeNotifier {
  RegionStore(this._prefs)
    : _saved =
          _prefs.getStringList(PreferenceKeys.savedRegionCodes) ?? const [];

  final SharedPreferences _prefs;

  /// Maximum saved townships (besides nationwide + current location).
  static const int maxSaved = 3;

  List<String> _saved;
  String? _currentCode;

  /// Default selection is 所在地 (index 1: after 全國).
  int _selectedIndex = 1;

  /// Saved township codes, in order (unmodifiable).
  List<String> get savedCodes => List.unmodifiable(_saved);

  /// The current GPS township code, or null when unavailable.
  String? get currentCode => _currentCode;

  /// The ordered areas: 全國, 所在地, then each saved township.
  List<HomeArea> get areas => [
    const NationwideArea(),
    CurrentArea(_currentCode),
    for (final code in _saved) SavedArea(code),
  ];

  /// Number of areas (drop-in for the region bar/pager).
  int get count => areas.length;

  /// The selected area index, always in range.
  int get selectedIndex => _selectedIndex.clamp(0, count - 1);

  /// The selected area.
  HomeArea get selected => areas[selectedIndex];

  /// Selects the area at [index]; ignored if unchanged / out of range.
  void select(int index) {
    final clamped = index.clamp(0, count - 1);
    if (clamped == _selectedIndex) return;
    _selectedIndex = clamped;
    notifyListeners();
  }

  /// Next area (no-op at the end) — swipe left.
  void next() => select(selectedIndex + 1);

  /// Previous area (no-op at the start) — swipe right.
  void previous() => select(selectedIndex - 1);

  /// Sets the current GPS township [code] (null when unavailable); not persisted.
  void setCurrentCode(String? code) {
    if (code == _currentCode) return;
    _currentCode = code;
    notifyListeners();
  }

  /// Whether [code] can be saved (not already saved, under the cap).
  bool canSave(String code) =>
      !_saved.contains(code) && _saved.length < maxSaved;

  /// Adds a saved township; returns false if duplicate or at the cap.
  bool addSaved(String code) {
    if (!canSave(code)) return false;
    _saved = [..._saved, code];
    _persist();
    notifyListeners();
    return true;
  }

  /// Removes a saved township (no-op if absent). Preserves which area stays
  /// selected: removing an area *before* the selected one shifts the selection
  /// down with it (so the same region stays active, not its neighbour). Removing
  /// the selected area itself, or one after it, leaves the index (then clamped).
  void removeSaved(String code) {
    final position = _saved.indexOf(code);
    if (position < 0) return;
    // Saved areas start at index 2 (after 全國, 所在地).
    final removedIndex = 2 + position;
    _saved = [
      for (final c in _saved)
        if (c != code) c,
    ];
    _persist();
    if (removedIndex < _selectedIndex) _selectedIndex -= 1;
    _selectedIndex = _selectedIndex.clamp(0, count - 1);
    notifyListeners();
  }

  void _persist() =>
      _prefs.setStringList(PreferenceKeys.savedRegionCodes, _saved);
}
