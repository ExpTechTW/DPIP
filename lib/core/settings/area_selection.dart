import 'package:flutter/foundation.dart';

/// The user's currently-selected geographic area (地區), swiped between in the
/// region bar on Home and Events.
///
/// A placeholder for now — [count] stand-in areas until real saved locations
/// land (the location feature isn't ported yet). Only the selected index is
/// state; the region bar renders the labels. Distinct from `RegionSelection`,
/// which picks the API server region, not a user location.
class AreaSelection extends ChangeNotifier {
  AreaSelection({this.count = 3});

  /// Number of areas available to switch between.
  final int count;

  int _selectedIndex = 0;

  /// Index of the active area, `0`–`count - 1`.
  int get selectedIndex => _selectedIndex;

  /// Selects the area at [index]; ignored if out of range or unchanged.
  void select(int index) {
    if (index < 0 || index >= count || index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }

  /// Moves to the next area (no-op at the end) — swipe left.
  void next() => select(_selectedIndex + 1);

  /// Moves to the previous area (no-op at the start) — swipe right.
  void previous() => select(_selectedIndex - 1);
}
