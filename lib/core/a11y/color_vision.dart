/// Recolouring the app for colour-vision deficiency.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

/// The kind of colour-vision deficiency to correct for.
enum ColorVision {
  /// Standard colours — every transform is the identity.
  none,

  /// Red-weak. ~1% of men.
  protan,

  /// Green-weak. The commonest, ~6% of men.
  deutan,

  /// Blue-yellow weak. Rare, and affects both sexes equally.
  tritan;

  /// The persisted token. [none] is stored as absence, so the default is a
  /// missing key rather than a magic string.
  String get token => name;

  static ColorVision fromToken(String? token) => switch (token) {
    'protan' => ColorVision.protan,
    'deutan' => ColorVision.deutan,
    'tritan' => ColorVision.tritan,
    _ => ColorVision.none,
  };
}

/// Daltonises colours so hues a deficient eye confuses are pushed apart.
///
/// **Correction, not simulation.** Simulating shows a typical eye what a
/// deficient one sees, which helps a designer and does nothing for the user.
/// This does the opposite: it works out what information the eye is losing and
/// redistributes it into channels that eye can still separate, so two colours
/// that would collapse into one stay distinguishable. Applied to the whole app —
/// including the seismic intensity scale, which the user has accepted will no
/// longer match CWA's published colours while this is on.
///
/// **Applied in linear RGB.** The Machado matrices are defined there, and every
/// sRGB value has to be un-gamma'd first. Doing it in gamma-encoded space —
/// which is what Flutter's own `ColorFilter.matrix` does — skews everything and
/// is worst in the darks, and this app's map is drawn on `#1f2025`.
///
/// **Applied at the definition, never at a converter.** The transform belongs
/// where a colour is declared, so a colour that reaches both the map (as a hex
/// string) and a legend (as a `Color`) is transformed exactly once and the two
/// still agree. Transforming inside the hex↔Color converters would double any
/// value that round-trips, and would miss every colour that never converts.
///
/// **What it cannot reach.** Server-rendered raster imagery — the radar
/// reflectivity echo and the satellite composite — arrives as finished PNG
/// tiles, and MapLibre's raster layer exposes no colour matrix. Those pixels
/// keep their original colours, so their legends must not be transformed either:
/// a key that disagrees with the picture is worse than one that is merely hard
/// to read. See [rasterExempt].
abstract final class ColorVisionFilter {
  /// Marks a colour as belonging to a server-rendered raster surface, whose
  /// pixels cannot be transformed — so its legend must not be either.
  ///
  /// Call this instead of [transform] at the definition of any colour that
  /// describes raster imagery (the radar dBZ scale, the satellite ramp). It is
  /// the identity, and it exists to say *why* out loud at the call site.
  static Color rasterExempt(Color color) => color;

  /// The same exemption for a hex string.
  static String rasterExemptHex(String hex) => hex;

  /// [color] recoloured for [vision].
  static Color transform(Color color, ColorVision vision) {
    if (vision == ColorVision.none) return color;
    final (r, g, b) = _daltonise(
      _toLinear(color.r),
      _toLinear(color.g),
      _toLinear(color.b),
      vision,
    );
    return Color.from(
      alpha: color.a,
      red: _toSrgb(r),
      green: _toSrgb(g),
      blue: _toSrgb(b),
    );
  }

