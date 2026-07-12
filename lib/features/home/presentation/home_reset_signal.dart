import 'package:flutter/foundation.dart';

/// A one-shot signal that asks the home page to reset its sheet to rest.
///
/// The home tab lives in a persistent [IndexedStack] branch, so its sheet keeps
/// whatever position it was dragged to. Firing this when the home tab is
/// re-selected snaps the sheet back to its resting detent.
class HomeResetSignal extends ChangeNotifier {
  /// Requests a reset. The home page listens and returns its sheet to rest.
  void fire() => notifyListeners();
}
