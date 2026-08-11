/// Weather glyphs from the bundled Material Symbols font that Flutter's
/// [Icons] class does not expose as named constants.
///
/// `rainy` (U+F07C2) / `rainy_light` (U+F07C4) / `rainy_heavy` (U+F07C3) were
/// added to Material Symbols v184 and ship inside Flutter's
/// `MaterialIcons-Regular.otf`, so referencing them by codepoint stays within
/// the "built-in icons only" rule — the glyphs are verified present in the
/// bundled font (the [Icons] class just doesn't name them).
library;

import 'package:flutter/material.dart';

/// Cloud with falling rain — the standard "raining" mark, for steady rain.
const IconData rainy = IconData(0xf07c2, fontFamily: 'MaterialIcons');

/// Light rain — a few scattered drops, for showers.
const IconData rainyLight = IconData(0xf07c4, fontFamily: 'MaterialIcons');

/// Heavy rain — dense falling drops, for downpour-scale phenomena.
const IconData rainyHeavy = IconData(0xf07c3, fontFamily: 'MaterialIcons');
