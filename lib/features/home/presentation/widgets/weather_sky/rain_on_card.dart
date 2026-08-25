import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_keyframe.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/scheduler.dart';

/// Puts rain on one card: water caught and pooling along its top edge, and —
/// while [RainOnCard.glass] is on — droplets clinging to its face.
///
/// Both halves come from the reference and both are separate from the falling
/// rain in the backdrop. The face gets a droplet shader as a `RenderEffect`
/// (that is [RainOnGlass]); the edge water is a panel particle system (that is
/// [CardWaterField] plus `shaders/weather/card_water.frag`) and runs
/// regardless of [RainOnCard.glass].
///
/// The edge water is drawn the way the engine draws it, in two passes:
///
///   1. Drops accumulate **additively** into an offscreen image — coverage
///      only, no colour. The reference uses an 800 px-tall RGBA16F render
///      texture here.
///   2. That buffer is composited through a shader that applies the alpha
///      threshold and the lighting. Everything that makes it look like water
///      happens in this pass, so drawing the particles straight to the screen —
///      as an earlier version of this did — shows the dots instead.
///
/// Applied per card rather than to the whole sheet: the reference wets the
/// card, not the page, and a refraction filter over an entire scrolling list
/// costs a full-surface pass every frame and warps text nowhere near the rain.
class RainOnCard extends StatefulWidget {
  const RainOnCard({
    super.key,
    required this.child,
    this.intensity = 0.0,
    this.opacity = 1.0,
    this.active = true,
    this.glass = true,
    this.silhouette = false,
    this.gated = true,
  });

  /// The card. Water is drawn over it, and — when [glass] is on — it is
  /// refracted through the droplets on its face.
  final Widget child;

  /// 0 disables both effects; 1 is a downpour on the card. Picks the grade —
  /// how much water arrives — as the reference's rain level picks a preset.
  final double intensity;

  /// Whether the face gets [RainOnGlass]'s refracting droplets, on top of the
  /// edge water every card gets regardless. `false` skips [RainOnGlass]
  /// entirely — [child] renders untouched, only the splash along the top edge
  /// runs. `true` (the default) still only runs it while the card's own
  /// position gate is open — see the position-gate doc below.
  final bool glass;

  /// Whether the splash collides with [child]'s own rendered outline instead
  /// of a flat line across the top of its bounding box.
  ///
  /// For [child] shapes that do not fill their own box — text, an icon,
  /// anything with real gaps in it — a flat edge pools water in mid-air over
  /// every gap. `true` rasterises [child] each time it actually changes (see
  /// `_RainOnCardState._scheduleCapture`) and builds a [CardWaterSurface]
  /// from its alpha channel, so a drop is caught by the nearest glyph or icon
  /// beneath it, or keeps falling if there genuinely is nothing there.
  final bool silhouette;

  /// Whether [_RainOnCardState._syncPositionGate]'s scroll-position cut-off
  /// applies to this card at all.
  ///
  /// The gate's fixed threshold (~21 % down the screen) is calibrated for a
  /// card that starts *below* it and rises past it mid-scroll — true of the
  /// rain-trend card, which sits at the bottom of the hero block. The header
  /// sits at the *top* of the same block and is already above that threshold
  /// at rest, so the same check would hold it permanently closed instead of
  /// ever opening. `false` skips the cut-off — the card relies on the
  /// surrounding scroll view culling its paint once it actually scrolls out
  /// of view, same as it would for any other off-screen widget.
  final bool gated;

  /// The scene alpha — how visible the whole effect is.
  ///
  /// Separate from [intensity] on purpose: the engine passes its global scene
  /// fade here, full strength whenever the scene shows. Folding the rain grade
  /// into it — as an earlier version did — ran the water at 0.6 × 0.55 ≈ 33%
  /// opacity and washed the whole effect out.
  final double opacity;

  /// Whether the water animates. False holds the last frame.
  final bool active;

  @override
  State<RainOnCard> createState() => _RainOnCardState();
}