  /// [hex] recoloured for [vision], preserving its exact input shape.
  ///
  /// Accepts what the MapLibre style already carries: `#rgb`, `#rrggbb`,
  /// `#rrggbbaa`, and `rgba(r, g, b, a)`. Anything else — an expression, a
  /// named colour, an interpolation — is returned untouched rather than
  /// mangled, because a broken paint value takes a whole layer off the map.
  static String transformHex(String hex, ColorVision vision) {
    if (vision == ColorVision.none) return hex;
    final rgba = _parseRgba(hex);
    if (rgba == null) return hex;
    final (r, g, b, a, wasFunctional) = rgba;
    final (tr, tg, tb) = _daltonise(
      _toLinear(r / 255),
      _toLinear(g / 255),
      _toLinear(b / 255),
      vision,
    );
    final rr = (_toSrgb(tr) * 255).round().clamp(0, 255);
    final gg = (_toSrgb(tg) * 255).round().clamp(0, 255);
    final bb = (_toSrgb(tb) * 255).round().clamp(0, 255);
    if (wasFunctional) {
      final alpha = a == 1.0 ? '1' : a.toStringAsFixed(3);
      return 'rgba($rr, $gg, $bb, $alpha)';
    }
    final hexBody =
        '#${rr.toRadixString(16).padLeft(2, '0')}'
        '${gg.toRadixString(16).padLeft(2, '0')}'
        '${bb.toRadixString(16).padLeft(2, '0')}';
    if (a == 1.0) return hexBody;
    final aa = (a * 255).round().clamp(0, 255);
    return '$hexBody${aa.toRadixString(16).padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------- internals

  /// Machado, Oliveira & Fernandes (2009), severity 1.0, linear RGB.
  static const Map<ColorVision, List<double>> _simulate = {
    ColorVision.protan: [
      0.152286, 1.052583, -0.204868, //
      0.114503, 0.786281, 0.099216, //
      -0.003882, -0.048116, 1.051998,
    ],
    ColorVision.deutan: [
      0.367322, 0.860646, -0.227968, //
      0.280085, 0.672501, 0.047413, //
      -0.011820, 0.042940, 0.968881,
    ],
    ColorVision.tritan: [
      1.255528, -0.076749, -0.178779, //
      -0.078411, 0.930809, 0.147602, //
      0.004733, 0.691367, 0.303900,
    ],
  };

  /// Simulate, take the error the eye loses, and fold it into the channels that
  /// eye still separates. Red/green losses move into green and blue; a blue
  /// loss moves into red and green.
  static (double, double, double) _daltonise(
    double r,
    double g,
    double b,
    ColorVision vision,
  ) {
    final m = _simulate[vision]!;
    final sr = m[0] * r + m[1] * g + m[2] * b;
    final sg = m[3] * r + m[4] * g + m[5] * b;
    final sb = m[6] * r + m[7] * g + m[8] * b;
    final er = r - sr, eg = g - sg, eb = b - sb;
    final double dr, dg, db;
    if (vision == ColorVision.tritan) {
      dr = er + 0.7 * eb;
      dg = eg + 0.7 * eb;
      db = 0;
    } else {
      dr = 0;
      dg = eg + 0.7 * er;
      db = eb + 0.7 * er;
    }
    return (
      (r + dr).clamp(0.0, 1.0),
      (g + dg).clamp(0.0, 1.0),
      (b + db).clamp(0.0, 1.0),
    );
  }

  static double _toLinear(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  static double _toSrgb(double c) => c <= 0.0031308
      ? c * 12.92
      : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;

  /// `(r, g, b, a, wasFunctional)` in 0–255 / 0–1, or null if unrecognised.
  static (int, int, int, double, bool)? _parseRgba(String value) {
    final text = value.trim();
    if (text.startsWith('#')) {
      final body = text.substring(1);
      int at(int i) => int.parse(body.substring(i, i + 2), radix: 16);
      try {
        return switch (body.length) {
          3 => (
            int.parse(body[0] * 2, radix: 16),
            int.parse(body[1] * 2, radix: 16),
            int.parse(body[2] * 2, radix: 16),
            1.0,
            false,
          ),
          6 => (at(0), at(2), at(4), 1.0, false),
          8 => (at(0), at(2), at(4), at(6) / 255, false),
          _ => null,
        };
      } on FormatException {
        return null;
      }
    }
    final match = RegExp(
      r'^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+)\s*)?\)$',
    ).firstMatch(text);
    if (match == null) return null;
    try {
      return (
        double.parse(match.group(1)!).round(),
        double.parse(match.group(2)!).round(),
        double.parse(match.group(3)!).round(),
        match.group(4) == null ? 1.0 : double.parse(match.group(4)!),
        true,
      );
    } on FormatException {
      return null;
    }
  }
}

/// The app-wide current [ColorVision], readable without a `BuildContext`.
///
/// The same shape as `AppTime`, and for the same reason: the colours that need
/// transforming are declared in map layers and paint tables that are not
/// widgets and never see a context, so a `Provider` cannot reach them. The
/// controller installs the value; everything else reads it.
///
/// Widgets should still rebuild when it changes — watch the controller for
/// that — but they read the value from here so a call site looks the same
/// wherever it lives.
abstract final class AppColorVision {
  static ColorVision _current = ColorVision.none;

  /// What the app is currently correcting for.
  static ColorVision get current => _current;

  /// Publishes [vision]. Called by the controller, and by tests.
  static void install(ColorVision vision) => _current = vision;
}

/// Terse access at a colour's definition: `const Color(0xFFD32F2F).vision`.
extension ColorVisionX on Color {
  /// This colour, corrected for the app's current colour-vision setting.
  Color get vision => ColorVisionFilter.transform(this, AppColorVision.current);
}

/// The same for a MapLibre paint string.
extension ColorVisionHexX on String {
  /// This hex/rgba paint value, corrected for the current setting. Anything
  /// that is not a colour passes through untouched.
  String get vision =>
      ColorVisionFilter.transformHex(this, AppColorVision.current);
}

/// A value that has to be rebuilt when the colour-vision setting moves.
///
/// Several map layers bake their marker PNGs once and keep them for the life of
/// the process. Those bitmaps have the corrected colours painted into them, so
/// a setting change leaves the map drawing yesterday's colours beside a legend
/// that already updated — the exact disagreement this whole feature is built to
/// avoid.
///
/// The cache remembers which setting it was built for rather than the setting
/// notifying every cache, so nothing has to keep a registry of them in step:
/// adding another baked asset cannot forget to register.
class VisionCache<T> {
  VisionCache(this._build);

  final T Function() _build;
  T? _value;
  ColorVision? _builtFor;

  /// The value, rebuilt if the setting has moved since it was made.
  T get value {
    final vision = AppColorVision.current;
    if (_builtFor != vision || _value == null) {
      _builtFor = vision;
      _value = _build();
    }
    return _value as T;
  }

  /// Whether a read would rebuild — for a caller that has to do the rebuild
  /// itself because it is asynchronous (an icon bake).
  bool get isStale => _builtFor != AppColorVision.current || _value == null;

  /// Drops the value so the next read rebuilds.
  void invalidate() => _builtFor = null;
}
