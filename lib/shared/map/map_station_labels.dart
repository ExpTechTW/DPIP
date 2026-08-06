/// Placement for two-line station labels (name over reading).
///
/// The label text itself is the plain `"名稱\n數值"` string the layers have
/// always built; what this fixes is **where it goes**:
///
/// * `text-anchor: top` + `text-offset` pin the label under its own dot. The
///   previous `text-variable-anchor` let each label hop between top/bottom/
///   left/right as the camera moved, and `text-justify: auto` flipped the
///   alignment with it.
/// * Collision stays **on**. Legacy disabled it (`text-allow-overlap: true`),
///   which at Taiwan's station density buries labels under their neighbours'
///   labels and dots — the fixed placement is what legacy actually bought, not
///   the overlap.
///
/// One symbol layer, one fontstack: the two lines are placed and dropped as a
/// unit, and there is no `format` expression to mis-lay-out. Offsets are in
/// **ems** (MapLibre `text-offset` units), so the gap tracks the text size.
library;

import 'package:maplibre_gl/maplibre_gl.dart';

/// Distance from the dot to the top of the label block, in ems.
const double stationLabelOffsetEm = 1.0;

/// The one fontstack station labels are set in.
///
/// It must be a stack the glyph CDN actually serves: MapLibre's default is
/// `Open Sans Regular,Arial Unicode MS Regular`, which 404s there and makes
/// gl-native drop the whole layer rather than just the text.
const String stationLabelFont = 'Noto Sans TC Regular';

/// A station's `"name\nreading"` label, pinned under its dot.
///
/// [textField] is the MapLibre expression for the whole two-line string.
SymbolLayerProperties stationLabelProps({
  required List<Object> textField,
  double textSize = 11,
  String textColor = '#FFFFFF',
  String haloColor = '#000000',
  double haloWidth = 1.2,
  double? opacity,
  List<Object>? sortKey,
}) => SymbolLayerProperties(
  textField: textField,
  textFont: const <String>[stationLabelFont],
  textSize: textSize,
  textColor: textColor,
  textHaloColor: haloColor,
  textHaloWidth: haloWidth,
  // CJK ideographs occupy a taller, lower ink band than Latin digits (measured
  // from the glyph PBFs: 臺 is 21 px tall at a 24 px em vs 18 px for a digit,
  // and sits 5 px lower). MapLibre's 1.2 default — and the 1.1 this used to
  // carry — lets a CJK line's descent crowd the reading underneath it.
  textLineHeight: 1.35,
  textAnchor: 'top',
  textOffset: const <double>[0, stationLabelOffsetEm],
  textAllowOverlap: false,
  textIgnorePlacement: false,
  // A little breathing room so two surviving labels never touch.
  textPadding: 4,
  textOpacity: opacity,
  symbolSortKey: sortKey,
);
