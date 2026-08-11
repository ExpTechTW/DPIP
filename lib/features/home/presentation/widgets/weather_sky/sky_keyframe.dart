import 'dart:math' as math;

/// One keyframe of the reference scene: the atmosphere, the light rig and
/// the fog/cloud colours at a single point in the day.
///
/// The reference engine does not simulate a sun. Its sky is a lookup table indexed
/// by `(sunAngleY, view elevation)`, and [sunAngleY] is authored per keyframe
/// — it is literally the u coordinate into that table, not an elevation angle.
/// Time of day is therefore a walk along a ring of keyframes (17 for clear and
/// cloudy, 4 for everything else), not an ephemeris.
///
/// Values here are already scaled to the units the shaders consume.
class SkyKeyframe {
  /// Keyframe index within its weather's ring.
  final double time;

  /// Sky-LUT u coordinate. Roughly 0.01 (night) … 0.57 (noon).
  final double sunAngleY;

  /// Camera yaw in degrees, which sets the frustum's elevation span.
  final double cameraYaw;

  /// Sun radiance multiplier, 3 … 23.
  final double sunIntensity;

  /// Ozone layer half-thickness (metres).
  final double ozoneThickness;

  /// Tonemap coefficients `(a, b, c, d, e)` applied inside the LUT bake.
  final (double, double, double, double, double) postColor;

  /// The medium, as `(dry, wet)` ramps lerped by relative humidity.
  ///
  /// There is no un-ramped form of any of these: [resolveKeyframe] always
  /// takes the humidity lerp, so a scalar alongside each pair would be read by
  /// nothing.
  final (double, double) humidRayleighHeight;
  final (double, double) humidMieScatter;
  final (double, double) humidMieAbsorb;
  final (double, double) humidMieHeight;
  final (double, double) humidMieAsymmetry;

  const SkyKeyframe({
    required this.time,
    required this.sunAngleY,
    required this.cameraYaw,
    required this.sunIntensity,
    required this.ozoneThickness,
    required this.postColor,
    required this.humidRayleighHeight,
    required this.humidMieScatter,
    required this.humidMieAbsorb,
    required this.humidMieHeight,
    required this.humidMieAsymmetry,
  });
}

/// The medium's fixed constants: the standard Earth atmosphere from Hillaire,
/// "A Scalable and Production Ready Sky and Atmosphere Rendering Technique"
/// (EGSR 2020), which is what everything from Bruneton onward uses.
///
/// Distances are metres and coefficients 1/metre.
abstract final class SkyConstants {
  SkyConstants._();

  /// Rayleigh scattering coefficient (1/m).
  static const (double, double, double) rayleighScatter = (
    5.802e-6,
    1.3558e-5,
    3.31e-5,
  );

  /// Ozone absorption coefficient (1/m).
  static const (double, double, double) ozoneAbsorb = (
    6.5e-7,
    1.881e-6,
    8.5e-8,
  );

  /// Ozone layer centre altitude (m).
  static const double ozoneCentre = 25000;

  /// Planet radius (m).
  static const double planetRadius = 6360000;

  /// Atmosphere outer radius (m).
  static const double atmosphereRadius = 6460000;

  /// Viewer altitude (m).
  static const double eyeAltitude = 739.98;

  /// Ray-march sample count in the sky-LUT bake.
  static const int marchStepCount = 30;

  /// Transmittance LUT size.
  static const int transmittanceWidth = 256;
  static const int transmittanceHeight = 256;

  /// Sky-view LUT size. 141 rows = 128 above the horizon plus 13 below.
  static const int skyLutWidth = 256;
  static const int skyLutHeight = 141;
}

/// A keyframe resolved for a moment in time: the two neighbouring keyframes
/// blended, then the humidity ramps applied.
class ResolvedSky {
  final double sunAngleY;
  final double cameraYaw;
  final double sunIntensity;
  final double rayleighHeight;
  final double mieScatter;
  final double mieAbsorb;
  final double mieHeight;
  final double mieAsymmetry;
  final double ozoneThickness;
  final (double, double, double, double, double) postColor;

  const ResolvedSky({
    required this.sunAngleY,
    required this.cameraYaw,
    required this.sunIntensity,
    required this.rayleighHeight,
    required this.mieScatter,
    required this.mieAbsorb,
    required this.mieHeight,
    required this.mieAsymmetry,
    required this.ozoneThickness,
    required this.postColor,
  });