class _RainOnCardState extends State<RainOnCard>
    with SingleTickerProviderStateMixin {
  static const String _asset = 'shaders/weather/card_water.frag';

  late final Ticker _ticker = createTicker(_onTick);

  /// Two fields — the reference configures two LiquidFun worlds and always
  /// draws both into one buffer.
  static final (ui.Image, ui.Image) _fallbackSprites = buildParticleSprites();
  late final CardWaterField _primary = CardWaterField(
    spritePos: _fallbackSprites.$1,
    spriteNeg: _fallbackSprites.$2,
  );
  late final CardWaterField _secondary = CardWaterField(
    spritePos: _fallbackSprites.$1,
    spriteNeg: _fallbackSprites.$2,
    seed: 23,
  );

  /// Repaints the water without rebuilding the card beneath it.
  final ValueNotifier<int> _frame = ValueNotifier(0);

  ui.FragmentShader? _shader;
  Duration _last = Duration.zero;
  Size _size = Size.zero;
  double _screenHeight = 0;
  Size _screenSize = Size.zero;

  /// Wraps [RainOnCard.child] so [_capture] has something to rasterise —
  /// only meaningful while [RainOnCard.silhouette] is on, but cheap enough to
  /// hold unconditionally rather than juggling a nullable key.
  final GlobalKey _captureKey = GlobalKey();

  /// The most recently captured outline, or null before the first capture
  /// completes — [_onTick] holds emission off until then rather than falling
  /// back to a flat edge for a frame or two, which [CardWaterField.update]
  /// would otherwise do on its own with a null surface.
  CardWaterSurface? _surface;
  bool _captureScheduled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Queues a rasterise-and-rebuild-the-surface pass for the end of the
  /// current frame, unless one is already queued or [RainOnCard.silhouette]
  /// is off. Coalescing through [_captureScheduled] matters because
  /// [didUpdateWidget] calls this on every rebuild while rain is running —
  /// without it, a sheet-drag animation rebuilding this widget every frame
  /// would queue a GPU readback every frame right along with it.
  void _scheduleCapture() {
    if (!widget.silhouette ||
        widget.intensity <= 0.001 ||
        _shader == null ||
        _captureScheduled) {
      return;
    }
    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  /// Rasterises [_captureKey]'s subtree — [RainOnCard.child], not whatever
  /// [RainOnGlass] does to it, since the boundary sits *inside* that filter
  /// and captures only its own descendants — and rebuilds [_surface] from
  /// the result.
  Future<void> _capture() async {
    _captureScheduled = false;
    if (!mounted || !widget.silhouette) return;
    final boundary = _captureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
      // Laid out but not yet painted (common on the very first frame) — try
      // again next frame instead of reading a boundary with nothing in it.
      _scheduleCapture();
      return;
    }
    ui.Image? image;
    try {
      // 1:1 with the widget's own logical pixels, matching the card-local
      // coordinates CardWaterField already works in — capturing at the
      // device's own pixel ratio would need every returned height rescaled
      // before it meant anything to the solver.
      image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (!mounted || data == null) return;
      _surface = silhouetteSurface(data, image.width, image.height);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to capture the splash outline');
    } finally {
      image?.dispose();
    }
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(_asset);
      if (!mounted) return;
      setState(() => _shader = program.fragmentShader());
      _syncRunning();
      _scheduleCapture();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to load shader $_asset');
    }
    // Swap the procedural stand-in for the baked sprite the moment the two
    // source textures decode. Both are generated by
    // `tool/gen/particle_sprites.py` — the kernel is a blurred disc, the
    // normal map an analytic hemisphere, so they are the same *functions*
    // the engine samples.
    try {
      // Shared across every card and every mount, like [_fallbackSprites]:
      // each mounted card used to decode both textures and bake its own
      // sprite pair — several cards rain at once on Home, and the pair was
      // never disposed with the State either, so scrolling leaked bakes.
      final (pos, neg) = await (_bakedSprites ??= _bakeShared());
      if (!mounted) return;
      _primary.spritePos = pos;
      _primary.spriteNeg = neg;
      _secondary.spritePos = pos;
      _secondary.spriteNeg = neg;
    } catch (error, stackTrace) {
      // Evict so a later mount retries rather than caching the failure.
      _bakedSprites = null;
      Log.handle(error, stackTrace, 'Failed to bake the drop sprite');
    }
  }

  /// The one baked sprite pair, app-lifetime — never disposed, exactly like
  /// [_fallbackSprites].
  static Future<(ui.Image, ui.Image)>? _bakedSprites;

  static Future<(ui.Image, ui.Image)> _bakeShared() async {
    final kernel = await _decodeAsset(
      'assets/weather/particles/particle_blurred.webp',
    );
    final normalMap = await _decodeAsset(
      'assets/weather/particles/drop_normal.webp',
    );
    try {
      return await bakeParticleSprites(kernel: kernel, normalMap: normalMap);
    } finally {
      kernel.dispose();
      normalMap.dispose();
    }
  }

  static Future<ui.Image> _decodeAsset(String key) async {
    final data = await rootBundle.load(key);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  /// Set while a gate-resume check is queued, so scroll ticks (which rebuild
  /// this card on every pixel) coalesce into one check rather than one
  /// post-frame callback each.
  bool _resumeScheduled = false;

  @override
  void didUpdateWidget(RainOnCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        (oldWidget.intensity > 0.001) != (widget.intensity > 0.001) ||
        (oldWidget.opacity > 0.004) != (widget.opacity > 0.004)) {
      _syncRunning();
    }
    // Rain about to start is exactly when a fresh outline matters most — the
    // capture from last time rain ran could be reading a since-changed
    // reading (a new temperature, a switched area). Re-running this on every
    // rebuild instead, not just this one transition, would queue a GPU
    // readback on every frame of a sheet-drag animation for no benefit.
    if (!(oldWidget.intensity > 0.001) && widget.intensity > 0.001) {
      _scheduleCapture();
    }
    // A scroll tick rebuilding this card may have reopened the position gate
    // since the ticker was stopped (a closed gate cuts the water outright).
    // If rain should be running but the ticker is idle, re-check the gate
    // once this frame settles and restart if it is open.
    //
    // The opacity term is not optional. Without it this block undoes the
    // [_syncRunning] call directly above it: fading out stops the ticker, which
    // makes `!_ticker.isActive` true, which schedules a resume that restarts it
    // — so the header card, whose opacity reaches exactly 0 once the hero
    // scrolls past the fold, kept stepping two water solvers and bumping
    // [_frame] every vsync while [_CardWaterPainter] returned without drawing a
    // pixel. Nothing else stopped it: this card is mounted with `gated: false`,
    // so the position gate is a constant `true`, and rain never drains below the
    // intensity floor.
    if (widget.active &&
        widget.intensity > 0.001 &&
        widget.opacity > 0.004 &&
        !_ticker.isActive &&
        !_resumeScheduled) {
      _resumeScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resumeScheduled = false;
        _resumeIfGateOpen();
      });
    }
  }

  void _resumeIfGateOpen() {
    if (!mounted) return;
    _syncPositionGate();
    // Same gate set as [_syncRunning], opacity included — a resume that used a
    // weaker test than the stop it is undoing is how the ticker came back to
    // life on an invisible card.
    if (_gateOpen &&
        _shader != null &&
        widget.active &&
        widget.intensity > 0.001 &&
        widget.opacity > 0.004) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _syncRunning() {
    final draining = _primary.liveCount > 0 || _secondary.liveCount > 0;
    final visible = widget.opacity > 0.004;
    if (_shader != null &&
        widget.active &&
        visible &&
        (widget.intensity > 0.001 || draining)) {
      if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    } else {
      _ticker.stop();
      if (widget.intensity <= 0.001) {
        _primary.clear();
        _secondary.clear();
      }
    }
  }

  /// The position gate: the panel water switches off entirely once the card
  /// has travelled [_gateCloseDistance] upward from the lowest point it has
  /// been at since appearing — and, alongside `widget.glass`, so does the
  /// face's refracting droplets, for the same reason: neither has any
  /// business still running on a card that is on its way off the top of the
  /// visible sheet.
  ///
  /// The reference gates on an *absolute* screen fraction instead — the water
  /// stops once the card's y drops below 30 % of a 1714/2400 reference
  /// height. That fits the reference's own layout, a list of many cards each
  /// scrolling past one fixed line, but not this card's: it starts most of a
  /// screen's height below that line, so the same check needed almost this
  /// card's entire travel before it closed — the problem this constant
  /// replaces. Gating on displacement from where the card actually settled
  /// closes it after a small, consistent swipe regardless of where that is.
  ///
  /// Tracking a running *low-water mark* — [_restTopY], the largest
  /// [_cardTopY] seen, i.e. the furthest down the screen — rather than the
  /// first sample matters for one reason: the sheet's own open animation
  /// moves the card by far more than this on its own, before the list is
  /// ever scrolled. Pinning the reference to wherever the card has actually
  /// settled, and letting it keep tracking that low point for as long as the
  /// card is still travelling toward (or resting at) it, keeps that
  /// animation from closing the gate on its own; displacement only grows
  /// once the card actually rises away from its settled point, which is
  /// what a real scroll does.
  ///
  /// The gate guards the particle draw *and* the accumulate-and-blur, so
  /// nothing renders at all — water has no business pooling on a card that is
  /// about to slide under the toolbar.
  static const double _gateCloseDistance = 64;

  /// Where the card's top edge currently sits, in logical pixels from the top
  /// of the window. Null before the first layout.
  double? _cardTopY;

  /// Running low-water mark for the gate — see [_gateCloseDistance]. Null
  /// before the first layout.
  double? _restTopY;
  bool _gateOpen = true;

  /// World gravity is multiplied by **1.5 while the card is travelling up the
  /// screen**, so water thrown off the lip is pulled back down instead of
  /// trailing behind a scroll.
  ///
  /// The reference compares the card's new position against the last one and
  /// switches to the boosted mode when it moved more than 5 px, applying the
  /// multiplier on every timer tick's `world.setGravity`. The 5 px is against
  /// the same 2400 px reference screen.
  double _gravityScale = 1.0;
  static const double _scrollGravityScale = 1.5;
  static const double _scrollThresholdRatio = 5 / 2400;

  /// Re-reads the card's position and applies the gate. Cheap enough to run
  /// per tick: the reference re-evaluates it on every scroll callback.
  void _syncPositionGate() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final previous = _cardTopY;
    _cardTopY = box.localToGlobal(Offset.zero).dy;
    final restTopY = _restTopY;
    _restTopY = restTopY == null || _cardTopY! > restTopY
        ? _cardTopY
        : restTopY;
    // The reference compares a quantity that grows as the card rises — so the
    // boosted mode is the card moving *up*, not any movement at all.
    _gravityScale =
        previous != null &&
            previous - _cardTopY! > _scrollThresholdRatio * _screenHeight
        ? _scrollGravityScale
        : 1.0;
    final open = !widget.gated || _restTopY! - _cardTopY! < _gateCloseDistance;
    if (open == _gateOpen) return;
    setState(() => _gateOpen = open);
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // Width only. The card sits in a ListView, so its height is unbounded at
    // layout time and `Size.isEmpty` was true on every frame — which silently
    // skipped the whole simulation and left the edge dry.
    if (dt <= 0 || _size.width <= 0) return;

    // A ticker goes on firing between `deactivate()` and `dispose()`, and that
    // window is exactly where this card sits when the list scrolls it away or a
    // tab teardown removes the page. [_syncPositionGate] reads
    // `context.findRenderObject()`, which throws on an inactive element, and
    // then calls `setState`, which throws on an unmounted one. Neither is worth
    // a frame of physics nobody can see.
    if (!mounted) return;

    _syncPositionGate();

    // Gate closed means the card is leaving the top of the sheet — cut the
    // water outright instead of letting it drain invisibly. The painter skips
    // it anyway, and every frame of physics on a card that is about to slide
    // under the toolbar (or already off past the fold) is wasted; the ticker
    // stays stopped until a scroll tick rebuilds this card and reopens the
    // gate (see [didUpdateWidget]).
    if (!_gateOpen) {
      _primary.clear();
      _secondary.clear();
      _frame.value++;
      _ticker.stop();
      return;
    }

    // While silhouette mode is waiting on its first capture there is no
    // surface to catch a drop on, so hold emission off rather than fall back
    // to a flat topEdge for a frame or two.
    final awaitingSurface = widget.silhouette && _surface == null;
    final intensity = awaitingSurface ? 0.0 : widget.intensity.clamp(0.0, 1.0);
    final surface = widget.silhouette ? _surface : null;
    final grade = _gradeFor(intensity);
    _primary.update(
      dt,
      width: _size.width,
      screenHeight: _screenHeight,
      intensity: intensity,
      preset: grade.$1,
      gravityScale: _gravityScale,
      surface: surface,
    );
    _secondary.update(
      dt,
      width: _size.width,
      screenHeight: _screenHeight,
      intensity: intensity,
      preset: grade.$2,
      gravityScale: _gravityScale,
      surface: surface,
    );
    _frame.value++;

    if (intensity <= 0.001 &&
        _primary.liveCount == 0 &&
        _secondary.liveCount == 0) {
      _ticker.stop();
    }
  }

  /// Maps our 0→1 intensity onto the reference's rain grades.
  ///
  /// **Both** worlds run at every grade — the reference's loop configures world 0 and
  /// world 1 identically for grades 0/1 and differently only for 2/3, and
  /// The reference always draws both. Idling the second world at the lighter grades,
  /// as an earlier version did, halves the water.
  static (CardWaterPreset, CardWaterPreset) _gradeFor(double intensity) {
    if (intensity >= 0.7) {
      return (CardWaterPreset.heavy, CardWaterPreset.heavySecondary);
    }
    if (intensity >= 0.35) {
      return (CardWaterPreset.moderate, CardWaterPreset.moderate);
    }
    return (CardWaterPreset.light, CardWaterPreset.light);
  }

  /// `specularIntensity` on the panel branch: 1.2 at night, 1.0 by day.
  static const double _specularDay = 1.0;
  static const double _specularNight = 1.2;

  /// Drawn diameter of one drop and the metaball's alpha cut, together —
  /// The reference picks the pair from the screen aspect: tall screens (h/w ≥ 2,
  /// the normal phone) get 5.0 px drops with the 0.6 cut, squarer screens
  /// smaller drops with a lower cut.
  ///
  /// Those are **buffer** pixels, not logical ones: the particle pass renders
  /// into an 800-tall render texture that stands for the whole screen, so a
  /// drop covers `size/800` of the screen's height whatever the device.
  (double, double) get _pointSizeAndThreshold {
    final w = _screenSize.width;
    final h = _screenSize.height;
    if (w <= 0 || h <= 0) return (5.0, 0.6);
    final scale = h / CardWaterField.bufferHeight;
    if (h / w >= 2.0) return (5.0 * scale, 0.6);
    if (h > w) return (3.3 * scale, 0.3);
    return (3.7 * scale, 0.3);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.sizeOf(context);
    _screenHeight = _screenSize.height;
    // The reference's night flag is `hour >= 15 || hour <= 4` — and that hour is
    // the scene's position on its 24-keyframe day ring, where ~15 is dusk and
    // ~4 is dawn. DPIP has the same mapping; the theme's brightness (used here
    // before) is unrelated to the sun.
    final wall = AppTime.utc8;
    final key = keyframePosition(
      wall.hour + wall.minute / 60.0,
      frameCount: 24,
    );
    final night = key >= 15.0 || key <= 4.0;
    final (pointSize, threshold) = _pointSizeAndThreshold;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(
          constraints.maxWidth,
          constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        );
        // Height may legitimately be 0 here — see [_onTick].
        // Boundary sits below RainOnGlass so a capture reads widget.child's
        // own pixels, not the glass filter's distortion of them — see
        // [_capture]'s doc.
        final content = RepaintBoundary(key: _captureKey, child: widget.child);
        return Stack(
          // Water sits above the card's top edge and must not be cut off.
          clipBehavior: Clip.none,
          children: [
            // **The gate rides the effect, never the tree's shape.**
            //
            // [RainOnGlass] documents this rule for its own subtree and this
            // is the same rule one level up: [content] carries [_captureKey],
            // and the gate is re-evaluated on scroll, so branching the tree on
            // it re-parented a GlobalKey subtree mid-drag. That was not a
            // cosmetic problem — it threw
            // `'!child.attached': is not true` out of `flushSemantics` on
            // every frame of the drag that flipped it, and killed the in-flight
            // gesture the same way the note inside `RainOnGlass` describes.
            //
            // So the wrapper stays mounted and the gate only zeroes what it
            // feeds: an intensity below `RainOnGlass`'s own threshold makes it
            // an `ImageFiltered(enabled: false)` and stops its ticker, which is
            // the same nothing the unwrapped branch used to render.
            //
            // [widget.glass] may still branch — it is a fixed property of each
            // call site, decided at construction and never toggled while the
            // card is alive.
            widget.glass
                ? RainOnGlass(
                    // A card sliding up toward the toolbar is about to scroll
                    // away, and refracting droplets over content that is
                    // mid-scroll has nothing left to sensibly distort. Running
                    // the shader filter every frame just to skip it wastes the
                    // GPU too. Reopening is free — the droplets resume from
                    // their own clock.
                    intensity: _gateOpen ? widget.intensity : 0,
                    opacity: widget.opacity,
                    active: widget.active && _gateOpen,
                    child: content,
                  )
                : content,
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _CardWaterPainter(
                      primary: _primary,
                      secondary: _secondary,
                      shader: _shader,
                      // Also repaints when the sky re-bakes, so the water's
                      // ambient follows the backdrop it falls out of.
                      repaint: Listenable.merge([
                        _frame,
                        SkyLutCache.panelAmbient,
                      ]),
                      opacity: widget.opacity.clamp(0.0, 1.0),
                      night: night,
                      screenHeight: _screenHeight,
                      pointSize: pointSize,
                      threshold: threshold,
                      screenWidth: _screenSize.width,
                      gateOpen: _gateOpen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CardWaterPainter extends CustomPainter {
  _CardWaterPainter({
    required this.primary,
    required this.secondary,
    required this.shader,
    required Listenable repaint,
    required this.opacity,
    required this.night,
    required this.screenHeight,
    required this.screenWidth,
    required this.gateOpen,
    required this.pointSize,
    required this.threshold,
  }) : super(repaint: repaint);

  final CardWaterField primary;
  final CardWaterField secondary;
  final ui.FragmentShader? shader;
  final double opacity;
  final bool night;
  final double screenHeight;
  final double screenWidth;

  /// The position gate — false once the card is too high on screen; both
  /// passes are skipped, not just the draw.
  final bool gateOpen;
  final double pointSize;
  final double threshold;

  /// The separable 5-tap blur the reference runs between the particle pass and
  /// the composite, as an equivalent gaussian.
  ///
  /// Taps sit at ±0.7 and ±0.35 of `uBlurBufferSize` with weights
  /// .164/.217/.238, so σ is `sqrt(2·(0.164·0.7² + 0.217·0.35²))` = 0.4625 of
  /// that step. The step is the load-bearing part: the reference computes it
  /// as `1/((w·355)/h)` **while both fields are still 1**, and only assigns the
  /// buffer's width and height afterwards — so the aspect correction is dead
  /// code and *both* axes get a flat 1/355 in **UV**.
  ///
  /// A UV step is not a pixel step. On the 800-tall buffer that is 1.04 px
  /// vertically but only `1.04·W/H` horizontally — the blur is 2.2x wider
  /// down the screen than across it, and reading it as one isotropic 0.46 px
  /// (as an earlier version did) leaves each drop far too sharp and far too
  /// much of it above the alpha cut.
  static const double _blurStepUv = 1 / 355;
  static const double _blurSigmaUv = 0.46253 * _blurStepUv;

  double get _sigmaX => _blurSigmaUv * screenWidth;
  double get _sigmaY => _blurSigmaUv * screenHeight;

  /// One signed half of the accumulation — see [CardWaterField.paintCoverage].
  ui.Image _accumulate(
    Size fieldSize,
    double headroom, {
    required bool negative,
  }) {
    final recorder = ui.PictureRecorder();
    final offscreen = Canvas(recorder);
    offscreen.saveLayer(
      Offset.zero & fieldSize,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: _sigmaX, sigmaY: _sigmaY),
    );
    offscreen.translate(0, headroom);
    primary.paintCoverage(offscreen, dropSize: pointSize, negative: negative);
    secondary.paintCoverage(offscreen, dropSize: pointSize, negative: negative);
    offscreen.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      fieldSize.width.ceil(),
      fieldSize.height.ceil(),
    );
    picture.dispose();
    return image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shader = this.shader;
    if (shader == null || opacity <= 0.004 || !gateOpen) return;
    if (primary.liveCount == 0 && secondary.liveCount == 0) return;
    if (size.isEmpty) return;

    // Pass 1: accumulate both signed halves, blurred as the engine blurs its
    // buffer. Spans the card plus the whole fall above it.
    final headroom = CardWaterField.spawnHeadroom(screenHeight);
    final fieldSize = Size(size.width, size.height + headroom);
    final pos = _accumulate(fieldSize, headroom, negative: false);
    final neg = _accumulate(fieldSize, headroom, negative: true);

    // Pass 2: reassemble the signed sum, light it, hard-cut it.
    // `J.s()` passes `Time().hour` — the local wall-clock hour.
    final hour = AppTime.utc8.hour.toDouble();
    var i = 0;
    void set(double v) => shader.setFloat(i++, v);
    set(fieldSize.width);
    set(fieldSize.height);
    // The sky at the panel band — the reference's `uBgLightTex` row. Until the first
    // bake lands, a rainy overcast grey-blue stands in.
    final ambient = SkyLutCache.panelAmbient.value ?? const Color(0xFF5C6B7E);
    set(ambient.r);
    set(ambient.g);
    set(ambient.b);
    set(night ? _specularNight : _specularDay);
    // The accumulation is scaled to dodge 8-bit saturation; the cut scales
    // with it so the metaball shape is untouched.
    set(threshold * CardWaterField.accumulationScale);
    set(opacity);
    set(hour);
    shader.setImageSampler(0, pos);
    shader.setImageSampler(1, neg);

    canvas.save();
    canvas.translate(0, -headroom);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fieldSize.width, fieldSize.height),
      Paint()..shader = shader,
    );
    canvas.restore();
    pos.dispose();
    neg.dispose();
  }

  static const double _specularDay = _RainOnCardState._specularDay;
  static const double _specularNight = _RainOnCardState._specularNight;

  @override
  bool shouldRepaint(covariant _CardWaterPainter oldDelegate) =>
      oldDelegate.opacity != opacity ||
      oldDelegate.night != night ||
      oldDelegate.shader != shader ||
      oldDelegate.pointSize != pointSize ||
      oldDelegate.threshold != threshold ||
      oldDelegate.screenHeight != screenHeight ||
      oldDelegate.screenWidth != screenWidth ||
      oldDelegate.gateOpen != gateOpen;
}
