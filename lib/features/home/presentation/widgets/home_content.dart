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
/// Below the header: **active events** while collapsed; once flush full-screen
/// on a township, **rain trend** + **24h forecast**, then active events. 全國
/// skips weather entirely (name + events only); 所在地 with no GPS fix shows the
/// header's "can't locate you" notice **alone** — no cards at all.
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
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset,
        AppSpacing.lg,
        // Clear the bottom nav (the body extends behind it — extendBody).
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
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
              HomeSheetHeader(
                reveal: reveal,
                expanded: expanded,
                weatherMode: weatherMode,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Collapsed: active events. Full-screen township: rain → forecast
              // → events. 全國: events only (no point weather).
              if (expanded && showWeather) ...[
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
                const SizedBox(height: AppSpacing.lg),
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
