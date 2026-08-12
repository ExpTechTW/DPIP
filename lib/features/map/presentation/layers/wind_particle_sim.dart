/// Pure particle-advection math for the wind-forecast overlay — no Flutter
/// widgets, so every projection and step is unit-testable in isolation.
///
/// The numbers below are the web renderer's, ported rather than reinvented:
/// `satellite-tiles-go/web/index.html` carries a tuning panel whose sliders
/// were dragged until the flow looked right, and `DEFAULTS` is where those
/// values were written down. Anything tuned by eye cannot be re-derived, so the
/// only way for two renderers to agree is for one of them to copy.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:dpip/features/weather/domain/wind_field.dart';

/// Wind speed (m/s) that saturates the visual ramp — fixed across every frame
/// and both models so a streak means the same thing everywhere
/// (`web/wind.js`, `SPEED_SCALE`).
const double kWindSpeedScale = 32;

/// The zooms the tuned values are pinned at (`web/index.html`, `ZOOM_STOPS`),
/// which are also this layer's own limits.
const double _kZoomLo = 3;
const double _kZoomHi = 7;

// Each pair is (value at z3, value at z7). Which ones interpolate
// geometrically and which linearly is not a free choice either — it is what
// `TUNE` declares, and a count that steps 6400 → 4096 → 2601 is a visibly
// different field from one that steps 6400 → 5056 → 3712.
const (double, double) _kParticles = (6400, 1024); // log
const (double, double) _kPointSize = (1.5, 1.8); // lin, logical px
const (double, double) _kSpeedFactor = (0.2, 0.0151); // log
const (double, double) _kFadeOpacity = (0.95, 0.945); // lin

/// Chance per frame that a particle in good standing is recycled anyway.
const double _kDropRate = 0.011;

/// Relative density of particles in still air and in strong wind.
///
/// Strong by eleven to one, which is the opposite of what the same pair used
/// to say. See the note in `web/index.html`: once the colour underneath
/// carries the speed, thinning the streaks where the weather is spends the one
/// channel still describing direction.
const double _kDensityCalm = 0.5;
const double _kDensityStrong = 5.5;

/// Where a zoom sits between the two tuned stops.
///
/// Clamped rather than extrapolated, matching the web's `effective()`: outside
/// the stops there is no judgement behind the number, only arithmetic.
double _stopFraction(double zoom) =>
    ((zoom - _kZoomLo) / (_kZoomHi - _kZoomLo)).clamp(0.0, 1.0);

double _lerpStops((double, double) v, double zoom) {
  final f = _stopFraction(zoom);
  return v.$1 * (1 - f) + v.$2 * f;
}

double _logLerpStops((double, double) v, double zoom) {
  final f = _stopFraction(zoom);
  return math.exp(math.log(v.$1) * (1 - f) + math.log(v.$2) * f);
}

/// How many particles the field holds at [zoom].
///
/// Rounded to a square because the web renderer allocates a square texture of
/// particle state and rounds to one; matching the count matters more than the
/// squareness, but rounding the same way keeps the two exactly equal.
int particleCountFor(double zoom) {
  final edge = math.max(1, math.sqrt(_logLerpStops(_kParticles, zoom)).round());
  return edge * edge;
}

/// Diameter of a particle in logical pixels. The web sets `gl_PointSize` in
/// device pixels and multiplies by the device pixel ratio to get there, so the
/// tuned number is already the logical one.
double pointSizeFor(double zoom) => _lerpStops(_kPointSize, zoom);

/// What fraction of the trail buffer survives each frame.
///
/// This is the whole trail mechanism: nothing records where a particle has
/// been. Every frame the previous picture is redrawn at this opacity and the
/// current dots stamped on top, so a streak is the exponential decay of the
/// dots that came before — length falls out of the fade, and costs one draw
/// instead of one per remembered position.
///
/// Never 1: a fade that does not fade accumulates for ever and the screen
/// saturates to white.
double fadeOpacityFor(double zoom) => _lerpStops(_kFadeOpacity, zoom);

