/// Hermite interpolation between [a] and [b] — GLSL's `smoothstep`.
double smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

/// One cloud sprite placed in the scene.
///
/// The reference positions clouds in true 3D — each carries a world x/y/z and
/// a scale, with the camera advancing along -z. A Flutter fragment shader has
/// no geometry stage, so instances are placed in screen-relative terms instead
/// and [depth] stands in for z: it scales the
/// sprite, dims it, and sets how fast it drifts. That reproduces the parallax
/// the 3D layout exists to create without needing the projection.
class CloudInstance {
  /// Index into the loaded sprite set.
  final int sprite;

  /// Horizontal position, in screen widths. Wraps, so the deck is endless.
  final double x;

  /// Vertical position, 0 at the top of the widget to 1 at the bottom.
  final double y;

  /// Width as a fraction of the widget's width, before [depth] scaling.
  final double scale;

  /// 0 near … 1 far. Near clouds are larger, brighter and drift faster.
  final double depth;

  /// Per-instance opacity.
  final double opacity;

  const CloudInstance({
    required this.sprite,
    required this.x,
    required this.y,
    required this.scale,
    required this.depth,
    this.opacity = 1.0,
  });
}

/// A named arrangement of clouds, mirroring the reference's `skies[]` entries.
class CloudLayout {
  final List<CloudInstance> clouds;

  /// Horizontal drift, in screen widths per second at [CloudInstance.depth]
  /// zero. The reference's `cloudSpeed` values are 30 (snow) … 100 (rain); these are
  /// the same ordering scaled to screen units.
  final double speed;

  const CloudLayout({required this.clouds, required this.speed});

  /// Scattered fair-weather cumulus — a few small puffs high up.
  static const CloudLayout fair = CloudLayout(
    speed: 0.010,
    clouds: [
      CloudInstance(
        sprite: 0,
        x: 0.10,
        y: 0.30,
        scale: 0.52,
        depth: 0.75,
        opacity: 0.85,
      ),
      CloudInstance(
        sprite: 2,
        x: 0.62,
        y: 0.22,
        scale: 0.44,
        depth: 0.85,
        opacity: 0.70,
      ),
      CloudInstance(
        sprite: 4,
        x: 1.15,
        y: 0.36,
        scale: 0.60,
        depth: 0.65,
        opacity: 0.80,
      ),
    ],
  );

  /// Broken cumulus — the default "some cloud about" sky.
  static const CloudLayout scattered = CloudLayout(
    speed: 0.012,
    clouds: [
      CloudInstance(sprite: 0, x: 0.05, y: 0.34, scale: 0.72, depth: 0.45),
      CloudInstance(
        sprite: 1,
        x: 0.55,
        y: 0.22,
        scale: 0.58,
        depth: 0.70,
        opacity: 0.85,
      ),
      CloudInstance(sprite: 3, x: 1.00, y: 0.40, scale: 0.86, depth: 0.30),
      CloudInstance(
        sprite: 2,
        x: 1.55,
        y: 0.26,
        scale: 0.50,
        depth: 0.80,
        opacity: 0.75,
      ),
      CloudInstance(
        sprite: 4,
        x: 0.85,
        y: 0.52,
        scale: 0.64,
        depth: 0.55,
        opacity: 0.9,
      ),
    ],
  );

  /// Overcast — a stacked, overlapping deck that fills the frame.
  static const CloudLayout overcast = CloudLayout(
    speed: 0.008,
    clouds: [
      CloudInstance(sprite: 8, x: 0.00, y: 0.30, scale: 1.30, depth: 0.55),
      CloudInstance(sprite: 9, x: 0.75, y: 0.20, scale: 1.25, depth: 0.65),
      CloudInstance(sprite: 10, x: 1.45, y: 0.34, scale: 1.35, depth: 0.45),
      CloudInstance(sprite: 3, x: 0.35, y: 0.46, scale: 1.00, depth: 0.30),
      CloudInstance(sprite: 0, x: 1.10, y: 0.50, scale: 0.95, depth: 0.25),
    ],
  );

  /// Rain deck — heavy nimbostratus, low and fast.
  static const CloudLayout rain = CloudLayout(
    speed: 0.030,
    clouds: [
      CloudInstance(sprite: 8, x: 0.00, y: 0.26, scale: 1.45, depth: 0.60),
      CloudInstance(sprite: 10, x: 0.70, y: 0.16, scale: 1.40, depth: 0.70),
      CloudInstance(sprite: 9, x: 1.40, y: 0.30, scale: 1.50, depth: 0.50),
      CloudInstance(sprite: 11, x: 0.40, y: 0.44, scale: 1.20, depth: 0.28),
      CloudInstance(sprite: 3, x: 1.15, y: 0.48, scale: 1.10, depth: 0.20),
    ],
  );
}

