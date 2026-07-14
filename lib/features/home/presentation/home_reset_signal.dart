import 'package:flutter/foundation.dart';

/// A one-shot signal fired when the home tab is re-selected.
///
/// The home tab lives in a persistent [IndexedStack] branch, so its state
/// survives navigating away. Firing this on re-selection lets the page refresh
/// what would otherwise go stale: the sheet snaps back to its resting detent,
/// and the map backdrop re-captures with the latest radar frame.
class HomeResetSignal extends ChangeNotifier {
  /// Requests a reset. Listeners restore the sheet and refresh the map.
  void fire() => notifyListeners();
}
