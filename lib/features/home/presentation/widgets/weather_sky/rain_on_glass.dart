import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_frame_pace.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_raster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Edge of the droplet-coverage bake, in pixels. The refract pass samples
/// this instead of rebuilding the field at the card's resolution.
const int kRainOnGlassFieldEdge = 256;

/// Writes coverage (R) and the one-step neighbour (G) for [shader] into a
/// [kRainOnGlassFieldEdge] square. [shader] must be `rain_on_glass.frag`
/// with `uMode` driven to the bake path. [dummy] satisfies the two samplers
/// the bake does not read.
///
/// Synchronous, for the field test. The running effect uses
/// [bakeRainOnGlassFieldAsync] so a frame does not flush the GPU.
ui.Image bakeRainOnGlassField({
  required ui.FragmentShader shader,
  required ui.Image dummy,
  required double time,
  required double opacity,
  required double staticSize,
  required double staticAmount,
  required double staticSpeed,
  required double runningSize,
  required double runningAmount,
  required double runningSpeed,
}) {
  final picture = _recordGlassField(
    shader: shader,
    dummy: dummy,
    time: time,
    opacity: opacity,
    staticSize: staticSize,
    staticAmount: staticAmount,
    staticSpeed: staticSpeed,
    runningSize: runningSize,
    runningAmount: runningAmount,
    runningSpeed: runningSpeed,
  );
  final image = rasterizePictureSync(
    picture,
    kRainOnGlassFieldEdge,
    kRainOnGlassFieldEdge,
  );
  picture.dispose();
  return image;
}

/// [bakeRainOnGlassField] without the UI-thread flush. The picture is recorded
/// here and rasterized on the raster thread.
Future<ui.Image> bakeRainOnGlassFieldAsync({
  required ui.FragmentShader shader,
  required ui.Image dummy,
  required double time,
  required double opacity,
  required double staticSize,
  required double staticAmount,
  required double staticSpeed,
  required double runningSize,
  required double runningAmount,
  required double runningSpeed,
}) {
  final picture = _recordGlassField(
    shader: shader,
    dummy: dummy,
    time: time,
    opacity: opacity,
    staticSize: staticSize,
    staticAmount: staticAmount,
    staticSpeed: staticSpeed,
    runningSize: runningSize,
    runningAmount: runningAmount,
    runningSpeed: runningSpeed,
  );
  final future = rasterizePicture(
    picture,
    kRainOnGlassFieldEdge,
    kRainOnGlassFieldEdge,
  );
  picture.dispose();
  return future;
}

ui.Picture _recordGlassField({
  required ui.FragmentShader shader,
  required ui.Image dummy,
  required double time,
  required double opacity,
  required double staticSize,
  required double staticAmount,
  required double staticSpeed,
  required double runningSize,
  required double runningAmount,
  required double runningSpeed,
}) {
  final edge = kRainOnGlassFieldEdge.toDouble();
  var i = 0;
  void set(double v) => shader.setFloat(i++, v);
  set(edge);
  set(edge);
  set(1080);
  set(1080);
  set(time);
  set(staticSize);
  set(staticAmount);
  set(staticSpeed);
  set(runningSize);
  set(runningAmount);
  set(runningSpeed);
  set(opacity);
  set(1);
  shader
    ..setImageSampler(0, dummy)
    ..setImageSampler(1, dummy);
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
      .drawRect(Rect.fromLTWH(0, 0, edge, edge), Paint()..shader = shader);
  return recorder.endRecording();
}

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

  /// When true, the ticker starts even though shader image filters are
  /// unsupported.
  ///
  /// A widget-test backend reports them unsupported, which would otherwise
  /// leave the ticker stopped. The filter still fails to build, and that
  /// failure stops the ticker once a field image is shown.
  @visibleForTesting
  static bool debugRunTickerWithoutShaderFilter = false;
}

