/// The Moon, for any moment you scrub to.
///
/// Everything is computed on the device. The position comes from
/// `core/astro/moon_ephemeris.dart` — one Meeus series, pinned against JPL
/// Horizons and the USNO — and the surface is the real Moon: NASA/GSFC's CGI
/// Moon Kit colour and elevation maps in `assets/astro/`, projected onto a
/// sphere and lit for the chosen instant by
/// `shaders/weather/moon_display.frag`.
///
/// The maps are bundled rather than fetched on purpose: this is a
/// disaster-preparedness app, and a page that needs the network to draw the
/// Moon is a page that stops working on the night it would most be looked at.
///
/// Two controls, because the Moon has two timescales. The **timeline** steps
/// two hours — the resolution at which the terminator visibly moves and the
/// rise/set times shift — and the **calendar** steps a month, showing the
/// whole lunation as a shape. They drive the same selection, so neither can
/// point somewhere the other cannot reach.
///
/// Rise and set are for a place, so the page says which: the current township
/// when location is available, otherwise the nearest township to a documented
/// fallback, named either way rather than silently assumed.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/moon_orientation.dart';
import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/astro/moon_rise_set.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/data/presentation/widgets/moon_calendar.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Taiwan's fixed offset — the wall clock every date on this page is read in.
const Duration _taiwanOffset = Duration(hours: 8);

/// Where the timeline starts and stops, either side of today. A full lunation
/// each way, so any phase is always reachable by scrubbing alone.
const int _daysEitherSide = 31;

/// Timeline resolution. The Moon's elongation gains about half a degree an
/// hour, so two hours is roughly one degree — the coarsest step at which
/// consecutive frames still look different.
const int _stepHours = 2;

