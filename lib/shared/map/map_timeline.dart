import 'dart:async';

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A horizontal, scrubbable timeline over a layer's [frames].
///
/// A ruler of ticks scrolls under a fixed centre scrubber; whichever frame sits
/// under the scrubber is the selection. Dragging updates the big time label
/// live and reports each crossed frame via [onSelected]. [onScrubbing] is true
/// while the finger is down / the fling is in flight and false on settle — raster
/// layers use that to opacity-GIF among residents without mounting cold frames.
/// The frame labelled "now" is the newest one at or before the present — the
/// last frame for observed data, and the latest already-due step of a forecast.
/// Forecast steps after it are "future", never presented as current.
///
/// Stateless about the map — it only turns [frames] + [selectedIndex] into a
/// scrub gesture, so `MapScaffold` can drive any layer's frames through it.
class MapTimeline extends StatefulWidget {
  const MapTimeline({
    super.key,
    required this.frames,
    required this.selectedIndex,
    required this.onSelected,
    this.onScrubbing,
    this.caption,
    this.framePeriod,
    this.dataTime,
    this.timeFormat,
    this.itemExtent = _defaultSlotWidth,
  });

  /// Frames in chronological order (oldest first); must be non-empty.
  final List<MapFrame> frames;

  /// Index into [frames] currently under the scrubber.
  final int selectedIndex;

  /// Called with the newly-centred index when the scrubber crosses a frame.
  final ValueChanged<int> onSelected;

  /// `true` on scrub start / during drag; `false` when the scrub settles.
  final ValueChanged<bool>? onScrubbing;

  /// What the frame times are, shown above the date — "observed" by default,
  /// "forecast" for a forecast layer.
  final String? caption;

  /// Tick / big-label time format — defaults to HH:mm. A daily timeline (e.g.
  /// lunar phases) passes `M/d` so the ruler reads dates instead of a clock.
  final DateFormat? timeFormat;

  /// Slot width per frame — the scroll offset that centres frame `i` is
  /// `i * itemExtent` (the leading/trailing pads are symmetric). Radar frames
  /// sit 14 px apart; a daily timeline needs a wider slot to stay draggable.
  final double itemExtent;

  /// Default frame slot width.
  static const double _defaultSlotWidth = 14;

  /// How long one frame's data represents, when it is a period rather than a
  /// point. A next-hour forecast's frame at 21:00 covers 21:00–22:00, so the
  /// big time label renders that range instead of a bare instant. `null` keeps
  /// the point-in-time label.
  final Duration? framePeriod;

  /// When the frames behind this timeline were produced — a forecast model
  /// run's issue time (資料時間), distinct from the valid times the ruler
  /// scrubs. `null` hides the data-time line.
  final DateTime? dataTime;

  @override
  State<MapTimeline> createState() => _MapTimelineState();
}

class _MapTimelineState extends State<MapTimeline> {
  static final DateFormat _time = DateFormat('HH:mm');
  // Numeric so no locale symbol data is needed (as with [_time]).
  static final DateFormat _date = DateFormat('yyyy/MM/dd');
  // The data-time line: the model run's issue time, `8/11 14:00`.
  static final DateFormat _data = DateFormat('M/d HH:mm');

  static const double _rulerHeight = 48;

  /// A finger can land, start the 150 ms tick-alignment snap, and touch down
  /// again immediately. Reporting every intervening `ScrollEnd` as settled
  /// makes the map mount a new raster ring for each short stroke. Wait for a
  /// brief input-quiet window so a burst has one final cold load.
  static const Duration _settleQuietPeriod = Duration(milliseconds: 120);

  /// Formatted labels per frame, built once per frame set.
  ///
  /// A scrub rebuilds this widget for every frame the finger crosses, and each
  /// rebuild lays out the whole visible ruler. Formatting dates in `build`
  /// re-ran `DateFormat` for every on-screen tick on every one of those frames —
  /// pure repeat work, since a frame's label never changes.
  List<String> _times = const [];
  List<String> _dates = const [];

