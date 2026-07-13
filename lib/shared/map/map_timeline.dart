import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A horizontal, scrubbable timeline over a layer's [frames].
///
/// A ruler of ticks scrolls under a fixed centre scrubber; whichever frame sits
/// under the scrubber is the selection. Dragging updates the big time label
/// live and, on release, snaps to the nearest frame and reports it via
/// [onSelected] (so the map re-renders only when scrubbing settles, not every
/// frame). The newest frame is labelled "now".
///
/// Stateless about the map — it only turns [frames] + [selectedIndex] into a
/// scrub gesture, so `MapScaffold` can drive any layer's frames through it.
class MapTimeline extends StatefulWidget {
  const MapTimeline({
    super.key,
    required this.frames,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Frames in chronological order (oldest first); must be non-empty.
  final List<MapFrame> frames;

  /// Index into [frames] currently under the scrubber.
  final int selectedIndex;

  /// Called with the newly-centred index when a scrub settles.
  final ValueChanged<int> onSelected;

  @override
  State<MapTimeline> createState() => _MapTimelineState();
}

class _MapTimelineState extends State<MapTimeline> {
  final DateFormat _time = DateFormat('HH:mm');
  // Numeric so no locale symbol data is needed (as with [_time]).
  final DateFormat _date = DateFormat('yyyy/MM/dd');

  /// Slot width per frame — the scroll offset that centres frame `i` is
  /// `i * _slotWidth` (the leading/trailing pads are symmetric).
  static const double _slotWidth = 14;
  static const double _rulerHeight = 48;

  /// Seeded so the first paint already sits on the selected frame (no flash),
  /// since `i * _slotWidth` centres frame `i`.
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.selectedIndex * _slotWidth,
  );

  /// The frame under the scrubber right now — follows the live scroll so the
  /// label tracks the drag before it settles.
  late int _liveIndex = widget.selectedIndex;
  bool _snapping = false;

  @override
  void didUpdateWidget(covariant MapTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-centre on an external change (a new layer's frames, or a jump-to-now)
    // but not on the echo of our own onSelected, which already matches.
    final framesChanged = !identical(oldWidget.frames, widget.frames);
    if (framesChanged || (widget.selectedIndex != _liveIndex && !_snapping)) {
      _liveIndex = widget.selectedIndex.clamp(0, widget.frames.length - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centreOn(_liveIndex, animate: false);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int get _centredIndex =>
      (_scroll.offset / _slotWidth).round().clamp(0, widget.frames.length - 1);

  void _centreOn(int index, {required bool animate}) {
    if (!_scroll.hasClients) return;
    final target = (index * _slotWidth).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if ((_scroll.offset - target).abs() < 0.5) return;
    if (animate) {
      _snapping = true;
      _scroll
          .animateTo(target, duration: AppMotion.fast, curve: Curves.easeOut)
          .whenComplete(() {
            if (mounted) _snapping = false;
          });
    } else {
      _scroll.jumpTo(target);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (!_scroll.hasClients) return false;
    final centred = _centredIndex;
    if (notification is ScrollUpdateNotification) {
      if (centred != _liveIndex) {
        setState(() => _liveIndex = centred);
        // Report every frame the scrubber crosses, not just the final one, so
        // the map animates through the loop as you drag.
        if (widget.selectedIndex != centred) widget.onSelected(centred);
      }
    } else if (notification is ScrollEndNotification && !_snapping) {
      if (widget.selectedIndex != centred) widget.onSelected(centred);
      _centreOn(centred, animate: true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isNow = _liveIndex == widget.frames.length - 1;
    final labelStep = (48 / _slotWidth).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left: 觀測 (label) over the selected date; right: the big time
        // ("now" when the newest frame is under the scrubber). FittedBox keeps
        // the row on one line on narrow screens instead of overflowing.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.mapTimelineObserved,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _date.format(widget.frames[_liveIndex].time),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (isNow) ...[
                    Text(
                      l10n.mapTimelineNow,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    _time.format(widget.frames[_liveIndex].time),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: _rulerHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final pad = (constraints.maxWidth - _slotWidth) / 2;
                  // ListView.builder (not a Row) so a week of frames only ever
                  // builds the ~dozens of ticks on screen. itemExtent keeps the
                  // centring math: offset `i * _slotWidth` centres frame `i`.
                  return NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: ListView.builder(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const _ScrubPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemExtent: _slotWidth,
                      itemCount: widget.frames.length,
                      itemBuilder: (context, i) => _Tick(
                        width: _slotWidth,
                        label: i % labelStep == 0
                            ? _time.format(widget.frames[i].time)
                            : null,
                        emphasised: i == _liveIndex,
                        colors: colors,
                        textStyle: theme.textTheme.labelSmall,
                      ),
                    ),
                  );
                },
              ),
              // Fixed centre scrubber.
              IgnorePointer(
                child: Container(
                  width: 2.5,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One ruler tick — a mark plus an optional time [label] beneath it.
class _Tick extends StatelessWidget {
  const _Tick({
    required this.width,
    required this.label,
    required this.emphasised,
    required this.colors,
    required this.textStyle,
  });

  final double width;
  final String? label;
  final bool emphasised;
  final ColorScheme colors;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final tickColor = emphasised ? colors.primary : colors.outlineVariant;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: label != null ? 1.5 : 1,
            height: label != null ? 16 : 10,
            color: tickColor,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Reserve the label row on every tick so heights line up; the label
          // itself is allowed to overflow its slot and centre on the tick.
          SizedBox(
            height: 14,
            child: label == null
                ? null
                : OverflowBox(
                    maxWidth: double.infinity,
                    child: Text(
                      label!,
                      maxLines: 1,
                      softWrap: false,
                      style: textStyle?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Scroll physics for the timeline ruler: caps a hard fling's speed and damps
/// it, so a fast swipe eases through the loop and slows to a stop instead of
/// blurring past. (The finger-drag itself is 1:1; this only shapes the fling.)
class _ScrubPhysics extends ClampingScrollPhysics {
  const _ScrubPhysics({super.parent});

  /// Peak fling speed (px/s) — a hard swipe is clamped to this.
  static const double _maxFlingVelocity = 2000;

  /// Fraction of the (capped) fling velocity actually used, so a fling sheds
  /// speed sooner and settles quickly.
  static const double _damping = 0.6;

  @override
  _ScrubPhysics applyTo(ScrollPhysics? ancestor) =>
      _ScrubPhysics(parent: buildParent(ancestor));

  @override
  double get maxFlingVelocity => _maxFlingVelocity;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final capped = velocity.clamp(-_maxFlingVelocity, _maxFlingVelocity);
    return super.createBallisticSimulation(position, capped * _damping);
  }
}