/// Field-space distance a particle rides per (m/s · frame) at [zoom].
///
/// It has to fall with zoom: a field-space step is a fraction of the *world*,
/// so the pixels it covers double with every zoom level in. Held constant at
/// the value that suits z3, particles at z7 move 23× too fast.
double fieldStepFor(double zoom) => 0.0001 * _logLerpStops(_kSpeedFactor, zoom);

/// The web's `densityWeight`: how many particles a place should hold relative
/// to spreading them evenly, by how hard the wind is blowing there.
double densityWeight(double speed) {
  final t = (speed / (0.6 * kWindSpeedScale)).clamp(0.0, 1.0);
  final s = t * t * (3 - 2 * t); // smoothstep
  return _kDensityCalm + (_kDensityStrong - _kDensityCalm) * s;
}

/// The camera a wind overlay is drawn under — enough to project a lat/lng to
/// screen pixels on a tilt-free, bearing-rotated Web Mercator view.
class WindCamera {
  const WindCamera({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.bearing,
  });

  final double centerLat;
  final double centerLng;
  final double zoom;

  /// Camera heading, degrees clockwise from north.
  final double bearing;

  @override
  bool operator ==(Object other) =>
      other is WindCamera &&
      other.centerLat == centerLat &&
      other.centerLng == centerLng &&
      other.zoom == zoom &&
      other.bearing == bearing;

  @override
  int get hashCode => Object.hash(centerLat, centerLng, zoom, bearing);
}

/// The rectangle of the world a [Size] screen shows, as a lat/lng span.
class WindViewport {
  const WindViewport({
    required this.westLng,
    required this.eastLng,
    required this.northLat,
    required this.southLat,
  });

  final double westLng;
  final double eastLng;
  final double northLat;
  final double southLat;
}

/// Web Mercator northing in `[0, 1]`, 0 at the north edge — the projection
/// every map in this app uses, kept identical to the web demo's `mercY`.
double mercatorY(double lat) {
  final phi = lat.clamp(-85.051129, 85.051129) * math.pi / 180;
  return (1 - math.log(math.tan(math.pi / 4 + phi / 2)) / math.pi) / 2;
}

/// Inverse of [mercatorY].
double mercatorLat(double y) =>
    (2 * math.atan(math.exp(math.pi * (1 - 2 * y))) - math.pi / 2) *
    180 /
    math.pi;

/// Project a geographic point into the map view. The camera's target sits at
/// the viewport centre and the view rotates clockwise with [WindCamera.bearing];
/// tilt is always zero in this app (the map disables it), so no perspective.
Offset projectLatLng(WindCamera cam, double lat, double lng, Size size) {
  final world = _worldSize(cam.zoom);
  final wx = (lng + 180) / 360 * world;
  final wy = mercatorY(lat) * world;
  final cx = (cam.centerLng + 180) / 360 * world;
  final cy = mercatorY(cam.centerLat) * world;
  // World x is cyclic, so fold the offset into the half-world nearest the
  // camera. Callers do not always hand over a longitude already inside
  // [-180, 180]: a particle's longitude is `lon0 + x · 360`, and ECMWF's grid
  // starts at 180, which puts every one of its particles in [180, 540). Taking
  // that difference literally throws them tens of thousands of pixels off
  // screen, where they are judged out of view and recycled before they can draw
  // anything. Folding also makes a point behind the antimeridian project onto
  // the near edge rather than across the whole world, which is what a map
  // centred at 121°E should do with 175°W.
  final dx = _wrapWorld(wx - cx, world);
  final dy = wy - cy;
  final r = cam.bearing * math.pi / 180;
  final cosR = math.cos(r);
  final sinR = math.sin(r);
  return Offset(
    size.width / 2 + dx * cosR - dy * sinR,
    size.height / 2 + dx * sinR + dy * cosR,
  );
}