  void _cacheLabels() {
    final format = widget.timeFormat ?? _time;
    // A frame's [DateTime] may be minted in UTC (server timestamps, moon
    // instants) or in local time — either way it expresses the same instant,
    // and the ruler must read in the caller's local time, not in the UTC
    // representation a `isUtc: true` value would print verbatim. toLocal is
    // the identity for a local DateTime and the conversion for a UTC one.
    _times = [
      for (final frame in widget.frames) format.format(frame.time.toLocal()),
    ];
    _dates = [
      for (final frame in widget.frames) _date.format(frame.time.toLocal()),
    ];
  }

  /// The big time label: the selected instant, or — when the layer's frames
  /// each cover a period — the range that instant starts, so "21:00" is read
  /// as "21:00–22:00" rather than a point measurement.
  String get _bigLabel {
    final start = _times[_liveIndex];
    final period = widget.framePeriod;
    if (period == null) return start;
    final end = _time.format(
      widget.frames[_liveIndex].time.toLocal().add(period),
    );
    return '$start – $end';
  }

  @override
  void initState() {
    super.initState();
    _cacheLabels();
  }

  /// Seeded so the first paint already sits on the selected frame (no flash),
  /// since `i * itemExtent` centres frame `i`.
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.selectedIndex * widget.itemExtent,
  );

  /// The frame under the scrubber right now — follows the live scroll so the
  /// label tracks the drag before it settles.
  late int _liveIndex = widget.selectedIndex;
  bool _snapping = false;
  bool _scrubbing = false;
  int _snapGeneration = 0;
  Timer? _settleTimer;

  void _setScrubbing(bool value) {
    if (value) {
      _settleTimer?.cancel();
      _settleTimer = null;
    }
    if (_scrubbing == value) return;
    _scrubbing = value;
    widget.onScrubbing?.call(value);
  }

  void _scheduleSettled() {
    _settleTimer?.cancel();
    _settleTimer = Timer(_settleQuietPeriod, () {
      _settleTimer = null;
      if (mounted) _setScrubbing(false);
    });
  }

  @override
  void didUpdateWidget(covariant MapTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-centre on an external change (a new layer's frames, or a jump-to-now)
    // but not on the echo of our own onSelected, which already matches.
    final framesChanged = !identical(oldWidget.frames, widget.frames);
    if (framesChanged) _cacheLabels();
    if (framesChanged || (widget.selectedIndex != _liveIndex && !_snapping)) {
      _liveIndex = widget.selectedIndex.clamp(0, widget.frames.length - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centreOn(_liveIndex, animate: false);
      });
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _snapGeneration++;
    _scroll.dispose();
    super.dispose();
  }

  int get _centredIndex => (_scroll.offset / widget.itemExtent).round().clamp(
    0,
    widget.frames.length - 1,
  );

  void _centreOn(int index, {required bool animate}) {
    if (!_scroll.hasClients) return;
    final target = (index * widget.itemExtent).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    if ((_scroll.offset - target).abs() < 0.5) return;
    if (animate) {
      final generation = ++_snapGeneration;
      _snapping = true;
      _scroll
          .animateTo(target, duration: AppMotion.fast, curve: Curves.easeOut)
          .whenComplete(() {
            if (mounted && generation == _snapGeneration) _snapping = false;
          });
    } else {
      _snapGeneration++;
      _snapping = false;
      _scroll.jumpTo(target);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (!_scroll.hasClients) return false;
    final centred = _centredIndex;
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        // A real finger interrupts any driven snap. Its completion future may
        // still run, so invalidate that generation as well as the flag.
        _snapGeneration++;
        _snapping = false;
        _setScrubbing(true);
      } else if (!_snapping) {
        // Ballistic motion belongs to the gesture; a driven alignment snap
        // does not restart or cancel its quiet-period timer.
        _setScrubbing(true);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (!_snapping) _setScrubbing(true);
      if (centred != _liveIndex) {
        setState(() => _liveIndex = centred);
        // Compare against [_liveIndex] (before the update), never
        // [widget.selectedIndex]: the parent keeps that prop stale on purpose
        // (no setState during scrub). Guarding on the prop stuck the map on
        // now−1 when sliding back to the initial frame.
        widget.onSelected(centred);
      }
    } else if (notification is ScrollEndNotification && !_snapping) {
      if (centred != _liveIndex) {
        setState(() => _liveIndex = centred);
        widget.onSelected(centred);
      }
      _centreOn(centred, animate: true);
      _scheduleSettled();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Asked of the calibrated clock rather than of the list, so a forecast's
    // "現在" lands on the present rather than on its furthest step — and the
    // clock resyncs on foreground, so returning from the background moves the
    // marker to the real now instead of the device clock's guess.
    final nowIndex = nowFrameIndex(widget.frames, now: AppTime.utc);
    final era = _eraOf(_liveIndex, nowIndex);
    final labelStep = (48 / widget.itemExtent).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left: 觀測 (label) over the selected date; right: the big time with
        // its era label (現在/歷史/未來) + HH:mm. FittedBox keeps the row on
        // one line on narrow screens instead of overflowing.
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
                    widget.caption ?? l10n.mapTimelineObserved,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.dataTime case final dataTime?)
                    Text(
                      l10n.mapTimelineDataTime(_data.format(dataTime)),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.tertiary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  Text(
                    _dates[_liveIndex],
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
                  Text(
                    switch (era) {
                      TimelineEra.past => l10n.mapTimelinePast,
                      TimelineEra.now => l10n.mapTimelineNow,
                      TimelineEra.future => l10n.mapTimelineFuture,
                    },
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _eraColor(era, theme.brightness),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _bigLabel,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: _eraColor(era, theme.brightness),
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
                  final pad = (constraints.maxWidth - widget.itemExtent) / 2;
                  // ListView.builder (not a Row) so a week of frames only ever
                  // builds the ~dozens of ticks on screen. itemExtent keeps the
                  // centring math: offset `i * itemExtent` centres frame `i`.
                  return NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: ListView.builder(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      physics: const _ScrubPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemExtent: widget.itemExtent,
                      itemCount: widget.frames.length,
                      itemBuilder: (context, i) => _Tick(
                        width: widget.itemExtent,
                        label: i % labelStep == 0 ? _times[i] : null,
                        labelColor: _eraColor(
                          _eraOf(i, nowIndex),
                          theme.brightness,
                        ),
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

/// Which side of the present a frame sits on.
enum TimelineEra { past, now, future }

TimelineEra _eraOf(int index, int nowIndex) =>
    switch (index.compareTo(nowIndex)) {
      -1 => TimelineEra.past,
      0 => TimelineEra.now,
      _ => TimelineEra.future,
    };

/// The era colours, one pair per brightness so each reads on both themes.
///
/// The hues are fixed (not theme roles) because they are the semantics: 歷史
/// blue, 現在 green, 未來 purple — a dark surface gets the lighter shade of the
/// same hue, a light surface the deeper one.
///
/// Blue/green/purple is exactly the triple a deficient eye flattens, so each
/// literal is routed through `.vision` at its definition. That transform is not
/// a compile-time constant, hence getters rather than `const`.
Color get _pastLight => const Color(0xFF1565C0).vision;
Color get _pastDark => const Color(0xFF64B5F6).vision;
Color get _nowLight => const Color(0xFF2E7D32).vision;
Color get _nowDark => const Color(0xFF81C784).vision;
Color get _futureLight => const Color(0xFF7B1FA2).vision;
Color get _futureDark => const Color(0xFFBA68C8).vision;

Color _eraColor(TimelineEra era, Brightness brightness) => switch (era) {
  TimelineEra.past => brightness == Brightness.dark ? _pastDark : _pastLight,
  TimelineEra.now => brightness == Brightness.dark ? _nowDark : _nowLight,
  TimelineEra.future =>
    brightness == Brightness.dark ? _futureDark : _futureLight,
};

/// One ruler tick — a mark plus an optional time [label] beneath it.
class _Tick extends StatelessWidget {
  const _Tick({
    required this.width,
    required this.label,
    required this.labelColor,
    required this.emphasised,
    required this.colors,
    required this.textStyle,
  });

  final double width;
  final String? label;
  final Color labelColor;
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
                      style: textStyle?.copyWith(color: labelColor),
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
