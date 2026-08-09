import 'dart:ui' show lerpDouble;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_forecast_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_rain_trend_section.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
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
    // 所在地 with no GPS fix has no township to report on. The header already
    // says so; showing cards below it would only be rows of dashes and empty
    // feeds pretending to be readings for a place we could not identify.
    final located = area is! CurrentArea || area.code != null;
    final showWeather = area is! NationwideArea && located;
    // One listener for the whole panel: the sky colour only changes when the
    // LUT re-bakes (a weather or time-slot change), and every card below tints
    // itself from the same value the way the reference samples one gradient stop for all
    // of them.
    return ValueListenableBuilder<Color?>(
      valueListenable: SkyLutCache.panelAmbient,
      builder: (context, sky, _) =>
          _build(context, areaIndex, located, showWeather, sky),
    );
  }

  Widget _build(
    BuildContext context,
    int areaIndex,
    bool located,
    bool showWeather,
    Color? sky,
  ) {
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
    //
    // MediaQuery.paddingOf(context).bottom is *not* the device's real bottom
    // safe area here: MainShell's Scaffold(extendBody: true) overrides it for
    // this whole subtree to the bottom-nav-bar's reserved height instead (114
    // logical px, measured on a real device — the bug that previously made
    // this leave a stray gap under the trend card). MediaQueryData.fromView
    // reads straight off the platform view, bypassing that override, and
    // gives back the one inset that's real in every state the hero block is
    // ever in: the home indicator.
    final bottomSafeArea = MediaQueryData.fromView(
      View.of(context),
    ).padding.bottom;
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
              child: Column(
                key: ValueKey(areaIndex),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (heroHeight != null)
                    SizedBox(
                      height: heroHeight,
                      // Only the trailing gap depends on scroll offset, so
                      // that's the only thing this rebuilds per tick — the
                      // header/trend-card subtree below is built once and
                      // handed through as ListenableBuilder's child, same
                      // split `HomeSheet`'s own `_ScrollBlurredWeather` uses.
                      child: ListenableBuilder(
                        listenable: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RainOnCard(
                              // Text and icons, not a solid card face — a flat
                              // top-edge collision would pool water in every
                              // gap between glyphs. Silhouette rasterises the
                              // header itself and catches drops on its actual
                              // outline instead.
                              intensity: _cardRain(weatherMode),
                              opacity: reveal,
                              glass: false,
                              silhouette: true,
                              // Default gated: true — the header rises with
                              // the rest of the hero block once the sheet
                              // scrolls, so it closes the same short distance
                              // into the gesture the trend card now does.
                              child: HomeSheetHeader(
                                reveal: reveal,
                                expanded: expanded,
                                weatherMode: weatherMode,
                                sky: sky,
                              ),
                            ),
                            // The gap is the point — open sky between the two
                            // fixed edges, not a forgotten card. `HomeSheet`
                            // blurs it back in once the scroll below carries the
                            // trend card past the top.
                            const Expanded(child: SizedBox.shrink()),
                            HomeRainTrendSection(
                              key: ValueKey('rain-$areaIndex'),
                              reveal: reveal,
                              sky: sky,
                              weatherMode: weatherMode,
                              // Only this card gets wet. The reference rains on the card, not the
                              // page, and the effect belongs on the one block that is
                              // *about* rain. The grade is the weather's; [reveal] gates
                              // visibility separately inside the section, the way the
                              // engine's scene alpha does — multiplying them together
                              // washed the water down to a third of its opacity.
                              rain: _cardRain(weatherMode),
                            ),
                          ],
                        ),
                        // Deflates the tight SizedBox height passed to the
                        // Column above, so the Expanded gap between header
                        // and trend card shrinks by exactly this much and
                        // heroHeight itself — and with it the forecast/events
                        // fold below — never moves. Collapses to 0 as the
                        // sheet scrolls — see [_bottomGapRampExtent] on why
                        // that includes the safe area, not just the nicety
                        // gap on top of it.
                        builder: (context, child) => Padding(
                          padding: EdgeInsets.only(
                            bottom: _heroBottomGap(
                              scrollController,
                              bottomSafeArea,
                            ),
                          ),
                          child: child,
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
                  // (no point weather).
                  if (heroHeight != null) ...[
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
  /// plus [bottomSafeArea] — for [controller]'s live scroll offset.
  static double _heroBottomGap(ScrollController controller, double bottomSafeArea) {
    final rest = _restBottomGap + bottomSafeArea;
    final offset = controller.hasClients ? controller.offset : 0.0;
    final t = (offset / _bottomGapRampExtent).clamp(0.0, 1.0);
    return rest * (1 - t);
  }

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
