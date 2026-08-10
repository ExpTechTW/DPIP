import 'dart:ui' show lerpDouble;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_forecast_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_rain_trend_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/rain_on_card.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/sky_lut_cache.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The scrollable home dashboard shown inside the draggable sheet — the surface
/// that fills the screen when the sheet is pulled up.
///
/// A single [ListView] (driven by the sheet's [scrollController], so overscroll
/// expands the sheet) hosts the grab handle and the per-area panel. Switching
/// area slides only that panel (`_AreaSlide`); the list and its controller stay
/// put, which is what keeps the sheet height stable across a switch.
///
/// Below the header: **active events** while collapsed. Once flush full-screen
/// on a township, the header and the **rain trend** card share one block sized
/// to exactly fill the visible sheet ([_heroHeight]) — the header stays at the
/// top, the trend card sits flush against the bottom edge, and the open sky
/// animates in the gap between them instead of being crowded out by cards. The
/// **24h forecast** and active events sit below that block, off-screen until
/// the sheet is scrolled past the trend card; `HomeSheet` blurs the sky
/// backdrop in step with that same scroll so the list reads clearly once it
/// arrives. 全國 skips weather entirely (name + events only, no hero block);
/// 所在地 with no GPS fix shows the header's "can't locate you" notice **alone**
/// — no cards at all.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.scrollController,
    this.handleOpacity = 1,
    this.reveal = 0,
    this.topInset = 0,
    this.expanded = false,
    this.weatherMode = WeatherMode.auto,
  });

  /// The draggable sheet's scroll controller.
  final ScrollController scrollController;

  /// Opacity of the grab handle — faded to 0 as the sheet reaches full, where
  /// the pull-up affordance is no longer needed.
  final double handleOpacity;

  /// How much the weather backdrop is revealed (0→1) — glass card opacity +
  /// sky-aware header ink.
  final double reveal;

  /// Extra top padding that clears the region-bar overlay as the sheet reaches
  /// full, so the content isn't hidden behind it.
  final double topInset;

  /// Sheet is flush full-screen — header typography/layout step up (chart-sheet
  /// pattern); rain trend + 24h forecast appear above the active-events block
  /// (township only).
  final bool expanded;

  /// Backdrop sky mode — header ink picks dark vs white from this.
  final WeatherMode weatherMode;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RegionStore>();
    final areaIndex = store.selectedIndex;
    final area = store.selected;
    // The hero block's bottom card slot swaps between the rain-trend chart and
    // a compact 24h summary. Track the trend alone — not the whole controller —
    // so a forecast/event update (which changes the trend not at all) doesn't
    // rebuild this whole dashboard.
    final hourTrend = context.select<HomeWeatherController, RainHourTrend?>(
      (controller) => controller.hourTrend,
    );
    // 所在地 with no GPS fix has no township to report on. The header already
    // says so; showing cards below it would only be rows of dashes and empty
    // feeds pretending to be readings for a place we could not identify.
    final located = area is! CurrentArea || area.code != null;
    final showWeather = area is! NationwideArea && located;
    // MediaQuery.paddingOf(context).bottom is *not* the device's real bottom
    // safe area in this subtree — MainShell's Scaffold(extendBody: true)
    // overrides it to the bottom-nav bar's reserved height, so this reads
    // straight off the platform view (see the original `_build` doc). Computed
    // once here, not per scroll tick.
    final bottomSafeArea = MediaQueryData.fromView(
      View.of(context),
    ).padding.bottom;
    // The sky re-bakes rarely; the scroll focus dial moves on every tick. The
    // ListView's *shell* rebuilds only when the sky changes — the scroll-driven
    // reveal/focus dial lives one level down, on the panel's own listenable,
    // so a scroll tick rebuilds the cards it changes instead of the whole list.
    return ListenableBuilder(
      listenable: SkyLutCache.panelAmbient,
      builder: (context, _) {
        final sky = SkyLutCache.panelAmbient.value;
        return _build(
          context,
          areaIndex,
          located,
          showWeather,
          sky,
          hourTrend,
          bottomSafeArea,
        );
      },
    );
  }

  /// Scroll distance over which the sheet's cards solidify out of their
  /// sky-glass panes back into solid plates — matched to
  /// `HomeSheet._ScrollBlurredWeather`'s own ramp so the backdrop dims and the
  /// cards turn opaque in the same swipe.
  static const double _focusRampExtent = 140;

  /// Focus dial for the content, `0` (resting) → `1` (scrolled past the hero).
  /// See [HomeContent._focusRampExtent].
  static double _focus(double offset) =>
      (offset / _focusRampExtent).clamp(0.0, 1.0);

  Widget _build(
    BuildContext context,
    int areaIndex,
    bool located,
    bool showWeather,
    Color? sky,
    RainHourTrend? hourTrend,
    double bottomSafeArea,
  ) {
    // A dry hour (empty `[]` response, or an all-zero series) hides the
    // rain-trend card entirely; the hero block's bottom slot is taken over by
    // a compact 24h forecast so the sheet still has a weather card to read at
    // rest. Null (still loading / failed) keeps the trend card's own pane.
    final dryTrend = hourTrend?.summary.grade == RainHourTrendGrade.none;
    // The hero block needs the sheet's own live pixel height, which only a
    // LayoutBuilder can give — MediaQuery reports the *screen*, not the
    // sheet's current size mid-expand. Null outside the hero layout
    // (collapsed, or nothing to anchor a hero to) doubles as the switch
    // between the header's two homes below, and as a fallback if the incoming
    // height is ever unbounded (nothing upstream does that today, but an
    // infinite SizedBox is a hard crash, not a bad-looking frame).
    //
    // heroHeight itself always fills the *entire* viewport (topInset to its
    // bottom edge) rather than stopping short of the safe area — the safe
    // area is reserved *inside* the block instead (see the Padding around
    // the hero Column below). Stopping short here, as an earlier version of
    // this did, left the block's declared bottom edge short of the screen's
    // own bottom edge, and whatever the *next* list item happened to be —
    // the AppSpacing.lg spacer before the forecast section, or the forecast
    // card itself once the spacer was too short to cover the gap — was free
    // to paint into that leftover strip. Filling the whole viewport here
    // guarantees nothing after the hero block is ever visible at rest,
    // regardless of how the safe area compares to that spacer's size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawHeight = constraints.maxHeight;
        final heroHeight = expanded && showWeather && rawHeight.isFinite
            ? _heroHeight(rawHeight)
            : null;
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topInset,
            AppSpacing.lg,
            AppSpacing.lg + bottomSafeArea,
          ),
          children: [
            Opacity(opacity: handleOpacity, child: const HomeSheetHandle()),
            // The grab handle above stays put; only the per-area panel slides.
            _AreaSlide(
              index: areaIndex,
              // The scroll focus dial drives every card's reveal and the hero
              // block's trailing reserve — one listenable, one builder — so a
              // scroll tick rebuilds this panel's cards rather than the whole
              // ListView shell around it (which rebuilds only when the sky
              // re-bakes, in [build]).
              child: ListenableBuilder(
                listenable: scrollController,
                builder: (context, _) {
                  final offset = scrollController.hasClients
                      ? scrollController.offset
                      : 0.0;
                  // The cards read as a pane of the sky only while the sky is
                  // the point (hero showing). Once the list scrolls, they
                  // solidify back into solid plates and their ink back onto
                  // the theme surface — a transparent 20 % sky-pane with
                  // sky-tuned ink is exactly what makes scrolled content hard
                  // to read, no matter how dimmed the backdrop behind it is.
                  final reveal = this.reveal * (1 - _focus(offset));
                  return Column(
                    key: ValueKey(areaIndex),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (heroHeight != null)
                        SizedBox(
                          height: heroHeight,
                          // Only the trailing gap depends on scroll offset, so
                          // that is all this block's Padding re-reads per tick.
                          child: Padding(
                            // Deflates the tight SizedBox height so the Expanded
                            // gap between header and trend card shrinks by exactly
                            // this much and heroHeight itself — and with it the
                            // forecast/events fold below — never moves. Collapses
                            // to 0 as the sheet scrolls — see
                            // [_bottomGapRampExtent] on why that includes the
                            // safe area, not just the nicety gap on top of it.
                            padding: EdgeInsets.only(
                              bottom: _heroBottomGap(offset, bottomSafeArea),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RainOnCard(
                                  // Text and icons, not a solid card face — a
                                  // flat top-edge collision would pool water in
                                  // every gap between glyphs. Silhouette
                                  // rasterises the header itself and catches drops
                                  // on its actual outline instead.
                                  //
                                  // Not gated — see [RainOnCard.gated]. The gate
                                  // closes once the card has risen [_gateCloseDistance]
                                  // above where it settled, which is exactly what
                                  // pulling the sheet up does to this header: it
                                  // starts most of a screen down (rest detent) and
                                  // rides up with the drag. Gating it there would
                                  // cut the header's water off the moment the sheet
                                  // is dragged, and the low-water mark ([_restTopY])
                                  // pins it shut afterwards. The surrounding scroll
                                  // view culls its paint once it truly scrolls out.
                                  intensity: _cardRain(weatherMode),
                                  opacity: reveal,
                                  glass: false,
                                  silhouette: true,
                                  gated: false,
                                  child: HomeSheetHeader(
                                    reveal: reveal,
                                    expanded: expanded,
                                    weatherMode: weatherMode,
                                    sky: sky,
                                  ),
                                ),
                                // The gap is the point — open sky between the two
                                // fixed edges, not a forgotten card. `HomeSheet`
                                // blurs it back in once the scroll below carries
                                // the trend card past the top.
                                const Expanded(child: SizedBox.shrink()),
                                if (dryTrend)
                                  // A dry hour has no rain chart, so the forecast
                                  // card itself takes the hero slot — a one-glance
                                  // summary (title + hour chips) at rest that
                                  // grows into the full card as the sheet is
                                  // pulled up, and rains on the card like the
                                  // trend card does.
                                  RainOnCard(
                                    intensity: _cardRain(weatherMode),
                                    opacity: reveal,
                                    child: HomeForecastSection(
                                      key: ValueKey('forecast-hero-$areaIndex'),
                                      expansion: _forecastExpansion(offset),
                                      reveal: reveal,
                                      sky: sky,
                                      weatherMode: weatherMode,
                                    ),
                                  )
                                else
                                  HomeRainTrendSection(
                                    key: ValueKey('rain-$areaIndex'),
                                    reveal: reveal,
                                    sky: sky,
                                    weatherMode: weatherMode,
                                    // Only this card gets wet. The reference rains
                                    // on the card, not the page, and the effect
                                    // belongs on the one block that is *about*
                                    // rain. The grade is the weather's; [reveal]
                                    // gates visibility separately inside the
                                    // section, the way the engine's scene alpha
                                    // does — multiplying them together washed the
                                    // water down to a third of its opacity.
                                    rain: _cardRain(weatherMode),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        HomeSheetHeader(
                          reveal: reveal,
                          expanded: expanded,
                          weatherMode: weatherMode,
                          sky: sky,
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      // Collapsed, or nothing to anchor a hero to: active events
                      // only. Full-screen township: the hero above, then forecast
                      // → events reached by scrolling past it. 全國: events only
                      // (no point weather). A dry hour carries its one forecast
                      // card in the hero itself, so nothing repeats below the fold.
                      if (heroHeight != null && !dryTrend) ...[
                        HomeForecastSection(
                          key: ValueKey('forecast-$areaIndex'),
                          reveal: reveal,
                          sky: sky,
                          weatherMode: weatherMode,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (located)
                        HomeActiveEventsSection(
                          key: ValueKey('active-$areaIndex'),
                          reveal: reveal,
                          expanded: expanded,
                          sky: sky,
                          weatherMode: weatherMode,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Height of the hero block (header + open sky + rain trend card): the
  /// entire viewport below [topInset]. [viewportHeight] is the sheet's live
  /// pixel height from the [LayoutBuilder] in [_build], not derived from
  /// [MediaQuery] — the sheet is mid-expand (not yet at the screen's full
  /// height) for the first several frames after [expanded] turns true, and
  /// this has to track that, not the eventual rest state.
  ///
  /// Deliberately fills the whole viewport rather than stopping short of the
  /// safe area — see [_build]'s comment on why the safe area is reserved
  /// *inside* the block instead of by shrinking this.
  ///
  /// Floored at 0 only as a degenerate-constraint guard. On every device this
  /// app ships to, the header and trend card together are a fraction of a
  /// screen's height, so the clamp never actually decides the block's size —
  /// it exists so a pathological constraint shrinks the gap to nothing rather
  /// than handing [SizedBox] a negative height.
  double _heroHeight(double viewportHeight) {
    final height = viewportHeight - topInset;
    return height < 0 ? 0 : height;
  }

  /// Resting-state breathing room between the trend card's own bottom edge
  /// and the safe area below it, on top of the safe area itself, so the card
  /// doesn't read as glued to the very edge of the screen.
  static const double _restBottomGap = AppSpacing.xl;

  /// Scroll distance over which the hero block's *entire* trailing reserve —
  /// [_restBottomGap] and the safe area alike — collapses to 0. Short on
  /// purpose, same reasoning as `HomeSheet._ScrollBlurredWeather`'s own ramp:
  /// both are a resting-state concern, not something to keep paying for once
  /// the sheet is actually moving.
  ///
  /// The safe area has to ramp away too, not just stay as a fixed floor under
  /// [_restBottomGap] — it exists only because the trend card sits at the
  /// physical bottom of the screen *at rest*. The moment the list scrolls,
  /// the card is no longer there and nothing about the device's home
  /// indicator applies to it anymore; holding that reserve open regardless
  /// just leaves it as dead space between the trend card and the forecast
  /// card once scrolled — taller than [AppSpacing.lg], the gap every other
  /// pair of cards on the second page actually uses, and visibly
  /// inconsistent with them.
  static const double _bottomGapRampExtent = 32;

  /// Current size of the hero block's trailing reserve — [_restBottomGap]
  /// plus [bottomSafeArea] — for the live scroll [offset].
  static double _heroBottomGap(double offset, double bottomSafeArea) {
    final rest = _restBottomGap + bottomSafeArea;
    final t = (offset / _bottomGapRampExtent).clamp(0.0, 1.0);
    return rest * (1 - t);
  }

  /// Scroll distance over which the hero's forecast card grows from its
  /// one-glance summary (title + hour chips) to the full card (sparkline +
  /// detail band). Independent of the shorter resting-state ramps around it —
  /// this one is the *point* of the gesture on a dry hour, so it deserves the
  /// distance.
  static const double _forecastExpandExtent = 200;

  /// Current growth of the hero forecast card for [offset].
  static double _forecastExpansion(double offset) =>
      (offset / _forecastExpandExtent).clamp(0.0, 1.0);

  /// How wet the rain-trend card gets for a given backdrop.
  ///
  /// These are positions on the reference's own weather-type ladder, not a free dial.
  /// Both effects switch whole parameter sets by the weather-type enum,
  /// and the ladder is counter-intuitive: **lighter rain means smaller, denser
  /// beads and sparser edge water**. DPIP's plain rain backdrop is the
  /// light-rain end of that ladder — which is what the shipped light-rain
  /// capture shows — and only thunderstorm reaches the downpour band. Sitting
  /// rain in the middle, as an earlier version did, gave it beads the reference keeps
  /// for a storm and an edge-water band the reference never shows at that grade.
  static double _cardRain(WeatherMode mode) => switch (mode) {
    WeatherMode.rain => 0.3,
    WeatherMode.thunderstorm => 0.85,
    _ => 0.0,
  };
}

/// Slides its [child] in from the side when the area [index] changes, so a
/// switch reads as the whole panel moving (a horizontal shared-axis
/// transition): the incoming panel enters from the direction of travel while the
/// outgoing one leaves the opposite way.
///
/// Sits inside the sheet's [ListView] as a single child, so the list's scroll
/// controller is untouched by a switch. [StackFit.passthrough] hands the list's
/// tight-width constraint to both panels so their [Column] stretch resolves.
class _AreaSlide extends StatefulWidget {
  const _AreaSlide({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AreaSlide> createState() => _AreaSlideState();
}

class _AreaSlideState extends State<_AreaSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Captured in initState, not via `late … = widget.…`: a lazy initializer's
  // first read lands inside didUpdateWidget, after `widget` already advanced —
  // which would make `_index` adopt the new value and skip the transition.
  late Widget _current;
  Widget? _previous;
  late int _index;
  bool _forward = true;

  /// Where the outgoing panel starts sliding from (fraction of width). Normally
  /// 0 (centred); on an interrupted switch it's the still-entering panel's
  /// current position, so it continues smoothly instead of jumping to centre.
  double _outgoingStart = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.child;
    _index = widget.index;
    _controller = AnimationController(vsync: this, duration: AppMotion.medium)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _previous = null);
        }
      });
  }

  @override
  void didUpdateWidget(covariant _AreaSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _index) {
      // If a slide is still running, the current panel is mid-entry — hand the
      // outgoing panel its live position so it doesn't snap back to centre.
      final curved = Curves.easeInOutCubicEmphasized.transform(
        _controller.value,
      );
      _outgoingStart = _previous == null
          ? 0.0
          : (_forward ? 1.0 : -1.0) * (1 - curved);
      _forward = widget.index > _index;
      _index = widget.index;
      _previous = _current;
      _current = widget.child;
      _controller.forward(from: 0);
    } else {
      // A content-only rebuild (e.g. reveal changed) — no switch to animate.
      _current = widget.child;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_previous == null) return _current;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubicEmphasized.transform(_controller.value);
        final dir = _forward ? 1.0 : -1.0;
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.hardEdge,
          children: [
            // Incoming panel sizes the stack; it slides in from the travel side.
            FractionalTranslation(
              translation: Offset(dir * (1 - t), 0),
              child: _current,
            ),
            // Outgoing panel slides out the opposite way, continuing from
            // wherever it was if this switch interrupted one. Top-anchored (not
            // fill) so it keeps its own height — a taller outgoing panel just
            // clips as it leaves rather than overflowing.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FractionalTranslation(
                translation: Offset(lerpDouble(_outgoingStart, -dir, t)!, 0),
                child: _previous,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The grab handle shown at the top of the home sheet.
class HomeSheetHandle extends StatelessWidget {
  const HomeSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