/// Where and how big a cloud instance lands on screen this frame.
typedef PlacedCloud = ({
  double left,
  double top,
  double width,
  double height,
  double opacity,
  double depth,
  int sprite,
});

/// Lays out [layout] for a widget of [size], drifted by [time] seconds.
///
/// Instances are returned far-to-near so a painter can draw them in order and
/// get correct overlap without a depth buffer. Horizontal positions wrap over
/// a span wider than the screen, so clouds enter and leave continuously.
List<PlacedCloud> placeClouds(
  CloudLayout layout, {
  required double width,
  required double height,
  required double time,
  required double coverage,
  double wind = 0.0,
  double spriteAspect = 512 / 288,
}) {
  final placed = <PlacedCloud>[];
  // How many instances the current coverage justifies. Below ~0.08 the sky is
  // clear and nothing is drawn at all.
  final visible = (layout.clouds.length * coverage.clamp(0.0, 1.0)).ceil();

  for (var i = 0; i < layout.clouds.length && i < visible; i++) {
    final c = layout.clouds[i];

    // Near clouds drift faster — the parallax the reference gets from its 3D layout.
    final speed = layout.speed * (1.0 + wind * 2.0) * (1.6 - c.depth);
    // Wrap over two screen widths so a sprite is never popped into view.
    final span = 2.4;
    var x = (c.x + time * speed) % span;
    if (x < 0) x += span;
    x -= 0.7; // start off the left edge

    // Distant clouds are smaller and hazier.
    final w = width * c.scale * (1.25 - 0.45 * c.depth);
    final h = w / spriteAspect;

    placed.add((
      left: x * width,
      top: c.y * height - h * 0.5,
      width: w,
      height: h,
      opacity: c.opacity * (1.0 - 0.35 * c.depth),
      depth: c.depth,
      sprite: c.sprite,
    ));
  }

  // Far first, so nearer clouds overlap them.
  placed.sort((a, b) => b.depth.compareTo(a.depth));
  return placed;
}

/// The reference's light group: `(picker, multi, intensity)`.
///
/// `picker` selects which sky elevation the light samples (0 = horizon,
/// 1 = zenith), `multi` is a gain and `intensity` scales the contribution.
typedef LightConfig = (double picker, double multi, double intensity);

/// Cloud lighting for a given sun height, in the reference's five-group form.
///
/// The engine authors these per keyframe; the ramps here follow the same
/// shape — as the sun drops, every probe slides toward the horizon, which is
/// what turns the clouds gold at dusk without any colour being named.
({
  LightConfig base,
  LightConfig sun,
  LightConfig ground,
  LightConfig ambient,
  double whitePer,
})
cloudLighting({required double sunAngleY}) {
  // 0 at night, 1 at midday. `sunAngleY` runs ~0.01 … 0.57.
  final day = ((sunAngleY - 0.02) / 0.42).clamp(0.0, 1.0);

  return (
    // The body reads the sky just above the horizon.
    base: (0.05 + 0.10 * day, 0.70 + 0.35 * day, 1.0),
    // The lit face reads the sky near the sun's own height.
    sun: (0.10 + 0.70 * day, 0.85 + 0.55 * day, 0.55 + 0.75 * day),
    // Bounce off the haze below.
    ground: (0.02, 0.55 + 0.25 * day, 0.30 + 0.30 * day),
    // Dome fill from the zenith.
    ambient: (0.80 + 0.15 * day, 0.60 + 0.30 * day, 0.35 + 0.35 * day),
    // The reference's real curve peaks at 0.800. It cannot be used yet: `whitePer`
    // mixes each light toward warm `vec3(1, 0.74, 0.53)`, and the reference weights
    // those lights by the **authored per-keyframe `cloudConfig` intensities**
    // while this port still synthesises them from one `day` scalar. Those
    // synthesised intensities run high, so the true 0.8 pushes the four-light
    // sum past 1 and the sprites clamp to solid white (measured: 0% white
    // pixels at 0.1, large saturated blocks at 0.8).
    //
    // Blocked on consuming the authored cloudConfig; until then this stays at
    // a value that does not blow out.
    whitePer: 0.1 * smoothstep(0.30, 1.0, day),
  );
}
