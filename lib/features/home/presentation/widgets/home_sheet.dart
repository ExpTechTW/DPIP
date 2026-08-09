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

  // The sheet floors at [restExtent], so surface opacity only ever ramps from
  // its resting translucency up to fully opaque as it climbs to full.
  double _surfaceAlpha(double e) {
    final t = ((e - restExtent) / (maxExtent - restExtent)).clamp(0.0, 1.0);
    return lerpDouble(_restAlpha, 1, t)!;
  }

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
        final blur =
            24.0 *
            (surfaceAlpha / _restAlpha).clamp(0.0, 1.0) *
            (1 - weatherOpacity);
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
                      child: WeatherSkyBackground(
                        mode: weatherMode,
                        timeMode: skyTimeMode,
                        active: HomeChrome.weatherActive(e),
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

/// Blurs [child] in step with [scrollController], so the sky reads as depth
/// of field behind the content once the sheet's list scrolls the hero's rain
/// trend card up past the fold — the counterpart to `HomeContent`'s hero
/// block, which leaves the sky untouched (and unblurred) for as long as the
/// trend card is still the last thing on screen.
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
class _ScrollBlurredWeather extends StatelessWidget {
  const _ScrollBlurredWeather({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: scrollController,
      child: child,
      builder: (context, child) {
        final offset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final t = (offset / _rampExtent).clamp(0.0, 1.0);
        // Skip the filter layer entirely at rest, rather than compositing an
        // always-on blur of sigma 0 — the sheet spends most of its time here.
        if (t <= 0) return child!;
        final sigma = _maxSigma * t;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: child,
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
