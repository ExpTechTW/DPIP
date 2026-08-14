/// Lunar phase page — a photoreal procedural moon for any chosen date.
///
/// Everything here is computed locally: the phase comes from
/// `core/astro/moon_phase.dart` (a Meeus-series closed form, no ephemeris
/// table, no network), and the surface is the **real Moon** — NASA/GSFC's CGI
/// Moon Kit colour and elevation maps in `assets/astro/` (see the README
/// there). `shaders/weather/moon_display.frag` projects them onto a sphere and
/// lights them for the chosen date.
///
/// The maps are bundled rather than fetched on purpose: this is a
/// disaster-preparedness app, and a page that needs the network to draw the
/// Moon is a page that stops working on the night it would be most looked at.
///
/// The date axis is a daily timeline (today ± 14 days) scrubbed exactly like
/// the map's radar timeline — a fixed centre scrubber over a scrolling ruler.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/astro/moon_phase.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

/// Half a synodic month on each side of today — a full moon-to-moon arc with
/// the current phase centred, so scrubbing can reach the next full moon.
const int _daysBefore = 14;
const int _daysAfter = 14;

class MoonPage extends StatefulWidget {
  const MoonPage({super.key});

  @override
  State<MoonPage> createState() => _MoonPageState();
}

class _MoonPageState extends State<MoonPage> {
  /// Daily frames, today centred — built once; the page's only state is which
  /// day the scrubber sits on.
  late final List<MapFrame> _frames;

  /// The frame the page opens on (today).
  late int _selectedIndex;

  /// Phase angle of the selected day, radians.
  late double _phase;

  /// Sub-earth point for the selected day — the Moon's libration, in radians.
  late Offset _libration;

  ui.FragmentProgram? _displayProgram;

  /// NASA colour and elevation maps, decoded once.
  ui.Image? _color;
  ui.Image? _height;
  Object? _loadError;

  static final DateFormat _monthDay = DateFormat('M/d');
  static final DateFormat _fullDate = DateFormat('yyyy/MM/dd');

  @override
  void initState() {
    super.initState();
    final today = AppTime.taipei(AppTime.utc);
    _frames = [
      for (var i = -_daysBefore; i <= _daysAfter; i++)
        MapFrame(
          id: 'moon$i',
          // The UTC instant of 00:00 Taiwan time on day [i].
          time: DateTime.utc(
            today.year,
            today.month,
            today.day,
          ).subtract(const Duration(hours: 8)).add(Duration(days: i)),
        ),
    ];
    _selectedIndex = _daysBefore;
    _phase = MoonPhase.at(_frames[_selectedIndex].time).angle;
    _libration = _librationOffset(_frames[_selectedIndex].time);
    unawaited(_load());
  }

  static Offset _librationOffset(DateTime utc) {
    final libration = MoonPhase.librationAt(utc);
    return Offset(libration.longitude, libration.latitude);
  }

  Future<void> _load() async {
    try {
      final display = await ui.FragmentProgram.fromAsset(
        'shaders/weather/moon_display.frag',
      );
      final color = await _decodeAsset('assets/astro/moon_color_2k.jpg');
      final height = await _decodeAsset('assets/astro/moon_height_1k.png');
      if (!mounted) {
        color.dispose();
        height.dispose();
        return;
      }
      setState(() {
        _displayProgram = display;
        _color = color;
        _height = height;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error);
    }
  }

  Future<ui.Image> _decodeAsset(String key) async {
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

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
      _phase = MoonPhase.at(_frames[index].time).angle;
      _libration = _librationOffset(_frames[index].time);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final phase = MoonPhase.at(_frames[_selectedIndex].time);
    final nextFull = MoonPhase.nextFullMoon(AppTime.utc);
    final nextFullDay = AppTime.taipei(nextFull);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moonTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _MoonDisc(
            color: _color,
            height: _height,
            displayProgram: _displayProgram,
            phase: _phase,
            libration: _libration,
            error: _loadError,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Column(
              children: [
                Text(
                  _phaseName(l10n, phase.name),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  // l10n-ignore: percentage readout
                  '${(phase.brightness * 100).round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _InfoItem(
                  label: l10n.moonAge,
                  value:
                      '${phase.ageInDays.toStringAsFixed(1)}'
                      // l10n-ignore: unit
                      ' ${l10n.moonDays}',
                ),
                const SizedBox(width: AppSpacing.lg),
                _InfoItem(
                  label: l10n.moonNextFullMoon,
                  value: _fullDate.format(nextFullDay),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: MapTimeline(
              frames: _frames,
              selectedIndex: _selectedIndex,
              onSelected: _select,
              caption: l10n.moonTimelineCaption,
              timeFormat: _monthDay,
              itemExtent: 26,
              framePeriod: const Duration(days: 1),
            ),
          ),
        ],
      ),
    );
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

/// The moon disc on a deep-space backdrop. The bake is synchronous but
/// one-shot (during shader load); once the texture exists every frame is just
/// a shader draw with the phase uniform.
class _MoonDisc extends StatelessWidget {
  const _MoonDisc({
    required this.color,
    required this.height,
    required this.displayProgram,
    required this.phase,
    required this.libration,
    required this.error,
  });

  final ui.Image? color;
  final ui.Image? height;
  final ui.FragmentProgram? displayProgram;
  final double phase;
  final Offset libration;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 340,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Color(0xFF141B33), Color(0xFF05070F)],
        ),
      ),
      child: Center(
        child: switch ((color, height, displayProgram, error)) {
          (final ui.Image c, final ui.Image h, final ui.FragmentProgram p, _) =>
            CustomPaint(
              size: const Size.square(300),
              painter: _MoonPainter(
                display: p.fragmentShader(),
                color: c,
                height: h,
                phase: phase,
                libration: libration,
              ),
            ),
          (_, _, _, final Object e) => Text(
            // l10n-ignore: shader failure is a developer error
            'moon shader: $e',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          _ => const SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        },
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter({
    required this.display,
    required this.color,
    required this.height,
    required this.phase,
    required this.libration,
  });

  final ui.FragmentShader display;
  final ui.Image color;
  final ui.Image height;

  /// Sub-earth point offset in radians — the Moon's monthly rocking.
  final Offset libration;

  /// Phase angle in radians — the only thing that changes between frames.
  final double phase;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    display.setFloat(0, size.width);
    display.setFloat(1, size.height);
    display.setFloat(2, phase);
    display.setFloat(3, libration.dx);
    display.setFloat(4, libration.dy);
    display.setImageSampler(0, color);
    display.setImageSampler(1, height);
    canvas.drawRect(Offset.zero & size, Paint()..shader = display);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      libration != oldDelegate.libration ||
      color != oldDelegate.color ||
      height != oldDelegate.height ||
      !identical(display, oldDelegate.display);
}

/// Label + value pair under the disc.
class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
