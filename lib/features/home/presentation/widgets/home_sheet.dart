import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/features/home/presentation/home_chrome.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_background.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The draggable home sheet: a frosted panel over the map that reveals an
/// animated weather backdrop as it expands to full.
///
/// Owns the sheet's detent metrics ([restExtent] / [maxExtent]) and maps the
/// live [extent] onto surface opacity, backdrop blur, and the weather
/// backdrop's visibility. [restExtent] is also the sheet's floor — it can't be
/// dragged smaller. The scrollable content lives in [HomeContent]; the drag
/// mechanics live in the host `HomePage`.
///
/// The frosted chrome (blur, surface tint, shadow) genuinely has to redraw on
/// every pixel of the drag — it ramps across the sheet's *whole* travel. The
/// heavy stuff underneath it (forecast chart, sparkline, active-events list,
/// all inside [HomeContent]) does not: its own inputs only move within the
/// top ~15% of that travel ([HomeChrome.weatherReveal] / the flush window /
/// [HomeSheetExtent.isAtTop]). Building it once and handing it down via this
/// [ValueListenableBuilder]'s `child` — rather than reconstructing it inside
/// `builder` on every tick — keeps that content out of the per-frame rebuild;
/// [_HomeContentLayer] then re-derives its own inputs straight from
/// [HomeSheetExtent] with [BuildContext.select], so it only actually rebuilds
/// within the narrow window where they change. This is what used to make
/// dragging the sheet janky: every frame was relaying out the forecast chart
/// and event list for no visible change.
class HomeSheet extends StatelessWidget {
  const HomeSheet({
    super.key,
    required this.scrollController,
    required this.extent,
    required this.weatherMode,
    required this.skyTimeMode,
    this.rainIntensity,
    this.snowIntensity,
    this.humidity,
  });

  /// The sheet's detents, sourced from [HomeSheetExtent] so the value notifier's
  /// seed and this widget's opacity/blur ramps share one definition. [restExtent]
  /// doubles as the floor (min = rest), so the sheet never shrinks below it.
  static const double restExtent = HomeSheetExtent.rest;
  static const double maxExtent = HomeSheetExtent.max;

  /// Surface opacity at rest — translucent so the map shows through.
  static const double _restAlpha = 0.85;

  /// Extent past which the sheet flattens against the region bar — its top
  /// corners square off and its shadow fades — so it meets the bar flush
  /// instead of butting a rounded, shadowed edge against it.
  static const double _flushFrom = 0.9;

  /// The region-bar overlay's height (matches `RegionBar`), added to the safe
  /// area for the content inset as the sheet reaches the top.
  static const double _regionBarHeight = 44;

  /// The draggable sheet's scroll controller.
  final ScrollController scrollController;

  /// The sheet's live extent, `0`–`1` of the screen height.
  final ValueListenable<double> extent;

  /// Which weather look the backdrop renders.
  final WeatherMode weatherMode;

  /// Forced time of day for the backdrop, from experimental settings.
  final SkyTimeMode skyTimeMode;

  /// Live rain intensity override for the backdrop, or null for the look's own
  /// default — from the station's CWB code ([weatherRainIntensity]).
  final double? rainIntensity;

  /// Live snow intensity override, or null for the look's default.
  final double? snowIntensity;

  /// Live relative humidity 0..1 for the atmosphere blend, or null for the
  /// backdrop's own default.
  final double? humidity;

  // The sheet floors at [restExtent], so surface opacity only ever ramps from
  // its resting translucency up to fully opaque as it climbs to full.
  double _surfaceAlpha(double e) {
    final t = ((e - restExtent) / (maxExtent - restExtent)).clamp(0.0, 1.0);
    return lerpDouble(_restAlpha, 1, t)!;
  }