class _RainOnGlassState extends State<RainOnGlass>
    with SingleTickerProviderStateMixin {
  static const String _asset = 'shaders/weather/rain_on_glass.frag';

  /// Same clock as the card-water solver. The bead field is a function of
  /// time, so holding [uTime] on this quantum is what lets one [ImageFilter]
  /// survive the frames in between.
  static const double _step = CardWaterField.emitterTick;

  late final SkyPacedTicker _ticker = SkyPacedTicker(this, _onTick);
  Duration _last = Duration.zero;
  double _carry = 0;
  double _simTime = 0;

  ui.FragmentShader? _shader;
  ui.FragmentShader? _fieldShader;
  ui.Image? _field;
  ui.Image? _retireField;
  ui.Image? _dummy;

  /// Finished field waiting for the next tick. Publishing it as it lands
  /// would ask for a frame of its own between two paced ticks.
  ui.Image? _readyField;
  double _readyTime = 0;
  _GlassGrade? _readyGrade;

  ui.ImageFilter? _cachedFilter;
  double _cachedOpacity = -1;
  _GlassGrade? _cachedGrade;
  double _displayedTime = -1;
  _GlassGrade? _bakedGrade;

  bool _bakeInFlight = false;
  bool _bakeAgain = false;
  double _pendingTime = 0;
  bool _closed = false;

  /// Set once `ImageFilter.shader` has been seen to fail, so the throw is not
  /// repeated every frame on a Skia device.
  bool _filterUnsupported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_asset);
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader();
        _fieldShader = program.fragmentShader();
      });
      _syncRunning();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to load shader $_asset');
    }
  }

  void _syncRunning() {
    // No shader means there can be no visible frame. This also permanently
    // stops the vsync loop on Skia, where a shader image filter cannot exist.
    // [RainOnGlass.debugRunTickerWithoutShaderFilter] lets a test run the
    // ticker on that backend anyway.
    //
    // The opacity term mirrors [build]'s own short-circuit: below 0.004 the
    // filter is never built, so a ticker kept alive there only wakes a frame
    // sixty times a second. The header card's opacity reaches exactly 0 once
    // the hero scrolls past the fold, and that is the state this used to spin
    // in (`RainOnCard` gates its own ticker the same way).
    if (!ui.ImageFilter.isShaderFilterSupported &&
        !RainOnGlass.debugRunTickerWithoutShaderFilter) {
      _filterUnsupported = true;
    }
    if (widget.active &&
        widget.intensity > 0.01 &&
        widget.opacity > 0.004 &&
        _shader != null &&
        !_filterUnsupported) {
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (_closed || _filterUnsupported) {
      _ticker.stop();
      return;
    }
    _publishReady();
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // The first callback has no dt. Seed a still field so the glass is not
    // blank until the first step; it is not itself a solver step.
    if (dt <= 0) {
      if (_field == null) _requestBake(0, fromTick: false);
      return;
    }
    final elapsedDt = dt > 0.1 ? 0.1 : dt;
    _carry += elapsedDt;
    final steps = _carry ~/ _step;
    if (steps <= 0) return;
    _carry -= steps * _step;
    _simTime += steps * _step;
    noteWeatherSolverSteps(steps);
    _requestBake(_simTime, fromTick: true);
  }

  /// Starts one coverage raster, unless one is already running — then the
  /// newest time waits, and the picture on screen stays the previous one.
  void _requestBake(double time, {required bool fromTick}) {
    if (_closed || _filterUnsupported) return;
    if (_bakeInFlight) {
      _bakeAgain = true;
      _pendingTime = time;
      return;
    }
    final shader = _fieldShader;
    if (shader == null) return;
    final grade = _GlassGrade.forIntensity(widget.intensity);
    if (_field != null && time == _displayedTime && grade == _bakedGrade) {
      return;
    }
    _bakeInFlight = true;
    if (fromTick) noteWeatherTickRaster();
    unawaited(_bake(shader, grade, time));
  }

  void _publishReady() {
    final image = _readyField;
    if (image == null || !mounted) return;
    _readyField = null;
    // The filter still on screen samples [_retireField] until this frame
    // replaces it, so the image one generation back stays alive.
    _retireField?.dispose();
    _retireField = _field;
    _field = image;
    _displayedTime = _readyTime;
    _bakedGrade = _readyGrade;
    _cachedFilter = null;
    // The new field is published by writing the filter onto the render
    // object already in the tree. The widget is not rebuilt, so an ancestor
    // [LayoutBuilder] is not laid out again for this frame.
    final render = context.findRenderObject();
    if (render is RenderRainGlassFiltered) render.filter = _activeFilter();
  }

  Future<void> _bake(
    ui.FragmentShader shader,
    _GlassGrade grade,
    double time,
  ) async {
    ui.Image? image;
    try {
      final dummy = await _ensureDummy();
      if (dummy != null) {
        image = await bakeRainOnGlassFieldAsync(
          shader: shader,
          dummy: dummy,
          time: time,
          opacity: widget.opacity,
          staticSize: grade.staticSize,
          staticAmount: grade.staticAmount,
          staticSpeed: grade.staticSpeed,
          runningSize: grade.runningSize,
          runningAmount: grade.runningAmount,
          runningSpeed: grade.runningSpeed,
        );
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'rain-on-glass raster failed');
    } finally {
      _bakeInFlight = false;
    }
    if (_closed || !mounted || image == null) {
      image?.dispose();
    } else {
      _readyField?.dispose();
      _readyField = image;
      _readyTime = time;
      _readyGrade = grade;
      if (!_ticker.isActive) _publishReady();
    }
    if (!_closed && _bakeAgain) {
      _bakeAgain = false;
      _requestBake(_pendingTime, fromTick: false);
    }
  }

  Future<ui.Image?> _ensureDummy() async {
    final existing = _dummy;
    if (existing != null) return existing;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0x00000000),
    );
    final picture = recorder.endRecording();
    try {
      final image = await rasterizePicture(picture, 1, 1);
      picture.dispose();
      if (_closed) {
        image.dispose();
        return null;
      }
      return _dummy = image;
    } catch (error, stackTrace) {
      picture.dispose();
      Log.handle(error, stackTrace, 'rain-on-glass raster failed');
      return null;
    }
  }

  /// The droplet filter for the current field image. The same instance is
  /// handed back while time, grade and opacity are unchanged, so the card
  /// snapshot under [RainGlassFiltered] is not recomposited on an idle frame.
  ui.ImageFilter? _filterFor(double intensity, double opacity) {
    final field = _field;
    final shader = _shader;
    if (field == null || shader == null || _filterUnsupported) {
      return null;
    }
    final grade = _GlassGrade.forIntensity(intensity);
    // [_cachedFilter] is cleared whenever the field image or its time changes,
    // so a non-null cache is already the filter for [_displayedTime].
    if (_cachedFilter != null &&
        _cachedOpacity == opacity &&
        _cachedGrade == grade) {
      return _cachedFilter;
    }
    final filter = _compose(shader, grade, opacity, field);
    if (filter == null) return null;
    _cachedFilter = filter;
    _cachedOpacity = opacity;
    _cachedGrade = grade;
    return filter;
  }

  ui.ImageFilter? _compose(
    ui.FragmentShader shader,
    _GlassGrade grade,
    double opacity,
    ui.Image field,
  ) {
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    // Slots 0..1 are the input size; the engine overwrites them, but they must
    // exist for `ImageFilter.shader` to accept the shader.
    set(0);
    set(0);
    // The reference's fixed frame — uResolution is 1080×1080 once at creation
    // and never per-view, so bead size is absolute, not card-relative.
    set(1080);
    set(1080);
    set(_displayedTime);
    set(grade.staticSize);
    set(grade.staticAmount);
    set(grade.staticSpeed);
    set(grade.runningSize);
    set(grade.runningAmount);
    set(grade.runningSpeed);
    // `uAlpha` is the effect's own strength, not the rain amount. The coverage
    // bake does not read it, so an opacity change rebuilds the filter only.
    set(opacity);
    set(0);
    shader.setImageSampler(1, field);
    try {
      return ui.ImageFilter.shader(shader);
    } catch (error, stackTrace) {
      // Skia backend: no shader image filters. Drop the effect for good.
      Log.handle(
        error,
        stackTrace,
        'ImageFilter.shader unavailable; rain-on-glass disabled',
      );
      _filterUnsupported = true;
      _ticker.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _closed) return;
        setState(() {});
        _syncRunning();
      });
      return null;
    }
  }

  @override
  void didUpdateWidget(RainOnGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        (oldWidget.intensity > 0.01) != (widget.intensity > 0.01) ||
        (oldWidget.opacity > 0.004) != (widget.opacity > 0.004)) {
      _syncRunning();
    }
    final oldGrade = _GlassGrade.forIntensity(oldWidget.intensity);
    final grade = _GlassGrade.forIntensity(widget.intensity);
    if (oldGrade != grade && _ticker.isActive) {
      _requestBake(_simTime, fromTick: false);
    }
  }

  @override
  void dispose() {
    _closed = true;
    _ticker.dispose();
    _shader?.dispose();
    _fieldShader?.dispose();
    _field?.dispose();
    _retireField?.dispose();
    _readyField?.dispose();
    _dummy?.dispose();
    super.dispose();
  }

  /// Filter applied to the child right now. Null leaves the child unfiltered.
  ui.ImageFilter? _activeFilter() {
    final intensity = widget.intensity.clamp(0.0, 1.0);
    final opacity = widget.opacity.clamp(0.0, 1.0);
    return intensity < 0.01 || opacity <= 0.004 || _filterUnsupported
        ? null
        : _filterFor(intensity, opacity);
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
    // So the structure is fixed: [RainGlassFiltered] is always there, and
    // only its filter changes. A null filter leaves the child unfiltered.
    // The filter object itself is reused until a 20 ms step's raster lands
    // or the opacity / grade actually change.
    return RainGlassFiltered(filter: _activeFilter(), child: widget.child);
  }
}

