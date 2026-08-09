import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/material.dart';

/// Puts rain on the *content*: droplets cling to [child] and bend its pixels
/// through each bead.
///
/// This is a distinct system from the falling rain behind it. The reference applies
/// The reference shader as an Android `RenderEffect` on the card View,
/// so the card's own pixels refract — which is why text visibly warps behind
/// the beads rather than having droplets drawn flat on top.
///
/// Flutter's equivalent is `ui.ImageFilter.shader`, whose contract matches
/// Android's: the first uniform is a `vec2` the engine fills with the input
/// texture size, and the first sampler receives the filtered content.
///
/// **Impeller only.** `ImageFilter.shader` throws on the Skia backend, so the
/// filter is dropped and [child] renders untouched — the effect is decoration,
/// and losing it must never cost the content.
class RainOnGlass extends StatefulWidget {
  /// The content the droplets sit on.
  final Widget child;

  /// 0 disables the effect entirely; 1 is a full downpour on the glass —
  /// selects among the reference's three uniform grades.
  final double intensity;

  /// The shader's `uAlpha` — how strongly the refraction shows. The reference's
  /// controller passes its animation alpha here, 1 once the scene is up.
  final double opacity;

  /// Whether the droplets animate. When false the last frame holds.
  final bool active;

  const RainOnGlass({
    super.key,
    required this.child,
    this.intensity = 0.0,
    this.opacity = 1.0,
    this.active = true,
  });

  @override
  State<RainOnGlass> createState() => _RainOnGlassState();
}

class _RainOnGlassState extends State<RainOnGlass>
    with SingleTickerProviderStateMixin {
  static const String _asset = 'shaders/weather/rain_on_glass.frag';

  final Stopwatch _clock = Stopwatch();
  late final AnimationController _ticker = AnimationController(
    duration: const Duration(seconds: 30),
    vsync: this,
  );

  ui.FragmentShader? _shader;

  /// Set once `ImageFilter.shader` has been seen to fail, so the throw is not
  /// repeated every frame on a Skia device.
  bool _filterUnsupported = false;

  @override
  void initState() {
    super.initState();
    _syncRunning();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_asset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to load shader $_asset');
    }
  }

  void _syncRunning() {
    if (widget.active && widget.intensity > 0.01) {
      if (!_clock.isRunning) _clock.start();
      _ticker.repeat();
    } else {
      _clock.stop();
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(RainOnGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        (oldWidget.intensity > 0.01) != (widget.intensity > 0.01)) {
      _syncRunning();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    _clock.stop();
    super.dispose();
  }

  /// Builds the droplet filter, or `null` if shaders-as-filters are not
  /// available on this backend.
  ui.ImageFilter? _filter(double intensity) {
    final shader = _shader;
    if (shader == null || _filterUnsupported) return null;

    final grade = _GlassGrade.forIntensity(intensity);
    final time = _clock.elapsedMilliseconds / 1000.0;
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    // Slots 0..1 are the input size; the engine overwrites them, but they must
    // exist for `ImageFilter.shader` to accept the shader.
    set(0);
    set(0);
    // The reference's fixed frame — the reference sets uResolution to 1080×1080 once at
    // creation and never per-view, so bead size is absolute, not card-relative.
    set(1080);
    set(1080);
    set(time);
    set(grade.staticSize);
    set(grade.staticAmount);
    set(grade.staticSpeed);
    set(grade.runningSize);
    set(grade.runningAmount);
    set(grade.runningSpeed);
    // `uAlpha` is the effect's own strength, not the rain amount.
    set(widget.opacity.clamp(0.0, 1.0));

    try {
      return ui.ImageFilter.shader(shader);
    } catch (error, stackTrace) {
      // Skia backend: no shader image filters. Drop the effect for good.
      Log.handle(
        error,
        stackTrace,
        'ImageFilter.shader unavailable; rain-on-glass disabled',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _filterUnsupported = true);
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The widget tree's SHAPE must not depend on the intensity. `intensity`
    // is scaled by the sheet's expansion, so it crosses the on/off threshold
    // *while the user is dragging* — and swapping between a wrapped and an
    // unwrapped child re-parents the content's element, which silently kills
    // the in-flight drag. Taps survive it because they complete within a
    // frame; a drag does not.
    //
    // So the structure is fixed and only `enabled` and the filter change.
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, child) {
        final intensity = widget.intensity.clamp(0.0, 1.0);
        final filter = intensity < 0.01 || widget.opacity < 0.004
            ? null
            : _filter(intensity);
        return ImageFiltered(
          // A no-op filter keeps the widget — and so the element tree —
          // present even when the effect is off.
          imageFilter:
              filter ?? ui.ImageFilter.matrix(Matrix4.identity().storage),
          enabled: filter != null,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// The droplet field's uniforms for one rain grade.
///
/// One ladder, walked by a single 0->1 grade, rather than a table of
/// hand-picked rows: every uniform here is monotone in how hard it is raining,
/// so the rows a table would hold are just this line sampled at three points.
///
/// The ladder runs the way intuition does **not**: the lighter the rain, the
/// *smaller and denser* the beads. Light rain deposits a fine mist that
/// condenses everywhere and rarely gathers enough mass to run; heavy rain
/// arrives in drops that land big, merge fast, and slide almost at once.
/// [staticSize] and [runningSize] are **divisors** in the shader
/// (`uv * 40 / uStaticDropSize`), so a smaller value means a tighter lattice:
/// 0.55 gives a 14.9 device-px cell against 1.15's 31 px — four times the
/// beads at half the size. Pinning every rain mode to the heavy end, as an
/// earlier version did, is exactly the "too big, too sparse" that a light-rain
/// capture shows it should not be.
class _GlassGrade {
  const _GlassGrade({
    required this.staticSize,
    required this.staticAmount,
    required this.staticSpeed,
    required this.runningSize,
    required this.runningAmount,
    required this.runningSpeed,
  });

  /// The ladder itself: [grade] 0 is a fine mist, 1 is a storm.
  factory _GlassGrade.atGrade(double grade) {
    double at(double light, double heavy) => light + (heavy - light) * grade;
    return _GlassGrade(
      staticSize: at(0.55, 1.15),
      staticAmount: at(0.55, 1.0),
      staticSpeed: at(0.9, 2.2),
      runningSize: at(0.9, 1.5),
      runningAmount: at(0.5, 1.0),
      runningSpeed: at(0.5, 1.4),
    );
  }

  final double staticSize;
  final double staticAmount;
  final double staticSpeed;
  final double runningSize;
  final double runningAmount;
  final double runningSpeed;

  /// Light rain and sleet — fine, dense beads that mostly stay put.
  static final _GlassGrade drizzle = _GlassGrade.atGrade(0.0);

  /// Moderate rain.
  ///
  /// Unreachable today: [WeatherMode] has only `rain` and `thunderstorm` for
  /// wet weather, which sit at the two ends. Named anyway because the ladder is
  /// continuous and this is where a heavy-rain mode would land.
  static final _GlassGrade steady = _GlassGrade.atGrade(0.5);

  /// Heavy rain through storm — big, fast beads that run almost at once.
  static final _GlassGrade downpour = _GlassGrade.atGrade(1.0);

  /// Maps our 0->1 intensity onto the ladder.
  ///
  /// Quantised to three rungs rather than interpolated continuously: the
  /// intensity is scaled by the sheet's expansion, so a continuous mapping
  /// would have the beads visibly resizing under the user's finger mid-drag.
  static _GlassGrade forIntensity(double intensity) {
    if (intensity >= 0.7) return downpour;
    if (intensity >= 0.35) return steady;
    return drizzle;
  }
}