  /// Quantises a 0..1 ramp into [levels] discrete steps — full-screen blur
  /// sigmas then only change on level crossings, so the filter isn't fed a
  /// fresh value on every drag tick.
  static double _step(double t, int levels) => (t * levels).round() / levels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final regionBarInset = MediaQuery.paddingOf(context).top + _regionBarHeight;
    return ValueListenableBuilder<double>(
      valueListenable: extent,
      // Built once, not on every tick — see the class doc.
      child: _HomeContentLayer(
        scrollController: scrollController,
        weatherMode: weatherMode,
        regionBarInset: regionBarInset,
      ),
      builder: (context, e, content) {
        // 0 until [_flushFrom], then 1 at full — drives the flatten + inset.
        final flush = ((e - _flushFrom) / (maxExtent - _flushFrom)).clamp(
          0.0,
          1.0,
        );
        final surfaceAlpha = _surfaceAlpha(e);
        final weatherOpacity = HomeChrome.weatherReveal(e);
        // Quantised so the full-screen backdrop blur re-renders on a few level
        // changes through the drag instead of a fresh sigma every pixel —
        // same ladder trick as [_ScrollBlurredWeather]'s scroll blur.
        final blur =
            24.0 *
            _step(
              (surfaceAlpha / _restAlpha).clamp(0.0, 1.0) *
                  (1 - weatherOpacity),
              6,
            );
        final borderRadius = BorderRadius.vertical(
          top: Radius.circular(lerpDouble(AppRadius.lg, 0, flush)!),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15 * (1 - flush)),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Frosted map-through backdrop, dominant while collapsed.
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: ColoredBox(
                    color: colors.surface.withValues(alpha: surfaceAlpha),
                  ),
                ),
                // Animated weather backdrop, revealed and played near full —
                // it fills behind the region-bar overlay so the bar blends in.
                IgnorePointer(
                  child: Opacity(
                    opacity: weatherOpacity,
                    child: _ScrollBlurredWeather(
                      scrollController: scrollController,
                      // The sky freezes the instant the list scrolls: the
                      // blur/dim it is about to be put under masks the hold,
                      // and holding the last frame lets the blur layer below
                      // cache instead of re-rendering the whole backdrop shader
                      // on every scroll tick. The state's own clock and ticker
                      // stop together (see `_syncRunning`), so when the list
                      // returns to the top the animation resumes where it left
                      // off — no jump.
                      child: ListenableBuilder(
                        listenable: scrollController,
                        builder: (context, _) {
                          final scrolled =
                              scrollController.hasClients &&
                              scrollController.offset > 0;
                          return WeatherSkyBackground(
                            mode: weatherMode,
                            rainIntensity: rainIntensity,
                            snowIntensity: snowIntensity,
                            humidity: humidity ?? 0.65,
                            timeMode: skyTimeMode,
                            active: HomeChrome.weatherActive(e) && !scrolled,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                content!,
              ],
            ),
          ),
        );
      },
    );
  }

  /// 0 until [_flushFrom], then 1 at full — matches the flatten/inset ramp
  /// computed alongside it in [build], kept in sync via the same constants.
  static double _flush(double e) =>
      ((e - _flushFrom) / (maxExtent - _flushFrom)).clamp(0.0, 1.0);
}

