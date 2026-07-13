import 'package:flutter/foundation.dart';

/// The live extent of the active Home sheet, `0` (collapsed) → `1` (full).
///
/// App-wide because the chrome layered over the Home backdrop choreographs
/// itself off the sheet's height: as the sheet climbs, the bottom nav slides
/// away first, then the region bar dismisses once the rising sheet invades it,
/// leaving the weather backdrop unobstructed. The Home sheet publishes its
/// extent here while it is the active area; every other tab reads it too but
/// forces its chrome shown.
///
/// Seeded to [rest] — the sheet's initial detent — so its frosted panel is
/// styled correctly from the very first frame. A `DraggableScrollableSheet` only
/// emits an extent notification when its size *changes*, so without this seed the
/// value would sit at 0 (transparent, unblurred panel) until the first drag.
///
/// This holds only the raw extent — consumers derive their own factor from it
/// via `HomeChrome`, so the choreography thresholds live in exactly one place.
class HomeSheetExtent extends ValueNotifier<double> {
  HomeSheetExtent() : super(rest);

  /// Resting detent — the sheet covers the bottom third of the screen. Also its
  /// floor: the sheet can't be dragged any smaller.
  static const double rest = 1 / 3;

  /// Fully expanded — the sheet covers the whole screen.
  static const double max = 1.0;
}
