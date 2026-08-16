import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

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
  RegionStore(this._settings)
    : _saved =
          _settings.getStringList(SettingKeys.savedRegionCodes) ?? const [];

  final SettingsStore _settings;

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

  /// 替換一個已保存的區域
  /// 當 [oldCode] 不存在 [newCode] 已經被保存或者已保存的區域達到最大數量時返回 false。
  /// 替換成功後返回 true。
  bool replaceSaved(String oldCode, String newCode) {
    final position = _saved.indexOf(oldCode);
    if (position < 0) return false;
    if (oldCode == newCode) return true;
    if (_saved.contains(newCode)) return false;
    final list = [..._saved];
    list[position] = newCode;
    _saved = list;
    _persist();
    notifyListeners();
    return true;
  }

  /// Moves the saved township from [oldIndex] to [newIndex] — the post-removal
  /// index, per `ReorderableListView.onReorderItem`. Keeps the same area selected
  /// by re-pointing the selection at its township's new slot.
  void reorderSaved(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _saved.length) return;
    final target = newIndex.clamp(0, _saved.length - 1);
    if (target == oldIndex) return;

    final selectedCode = switch (selected) {
      SavedArea(:final code) => code,
      _ => null,
    };
    final list = [..._saved];
    list.insert(target, list.removeAt(oldIndex));
    _saved = list;
    _persist();
    // Saved areas start at index 2 (after 全國, 所在地); keep the same one active.
    if (selectedCode != null) {
      final position = _saved.indexOf(selectedCode);
      if (position >= 0) _selectedIndex = 2 + position;
    }
    notifyListeners();
  }

  void _persist() =>
      _settings.setStringList(SettingKeys.savedRegionCodes, _saved);
}
