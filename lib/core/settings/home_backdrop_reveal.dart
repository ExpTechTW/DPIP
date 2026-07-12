import 'package:flutter/foundation.dart';

/// How much the home weather backdrop is revealed (0 = collapsed sheet, map/
/// surface showing; 1 = sheet full, weather filling the screen).
///
/// App-wide so the chrome that sits over it — the region bar and the bottom nav
/// — can go transparent and flip their text/icons to contrast as the weather
/// takes over, instead of leaving opaque light strips. The home sheet drives it;
/// it is 0 on every other tab.
class HomeBackdropReveal extends ValueNotifier<double> {
  HomeBackdropReveal() : super(0);
}