/// The axis-aligned world rectangle a [Size] viewport shows under [cam] —
/// the bounds the simulation respawns particles into. Rotating the view makes
/// this a super-set of the visible area, which only wastes a few particles.
WindViewport viewportBounds(WindCamera cam, Size size) {
  final world = _worldSize(cam.zoom);
  final cx = (cam.centerLng + 180) / 360 * world;
  final cy = mercatorY(cam.centerLat) * world;
  final r = cam.bearing * math.pi / 180;
  final cosR = math.cos(r);
  final sinR = math.sin(r);
  var minX = double.infinity, maxX = -double.infinity;
  var minY = double.infinity, maxY = -double.infinity;
  // The four corners of the screen, un-rotated back into world space.
  for (final corner in const [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
    final dx = (corner.$1 - 0.5) * size.width;
    final dy = (corner.$2 - 0.5) * size.height;
    final wx = cx + dx * cosR + dy * sinR;
    final wy = cy - dx * sinR + dy * cosR;
    minX = math.min(minX, wx);
    maxX = math.max(maxX, wx);
    minY = math.min(minY, wy);
    maxY = math.max(maxY, wy);
  }
  return WindViewport(
    westLng: minX / world * 360 - 180,
    eastLng: maxX / world * 360 - 180,
    northLat: mercatorLat(minY / world),
    southLat: mercatorLat(maxY / world),
  );
}

double _worldSize(double zoom) => 512 * math.pow(2.0, zoom).toDouble();

/// Folds a world-space x offset into `(-world/2, world/2]`.
double _wrapWorld(double dx, double world) =>
    dx - world * (dx / world + 0.5).floorToDouble();

/// One particle: where it is in the field, how fast the air there is moving,
/// and where that puts it on screen.
///
/// Positions live in field space (x along the field's longitude span, y along
/// its latitude span) so advection is projection-free. Nothing remembers where
/// the particle has been — the streak behind it is the trail buffer's business,
/// not the particle's.
///
/// Screen position is two plain doubles plus a flag instead of a nullable
/// [Offset]: the simulation allocates nothing per particle per frame, and the
/// stamp pass has the coordinates it needs without unwrapping an object the
/// GC would have to collect.
class WindParticle {
  WindParticle(this.x, this.y);

  double x;
  double y;

  /// Speed of the air the particle last sampled, m/s — sets how bright its dot
  /// is stamped, so faster air reads as a brighter streak.
  double speed = 0;

  /// Screen x/y of the last step, valid only when [visible].
  double sx = 0;
  double sy = 0;

  /// Whether the last step landed the particle inside the viewport, where it
  /// has something to stamp.
  bool visible = false;
}

/// The animation state — a population advected through a [WindField].
class WindParticleSim {
  /// [count] is only the starting population: [step] resizes it to whatever
  /// the current zoom asks for, because the web renderer varies it from 6400
  /// at z3 down to 1024 at z7 and a fixed number matches neither end.
  WindParticleSim(this.field, {int count = 6400, math.Random? random})
    : _random = random ?? math.Random(),
      _mercY = _buildMercY(field),
      particles = [for (var i = 0; i < count; i++) WindParticle(0, 0)];

  final WindField field;
  final math.Random _random;
  final List<WindParticle> particles;

  /// Field-space y → mercator-y lookup, so the projection per particle per
  /// frame is two array reads instead of a `log` + `tan`.
  ///
  /// The web's GPU shader evaluates the projection per vertex for free; the
  /// CPU port would spend ~6000 transcendentals a frame on the same thing.
  /// The LUT is built over this field's own latitude span (y ∈ [0, 1]) with
  /// linear interpolation; its error stays under a pixel at any zoom this
  /// layer can show.
  final Float64List _mercY;

  static const int _mercYEntries = 1024;

  bool _seeded = false;

  /// Moves every particle one frame: sample the wind, step, work out where
  /// that lands on screen, and recycle the ones that have left.
  ///
  /// The view's projection is shared by the whole population, so its rotation
  /// and origin are computed here once and the loop inlines the same arithmetic
  /// [projectLatLng] does per point — six thousand `sin`/`cos` calls a frame
  /// become two.
  void step(WindCamera cam, Size size) {
    final vp = viewportBounds(cam, size);
    final fieldSpace = _fieldRect(vp);
    final fieldStep = fieldStepFor(cam.zoom);
    if (!_seeded) {
      _seedIn(fieldSpace);
      _seeded = true;
    }
    _resize(particleCountFor(cam.zoom), fieldSpace);

    final world = _worldSize(cam.zoom);
    final cx = (cam.centerLng + 180) / 360 * world;
    final cy = mercatorY(cam.centerLat) * world;
    final r = cam.bearing * math.pi / 180;
    final cosR = math.cos(r);
    final sinR = math.sin(r);
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final latScale = field.dLat * field.height;
    // `lon0 + x·360` folds into a per-frame constant plus one multiply.
    final xOffset = (field.lon0 + 180) / 360 * world;
    final mercY = _mercY;
    const degToRad = math.pi / 180;

    for (final p in particles) {
      final (u, v) = _sampleUV(p.x, p.y);
      p.speed = math.sqrt(u * u + v * v);
      final lat = field.lat0 + p.y * latScale;
      p.x = (p.x + u / math.cos(lat * degToRad) * fieldStep) % 1.0;
      p.y -= v * fieldStep;

      // Off the grid is nothing to stamp: mark it invisible and recycle
      // without paying for a projection nobody will see.
      if (p.y < 0 || p.y > 1) {
        p.visible = false;
        _respawn(p, fieldSpace);
        continue;
      }

      final dx = _wrapWorld(xOffset + p.x * world - cx, world);
      final dy = _mercYAt(mercY, p.y) * world - cy;
      p.sx = halfWidth + dx * cosR - dy * sinR;
      p.sy = halfHeight + dx * sinR + dy * cosR;
      final inView =
          p.sx >= -0.1 * size.width &&
          p.sx <= 1.1 * size.width &&
          p.sy >= -0.1 * size.height &&
          p.sy <= 1.1 * size.height;
      p.visible = inView;

      // Recycle a particle that has left, and occasionally a healthy one — the
      // field would otherwise empty out of wherever the density weighting is
      // not putting anything back.
      if (!inView || _random.nextDouble() < _kDropRate) {
        _respawn(p, fieldSpace);
      }
    }
  }

  /// Grows or shrinks the population to [count], seeding anything new into the
  /// current view so a zoom does not open a hole in the field.
  void _resize(int count, _FieldRect r) {
    if (!_seeded || count == particles.length) return;
    if (count < particles.length) {
      particles.removeRange(count, particles.length);
      return;
    }
    while (particles.length < count) {
      particles.add(
        WindParticle(
          _lerpX(r, _random.nextDouble()),
          _lerp(r.y0, r.y1, _random.nextDouble()),
        ),
      );
    }
  }

  static Float64List _buildMercY(WindField field) {
    final lut = Float64List(_mercYEntries);
    final latScale = field.dLat * field.height;
    for (var i = 0; i < _mercYEntries; i++) {
      lut[i] = mercatorY(field.lat0 + i / (_mercYEntries - 1) * latScale);
    }
    return lut;
  }

  /// Linear interpolation into [_buildMercY]'s table at field-space [y].
  static double _mercYAt(Float64List lut, double y) {
    final t = y * (_mercYEntries - 1);
    final i = math.min(_mercYEntries - 2, t.floor());
    final f = t - i;
    return lut[i] + (lut[i + 1] - lut[i]) * f;
  }

  /// The viewport's rectangle in field space (fractions of the field's
  /// longitude / latitude span), for seeding and respawning.
  _FieldRect _fieldRect(WindViewport vp) {
    final latSpan = field.dLat * field.height;
    final x0 = ((vp.westLng - field.lon0) / 360) % 1.0;
    var x1 = ((vp.eastLng - field.lon0) / 360) % 1.0;
    // Wrapping the two edges independently is what turns a viewport straddling
    // the grid's seam into its own complement — west 0.98, east 0.02 describes
    // the 96% of the world the viewer cannot see. Carrying the east edge past
    // the seam keeps the interval the one that was meant; [_lerpX] folds the
    // result back afterwards. ECMWF's seam is the antimeridian, so this is the
    // difference between working and not for anyone looking at the Pacific.
    if (x1 < x0) x1 += 1.0;
    return _FieldRect(
      x0: x0,
      x1: x1,
      y0: (vp.northLat - field.lat0) / latSpan,
      y1: (vp.southLat - field.lat0) / latSpan,
    );
  }

  /// A point drawn from a longitude interval that may reach past the seam,
  /// folded back into the field's own `[0, 1)`.
  double _lerpX(_FieldRect r, double t) => _lerp(r.x0, r.x1, t) % 1.0;

  void _seedIn(_FieldRect r) {
    for (final p in particles) {
      p.x = _lerpX(r, _random.nextDouble());
      p.y = _lerp(r.y0, r.y1, _random.nextDouble());
    }
  }

  /// Rejection sampling by wind speed, weighted by [densityWeight].
  ///
  /// One candidate, accepted with probability proportional to its weight, and
  /// on rejection the particle simply stays where it is and tries again next
  /// frame. Not best-of-N: when every candidate lands in calm air, best-of-N
  /// returns calm whatever the weights say, which caps the reachable contrast
  /// near three to one — nowhere near the eleven asked for here. Rejection has
  /// no such ceiling, because the equilibrium density *is* the acceptance
  /// probability: inflow to a region is its area times that probability, and
  /// the lifetime is the same everywhere.
  ///
  /// A particle that had already left the view just stays invisible a few more
  /// frames, which at sixty a second is nothing.
  void _respawn(WindParticle p, _FieldRect r) {
    final x = _lerpX(r, _random.nextDouble());
    final y = _lerp(r.y0, r.y1, _random.nextDouble());
    final (u, v) = _sampleUV(x, y);
    final weight = densityWeight(math.sqrt(u * u + v * v));
    if (_random.nextDouble() <
        weight / math.max(_kDensityCalm, _kDensityStrong)) {
      p.x = x;
      p.y = y;
    }
  }

  /// Bilinear sample of both wind components at field-space [x], [y] in one
  /// pass — the four-cell geometry (which cells, how much of each) is shared by
  /// u and v, so two separate lookups would redo every floor, wrap, and lerp
  /// once per component. This is the hand-rolled texture sample the web shader
  /// does (`lookup_wind`), reading the two quantised planes directly.
  (double, double) _sampleUV(double x, double y) {
    final fx = x * field.width;
    final fy = y * field.height;
    // Columns wrap — the grid's last column neighbours its first, and clamping
    // there flattens the wind along the whole seam. Rows do not: there is no
    // cell north of the north pole.
    final i0 = fx.floor() % field.width;
    final i1 = (i0 + 1) % field.width;
    var j0 = fy.floor();
    if (j0 < 0) j0 = 0;
    if (j0 >= field.height) j0 = field.height - 1;
    final j1 = j0 + 1 < field.height ? j0 + 1 : j0;
    final tx = fx - fx.floorToDouble();
    final ty = (fy - j0).clamp(0.0, 1.0);
    final row0 = j0 * field.width;
    final row1 = j1 * field.width;
    return (
      _lerpPlane(field.u, row0, row1, i0, i1, tx, ty, field.uMin, field.uMax),
      _lerpPlane(field.v, row0, row1, i0, i1, tx, ty, field.vMin, field.vMax),
    );
  }

  /// One plane's bilinear interpolation over the shared cell geometry.
  double _lerpPlane(
    Uint8List plane,
    int row0,
    int row1,
    int i0,
    int i1,
    double tx,
    double ty,
    double lo,
    double hi,
  ) {
    final a = plane[row0 + i0];
    final b = plane[row0 + i1];
    final c = plane[row1 + i0];
    final d = plane[row1 + i1];
    final top = a + (b - a) * tx;
    final bottom = c + (d - c) * tx;
    return lo + (top + (bottom - top) * ty) / 255 * (hi - lo);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _FieldRect {
  const _FieldRect({
    required this.x0,
    required this.x1,
    required this.y0,
    required this.y1,
  });

  final double x0;
  final double x1;
  final double y0;
  final double y1;
}