/// Applies [filter] to [child]. A null [filter] draws [child] unchanged.
///
/// The element stays either way, so the effect turning on or off does not
/// reparent [child]. The render object keeps one [ImageFilterLayer] and
/// replaces the filter on it.
@visibleForTesting
class RainGlassFiltered extends SingleChildRenderObjectWidget {
  const RainGlassFiltered({super.key, required this.filter, super.child});

  /// The filter to apply, or null to leave [child] unfiltered.
  final ui.ImageFilter? filter;

  @override
  RenderRainGlassFiltered createRenderObject(BuildContext context) {
    return RenderRainGlassFiltered(filter);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderRainGlassFiltered renderObject,
  ) {
    renderObject.filter = filter;
  }
}

/// Render object for [RainGlassFiltered].
///
/// A null [filter] is the off state: this is a repaint boundary only while a
/// filter is set, and [updateCompositedLayer] writes that filter onto the
/// [ImageFilterLayer] it already owns.
@visibleForTesting
class RenderRainGlassFiltered extends RenderProxyBox {
  RenderRainGlassFiltered(ui.ImageFilter? filter) : _filter = filter;

  ui.ImageFilter? get filter => _filter;
  ui.ImageFilter? _filter;
  set filter(ui.ImageFilter? value) {
    if (identical(value, _filter)) return;
    final toggled = (value == null) != (_filter == null);
    _filter = value;
    if (toggled) {
      markNeedsCompositingBitsUpdate();
      markNeedsPaint();
    } else {
      // A new filter on the layer that is already there. The child's pixels
      // have not changed, so nothing under this layer is repainted.
      markNeedsCompositedLayerUpdate();
    }
  }