/// Blurs and dims [child] in step with [scrollController], so the sky reads as
/// depth of field behind the content once the sheet's list scrolls the hero's
/// rain trend card up past the fold — the counterpart to `HomeContent`'s hero
/// block, which leaves the sky untouched (and unblurred) for as long as the
/// trend card is still the last thing on screen.
///
/// The dim rides the same scroll ramp as the blur: scrolling the list is what
/// shuts the cards' [RainOnGlass] refraction off (their position gate closes a
/// short distance into the gesture) and what solidifies `HomeContent`'s cards
/// out of their sky-glass back into solid plates — darkening the backdrop in
/// step keeps the space between cards quiet so the solid plates they arrive as
/// carry the reading.
///
/// This is a *second*, independent blur from the one [HomeSheet.build] already
/// ramps off the sheet's `extent` — that one plays only while the sheet itself
/// is being dragged open and is already at ~0 by the time the content becomes
/// scrollable (`extent` is pinned at [HomeSheet.maxExtent] for the list to
/// scroll at all). Driving both off the same value would leave this one dead;
/// [scrollController] is the only signal that still moves once the sheet does
/// not.
///
/// Listens directly on [scrollController] rather than through `HomeSheetExtent`
/// so only this small leaf repaints on every scroll tick — not the sheet's
/// whole frosted-chrome tree, which is the mistake `HomeSheet`'s own class doc
/// warns against for the drag case.
class _ScrollBlurredWeather extends StatefulWidget {
  const _ScrollBlurredWeather({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  State<_ScrollBlurredWeather> createState() => _ScrollBlurredWeatherState();
}

class _ScrollBlurredWeatherState extends State<_ScrollBlurredWeather> {
  /// Scroll distance over which blur reaches its peak. Short on purpose: the
  /// trend card itself is most of a screen's scroll away, and holding the sky
  /// crisp for that whole distance would make the blur feel disconnected from
  /// the gesture that triggered it. This finishes within the first small
  /// swipe, before the trend card has travelled far at all.
  static const double _rampExtent = 140;

  /// Peak blur sigma — soft enough to read as out-of-focus depth, not a
  /// frosted pane; well under the sheet's own drag blur (24, [HomeSheet.build]),
  /// since this sits behind readable card content rather than standing in for
  /// the sheet's surface.
  static const double _maxSigma = 16;

  /// Peak backdrop dim on the same scroll ramp — enough to drop the sky out of
  /// competition with the cards once the list is actually moving, without
  /// turning the whole backdrop into a black hole at the top of the gesture.
  static const double _maxDim = 0.45;

  /// The filter instance last handed to the [ImageFiltered] — [ImageFilter]
  /// has no value equality, so a fresh `blur(...)` every scroll tick would
  /// make the full-screen blur layer recomposite on **every** tick even though
  /// the sigma quantises to the same value. Reusing the instance keeps the
  /// layer cached for the whole 4-step scroll ramp.
  ImageFilter? _filter;

  /// Sigma the cached [_filter] was built for — the ladder is quantised, so
  /// this only differs on the handful of step crossings.
  double _filterSigma = -1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.scrollController,
      child: widget.child,
      builder: (context, child) {
        final offset = widget.scrollController.hasClients
            ? widget.scrollController.offset
            : 0.0;
        final t = (offset / _rampExtent).clamp(0.0, 1.0);
        // Quantised so the full-screen blur re-renders only on a few level
        // changes through the gesture, not on every scroll tick — with the
        // sky frozen behind it (see HomeSheet's build), the blur layer is
        // cached between steps and reused as long as the list keeps moving.
        // The dim rides the same ladder; a 4-step ramp reads as the same
        // smooth fade.
        final step = (t * 4).round() / 4;
        final sigma = _maxSigma * step;
        final dim = _maxDim * step;
        if (sigma != _filterSigma) {
          _filterSigma = sigma;
          _filter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
        }
        // The tree's SHAPE never changes — a blur that toggles via `enabled`
        // and an always-present transparent dim. Returning the bare child at
        // rest (as an early version did) re-parents the sky's element the
        // moment t crosses 0, which disposes and recreates the whole
        // `WeatherSkyBackground` state: its LUT cache is null again, so the
        // first blurred frame is the flat fallback colour until every shader
        // re-decodes. That is the flash. RainOnGlass's doc warns about the
        // same re-parenting for drags; here it cost a visible blink.
        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: _filter!,
              // No-op at rest, so no offscreen layer is composited — the sheet
              // spends most of its time here, and ImageFiltered.enabled skips
              // the filter without touching the tree shape.
              enabled: step > 0,
              child: child,
            ),
            // Dim sits *above* the blur so the backdrop darkens uniformly; the
            // content layer renders above this whole stack in HomeSheet, so the
            // cards are never dimmed with it. Transparent at rest.
            ColoredBox(color: Colors.black.withValues(alpha: dim)),
          ],
        );
      },
    );
  }
}

/// The scrollable content ([HomeContent]) — forecast chart, sparkline,
/// active-events list — re-deriving its own inputs from [HomeSheetExtent]
/// instead of being handed them by the chrome's per-tick rebuild above. Each
/// [BuildContext.select] only marks this dirty when *that* derived value
/// changes, so this rebuilds within its own narrow window, not on every pixel
/// of the drag.
class _HomeContentLayer extends StatelessWidget {
  const _HomeContentLayer({
    required this.scrollController,
    required this.weatherMode,
    required this.regionBarInset,
  });

  final ScrollController scrollController;
  final WeatherMode weatherMode;

  final double regionBarInset;

  @override
  Widget build(BuildContext context) {
    final reveal = context.select<HomeSheetExtent, double>(
      (extent) => HomeChrome.weatherReveal(extent.value),
    );
    final flush = context.select<HomeSheetExtent, double>(
      (extent) => HomeSheet._flush(extent.value),
    );
    final expanded = context.select<HomeSheetExtent, bool>(
      (extent) => HomeSheetExtent.isAtTop(extent.value),
    );
    return HomeContent(
      scrollController: scrollController,
      handleOpacity: 1 - reveal,
      reveal: reveal,
      topInset: lerpDouble(0, regionBarInset, flush)!,
      expanded: expanded,
      weatherMode: weatherMode,
    );
  }
}