/// Used only when no township is known. Taipei City Hall; resolved through the
/// directory so the page names a real township rather than a coordinate.
const ({double lat, double lng}) _fallbackPlace = (lat: 25.0330, lng: 121.5654);

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  /// Two-hourly frames spanning [_daysEitherSide] either side of today, built
  /// once. The page's only real state is which one is selected.
  late final List<MapFrame> _frames;
  late final int _nowIndex;

  late int _selectedIndex;

  /// The month the calendar is showing — follows the selection, but can also
  /// be paged on its own without moving it.
  late DateTime _visibleMonth;

  ui.FragmentProgram? _program;
  ui.Image? _color;
  ui.Image? _height;
  Object? _loadError;

  // Numeric formats only, so no `intl` locale symbol data is needed.
  static final DateFormat _dayMonth = DateFormat('M/d');
  static final DateFormat _clock = DateFormat('HH:mm');
  static final NumberFormat _grouped = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    final now = AppTime.utc;
    final today = AppTime.taipei(now);
    // Midnight Taiwan time, [_daysEitherSide] back, as a UTC instant.
    final start = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(_taiwanOffset).subtract(const Duration(days: _daysEitherSide));
    const count = (2 * _daysEitherSide * 24) ~/ _stepHours + 1;
    _frames = [
      for (var i = 0; i < count; i++)
        MapFrame(
          id: 'moon$i',
          time: start.add(Duration(hours: i * _stepHours)),
        ),
    ];
    _nowIndex = _indexAt(now);
    _selectedIndex = _nowIndex;
    _visibleMonth = today;
    unawaited(_load());
  }

  /// The frame at or just before [utc], clamped to the range.
  int _indexAt(DateTime utc) {
    final steps =
        utc.difference(_frames.first.time).inMinutes ~/ (_stepHours * 60);
    return steps.clamp(0, _frames.length - 1);
  }

  DateTime get _selected => _frames[_selectedIndex].time;

  /// The selected instant as Taipei wall time.
  DateTime get _selectedLocal => AppTime.taipei(_selected);

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/weather/moon_display.frag',
      );
      final color = await _decode('assets/astro/moon_color_2k.jpg');
      final height = await _decode('assets/astro/moon_height_1k.png');
      if (!mounted) {
        color.dispose();
        height.dispose();
        return;
      }
      setState(() {
        _program = program;
        _color = color;
        _height = height;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<ui.Image> _decode(String key) async {
    final data = await rootBundle.load(key);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  void dispose() {
    _color?.dispose();
    _height?.dispose();
    super.dispose();
  }

  void _select(int index) => setState(() {
    _selectedIndex = index;
    _visibleMonth = AppTime.taipei(_frames[index].time);
  });

  /// Jumps to [day] (Taipei wall time) keeping the time of day, so stepping
  /// through the calendar compares like with like.
  void _selectDay(DateTime day) {
    final local = _selectedLocal;
    final target = DateTime.utc(
      day.year,
      day.month,
      day.day,
      local.hour,
    ).subtract(_taiwanOffset);
    _select(_indexAt(target));
  }

  /// The township rise and set are computed for: the current GPS township, or
  /// the selected saved one, or the nearest to [_fallbackPlace].
  Town? _observer(BuildContext context) {
    final directory = context.read<TownDirectory>();
    final regions = context.watch<RegionStore>();
    final selected = regions.selected;
    final code = switch (selected) {
      SavedArea(:final code) => code,
      CurrentArea(:final code) => code,
      NationwideArea() => null,
    };
    return directory.byCode(code ?? regions.currentCode) ??
        directory.nearest(_fallbackPlace.lat, _fallbackPlace.lng);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = MoonPhase.at(_selected);
    final libration = MoonPhase.librationAt(_selected);
    final town = _observer(context);
    final local = _selectedLocal;
    final riseSet = town == null
        ? null
        : MoonRiseSet.of(
            DateTime.utc(
              local.year,
              local.month,
              local.day,
            ).subtract(_taiwanOffset),
            latitude: town.lat,
            longitude: town.lng,
          );
    final orientation = town == null
        ? null
        : MoonOrientation.at(
            _selected,
            latitude: town.lat,
            longitude: town.lng,
          );
    final aboveHorizon =
        town != null &&
        riseSet != null &&
        riseSet.isCircumpolar &&
        MoonRiseSet.aboveHorizon(
          _selected,
          latitude: town.lat,
          longitude: town.lng,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moonTitle),
        actions: [
          // Only once the selection has left the present. Deliberately an icon:
          // the timeline already writes "now" as the label for the current
          // frame, and two different "now"s on one screen read as one thing.
          if (_selectedIndex != _nowIndex)
            IconButton(
              onPressed: () => _select(_nowIndex),
              icon: const Icon(Icons.today_outlined),
              tooltip: l10n.moonNow,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _MoonStage(
            color: _color,
            height: _height,
            program: _program,
            error: _loadError,
            phase: phase,
            libration: Offset(libration.longitude, libration.latitude),
            orientation: orientation,
            title: _phaseName(l10n, phase.name),
            // l10n-ignore: percentage readout
            subtitle: '${(phase.brightness * 100).round()}%',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: MapTimeline(
              frames: _frames,
              selectedIndex: _selectedIndex,
              onSelected: _select,
              caption: l10n.moonTimelineCaption,
              itemExtent: 22,
            ),
          ),
          SectionHeader(l10n.moonSectionAppearance),
          _StatCard(
            rows: [
              (
                Icons.hourglass_bottom_outlined,
                l10n.moonAge,
                '${phase.ageInDays.toStringAsFixed(1)} ${l10n.moonDays}',
              ),
              (
                Icons.straighten_outlined,
                l10n.moonDistance,
                '${_grouped.format(phase.distanceKm.round())}'
                    ' ${l10n.moonKilometres}',
              ),
              (
                Icons.circle_outlined,
                l10n.moonApparentSize,
                // l10n-ignore: degree symbol
                '${phase.apparentDiameterDegrees.toStringAsFixed(3)}°',
              ),
            ],
          ),
          SectionHeader(
            l10n.moonSectionRiseSet,
            trailing: town == null
                ? null
                : Text(
                    town.fullName,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          _StatCard(
            rows: [
              (
                Icons.arrow_upward,
                l10n.moonRise,
                _eventLabel(l10n, riseSet?.rise, aboveHorizon: aboveHorizon),
              ),
              (
                Icons.arrow_downward,
                l10n.moonSet,
                _eventLabel(l10n, riseSet?.set, aboveHorizon: aboveHorizon),
              ),
            ],
          ),
          SectionHeader(l10n.moonSectionUpcoming),
          _StatCard(
            rows: [
              (
                Icons.brightness_1_outlined,
                l10n.moonNextFullMoon,
                _stamp(MoonPhase.nextFullMoon(_selected)),
              ),
              (
                Icons.brightness_3_outlined,
                l10n.moonNextNewMoon,
                _stamp(MoonPhase.nextNewMoon(_selected)),
              ),
            ],
          ),
          SectionHeader(l10n.moonSectionCalendar),
          _Card(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: MoonCalendar(
              month: _visibleMonth,
              selected: local,
              today: AppTime.utc8,
              firstDay: AppTime.taipei(_frames.first.time),
              lastDay: AppTime.taipei(_frames.last.time),
              onMonthChanged: (month) => setState(() => _visibleMonth = month),
              onDaySelected: _selectDay,
              phaseAt: (day) => MoonPhase.angleAt(
                DateTime.utc(
                  day.year,
                  day.month,
                  day.day,
                  12,
                ).subtract(_taiwanOffset),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `M/d HH:mm` in Taipei wall time — the form the rest of the page uses.
  String _stamp(DateTime utc) {
    final local = AppTime.taipei(utc);
    return '${_dayMonth.format(local)} ${_clock.format(local)}';
  }

  /// A rise or set time, or why there isn't one. A day with no moonrise is
  /// ordinary (the Moon slips ~50 minutes later daily), so it gets a real
  /// answer rather than a dash.
  String _eventLabel(
    AppLocalizations l10n,
    DateTime? event, {
    required bool aboveHorizon,
  }) {
    if (event != null) return _clock.format(AppTime.taipei(event));
    return aboveHorizon ? l10n.moonAlwaysUp : l10n.moonNoEvent;
  }

  String _phaseName(AppLocalizations l10n, MoonPhaseName name) =>
      switch (name) {
        MoonPhaseName.newMoon => l10n.moonPhaseNew,
        MoonPhaseName.waxingCrescent => l10n.moonPhaseWaxingCrescent,
        MoonPhaseName.firstQuarter => l10n.moonPhaseFirstQuarter,
        MoonPhaseName.waxingGibbous => l10n.moonPhaseWaxingGibbous,
        MoonPhaseName.fullMoon => l10n.moonPhaseFull,
        MoonPhaseName.waningGibbous => l10n.moonPhaseWaningGibbous,
        MoonPhaseName.lastQuarter => l10n.moonPhaseLastQuarter,
        MoonPhaseName.waningCrescent => l10n.moonPhaseWaningCrescent,
      };
}

/// The hero: the lit globe over deep space, with the phase named beneath it.
class _MoonStage extends StatelessWidget {
  const _MoonStage({
    required this.color,
    required this.height,
    required this.program,
    required this.error,
    required this.phase,
    required this.libration,
    required this.orientation,
    required this.title,
    required this.subtitle,
  });

  final ui.Image? color;
  final ui.Image? height;
  final ui.FragmentProgram? program;
  final Object? error;
  final MoonPhase phase;
  final Offset libration;

  /// How the globe is tilted for this observer — see `moon_orientation.dart`.
  /// Null before a place is known, in which case the canonical north-up,
  /// terminator-vertical view is drawn rather than a guessed one.
  final MoonOrientation? orientation;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Big enough to be the point of the page, capped so the readings under it
    // are still on screen on a short phone.
    final screen = MediaQuery.sizeOf(context);
    final stage = (screen.height * 0.42).clamp(300.0, 380.0);
    final disc = (stage * 0.62).clamp(180.0, 260.0);

    return SizedBox(
      height: stage,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.35),
                radius: 1.2,
                colors: [Color(0xFF16203D), Color(0xFF05070F)],
              ),
            ),
          ),
          CustomPaint(painter: const _StarfieldPainter()),
          // A halo that grows with the lit fraction — the sky around a full
          // moon really is washed out, and a new moon really does sit in the
          // dark. It also stops the disc from looking pasted on.
          Align(
            alignment: const Alignment(0, -0.26),
            child: IgnorePointer(
              child: Container(
                width: disc * 1.9,
                height: disc * 1.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16 * phase.brightness),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.26),
            child: switch ((color, height, program, error)) {
              (
                final ui.Image c,
                final ui.Image h,
                final ui.FragmentProgram p,
                _,
              ) =>
                CustomPaint(
                  size: Size.square(disc),
                  painter: _MoonPainter(
                    shader: p.fragmentShader(),
                    color: c,
                    height: h,
                    phase: phase.angle,
                    libration: libration,
                    // Canonical view until a place is known: pole up, lit
                    // limb to the right. A guessed tilt would look confident
                    // and be wrong.
                    northBearing: orientation?.northBearing ?? 0,
                    brightLimbBearing:
                        orientation?.brightLimbBearing ?? math.pi / 2,
                  ),
                ),
              (_, _, _, final Object e) => Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  // l10n-ignore: shader failure is a developer error
                  'moon shader: $e',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              _ => const SizedBox.square(
                dimension: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.xl,
            child: Column(
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed field of faint stars. Deterministic — a starfield that reshuffles
/// on every scrub frame reads as noise rather than as sky.
class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  /// A cheap integer hash, so the field needs no stored table and no `Random`.
  static double _unit(int seed) => ((seed * 2654435761) % 65536) / 65536;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 90; i++) {
      final x = _unit(i * 3 + 1) * size.width;
      final y = _unit(i * 7 + 2) * size.height;
      final brightness = _unit(i * 11 + 3);
      canvas.drawCircle(
        Offset(x, y),
        0.4 + brightness * 0.9,
        paint..color = Colors.white.withValues(alpha: 0.15 + brightness * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => false;
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter({
    required this.shader,
    required this.color,
    required this.height,
    required this.phase,
    required this.libration,
    required this.northBearing,
    required this.brightLimbBearing,
  });

  final ui.FragmentShader shader;
  final ui.Image color;
  final ui.Image height;

  /// Phase angle in radians — the only thing that changes between frames.
  final double phase;

  /// The selenographic point facing Earth — the Moon's monthly rocking.
  final Offset libration;

  /// Screen bearing of the Moon's north pole, and of the middle of its lit
  /// limb — what tilts the globe the way the observer actually sees it.
  final double northBearing;
  final double brightLimbBearing;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, phase);
    shader.setFloat(3, libration.dx);
    shader.setFloat(4, libration.dy);
    shader.setFloat(5, northBearing);
    shader.setFloat(6, brightLimbBearing);
    shader.setImageSampler(0, color);
    shader.setImageSampler(1, height);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      libration != oldDelegate.libration ||
      northBearing != oldDelegate.northBearing ||
      brightLimbBearing != oldDelegate.brightLimbBearing ||
      color != oldDelegate.color ||
      height != oldDelegate.height ||
      !identical(shader, oldDelegate.shader);
}

/// The page's one surface: an inset, rounded container. Every group on the
/// page sits in one, so the calendar reads as a peer of the readings rather
/// than as loose widgets after them.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.medium,
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// A grouped card of icon / label / value rows.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _Card(
      child: Column(
        children: [
          for (final (index, (icon, label, value)) in rows.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: AppSpacing.xxl + AppSpacing.md,
                color: colors.outlineVariant,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