  @override
  bool get alwaysNeedsCompositing => child != null && filter != null;

  @override
  bool get isRepaintBoundary => alwaysNeedsCompositing;

  @override
  OffsetLayer updateCompositedLayer({
    required covariant ImageFilterLayer? oldLayer,
  }) {
    final layer = oldLayer ?? ImageFilterLayer();
    layer.imageFilter = filter;
    return layer;
  }
}

/// One of the three droplet uniform sets for the card effect.
///
/// The branch key is the weather *type*, not a rain "level". Light rain and
/// sleet take [drizzle]; moderate rain takes [steady]; everything from heavy
/// rain up through storm takes [downpour].
///
/// The ladder runs the way intuition does **not**: the lighter the rain, the
/// *smaller and denser* the beads. `uStaticDropSize` is a divisor —
/// `uv *= 40 / uStaticDropSize` — so 0.5 gives a 13.5 device-px lattice against
/// 1.0's 27 px, i.e. four times the beads at half the size. Pinning every rain
/// mode to the downpour set, as an earlier version did, is exactly the "too
/// big, too sparse" that a light-rain capture shows it should not be.
class _GlassGrade {
  const _GlassGrade({
    required this.staticSize,
    required this.staticAmount,
    required this.staticSpeed,
    required this.runningSize,
    required this.runningAmount,
    required this.runningSpeed,
  });

  final double staticSize;
  final double staticAmount;
  final double staticSpeed;
  final double runningSize;
  final double runningAmount;
  final double runningSpeed;

  /// Light rain and sleet — fine, dense beads.
  static const _GlassGrade drizzle = _GlassGrade(
    staticSize: 0.5,
    staticAmount: 0.5,
    staticSpeed: 1.0,
    runningSize: 0.85,
    runningAmount: 0.6,
    runningSpeed: 0.4,
  );

  /// Moderate rain.
  ///
  /// Unreachable today: [WeatherMode] has only `rain` and `thunderstorm` for
  /// wet weather, which sit on the light and storm rungs. Kept because it is
  /// the ladder's own middle rung, and the moment a heavy-rain mode exists it
  /// is the set it needs — inventing one then would just be guessing again.
  static const _GlassGrade steady = _GlassGrade(
    staticSize: 0.8,
    staticAmount: 0.8,
    staticSpeed: 1.5,
    runningSize: 1.0,
    runningAmount: 0.7,
    runningSpeed: 1.0,
  );

  /// Heavy rain through storm. Big, fast, sparse beads.
  static const _GlassGrade downpour = _GlassGrade(
    staticSize: 1.0,
    staticAmount: 1.0,
    staticSpeed: 2.0,
    runningSize: 1.4,
    runningAmount: 1.0,
    runningSpeed: 1.3,
  );

  /// Maps our 0→1 intensity onto the ladder. Whole sets are switched by
  /// weather type rather than interpolated, so this does the same.
  static _GlassGrade forIntensity(double intensity) {
    if (intensity >= 0.7) return downpour;
    if (intensity >= 0.35) return steady;
    return drizzle;
  }
}