  /// Whether re-baking the LUTs is needed to move from this to [other].
  ///
  /// Only the values the bake actually reads are compared — the fog and cloud
  /// colours feed other layers and must not trigger a bake on their own.
  bool needsRebake(ResolvedSky other) =>
      sunAngleY != other.sunAngleY ||
      cameraYaw != other.cameraYaw ||
      sunIntensity != other.sunIntensity ||
      rayleighHeight != other.rayleighHeight ||
      mieScatter != other.mieScatter ||
      mieAbsorb != other.mieAbsorb ||
      mieHeight != other.mieHeight ||
      mieAsymmetry != other.mieAsymmetry ||
      ozoneThickness != other.ozoneThickness ||
      postColor != other.postColor;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Interpolates [frames] at ring position [position] and applies [humidity].
///
/// [position] is in keyframe units (0 … frames.length), and wraps — the ring
/// closes from the last keyframe back to the first, which is what carries the
/// scene through midnight without a seam.
ResolvedSky resolveSky(
  List<SkyKeyframe> frames, {
  required double position,
  required double humidity,
}) {
  assert(frames.isNotEmpty, 'a weather type must have keyframes');

  final n = frames.length;
  final wrapped = position % n;
  final i0 = wrapped.floor() % n;
  final i1 = (i0 + 1) % n;
  final t = wrapped - wrapped.floorToDouble();

  final a = frames[i0];
  final b = frames[i1];
  final h = humidity.clamp(0.0, 1.0);

  /// Blends a humidity ramp across both keyframes, then across humidity.
  double humid((double, double) ra, (double, double) rb) =>
      _lerp(_lerp(ra.$1, ra.$2, h), _lerp(rb.$1, rb.$2, h), t);

  return ResolvedSky(
    sunAngleY: _lerp(a.sunAngleY, b.sunAngleY, t),
    cameraYaw: _lerp(a.cameraYaw, b.cameraYaw, t),
    sunIntensity: _lerp(a.sunIntensity, b.sunIntensity, t),
    // The humidity ramps override the base atmosphere values wherever the
    // keyframe supplies one — that is the engine's own precedence.
    rayleighHeight: humid(a.humidRayleighHeight, b.humidRayleighHeight),
    mieScatter: humid(a.humidMieScatter, b.humidMieScatter),
    mieAbsorb: humid(a.humidMieAbsorb, b.humidMieAbsorb),
    mieHeight: humid(a.humidMieHeight, b.humidMieHeight),
    mieAsymmetry: humid(a.humidMieAsymmetry, b.humidMieAsymmetry),
    ozoneThickness: _lerp(a.ozoneThickness, b.ozoneThickness, t),
    postColor: (
      _lerp(a.postColor.$1, b.postColor.$1, t),
      _lerp(a.postColor.$2, b.postColor.$2, t),
      _lerp(a.postColor.$3, b.postColor.$3, t),
      _lerp(a.postColor.$4, b.postColor.$4, t),
      _lerp(a.postColor.$5, b.postColor.$5, t),
    ),
  );
}

/// Maps a wall-clock hour to a position on a keyframe ring of [frameCount].
///
/// The ring is authored as an even split of the day with keyframe 0 at
/// midnight: the 17-frame tables peak at keyframe 8 (`sunAngleY` 0.02 → 0.50 →
/// 0.01), i.e. 11.3 h, solar noon. Sunrise therefore lands near keyframe 4 and
/// sunset near keyframe 13.
///
/// Rather than assume those hours, the day and night segments are *stretched*
/// between the real [sunrise] and [sunset]. An even split would peg dawn to a
/// fixed 5.6 h year-round, which is over an hour out in a Taiwanese winter
/// (sunrise 06:35 in December against 05:05 in June).
///
/// Anchoring must map sunrise to the **dawn keyframe**, not to keyframe 0 —
/// keyframe 0 is midnight, and mapping sunrise there renders a night sky at
/// 06:00.
///
/// [hour], [sunrise] and [sunset] are local decimal hours.
double keyframePosition(
  double hour, {
  required int frameCount,
  double sunrise = 5.6,
  double sunset = 18.4,
}) {
  final n = frameCount.toDouble();
  // Where dawn and dusk sit on an evenly-split ring.
  final dawnKey = n * 5.6 / 24.0;
  final duskKey = n * 18.4 / 24.0;

  final wrapped = hour % 24.0;
  final h = wrapped < 0 ? wrapped + 24.0 : wrapped;

  if (h >= sunrise && h < sunset) {
    final t = (h - sunrise) / math.max(sunset - sunrise, 1e-6);
    return dawnKey + t * (duskKey - dawnKey);
  }

  // Night: from dusk, through midnight, back around to dawn.
  final nightHours = 24.0 - (sunset - sunrise);
  final since = h >= sunset ? h - sunset : h + 24.0 - sunset;
  final t = since / math.max(nightHours, 1e-6);
  return (duskKey + t * (n - duskKey + dawnKey)) % n;
}
