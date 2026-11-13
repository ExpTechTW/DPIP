/// Live phone seismometer.
///
/// Sampling runs while this page is on the data tab, the shell is the top
/// route, and the app is in the foreground. [SeismometerController.stop]
/// runs when any of those stops being true, and [SeismometerController.start]
/// runs again when they all hold. The state disposes the controller.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/seismometer/presentation/seismometer_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:material_ui/material_ui.dart';

const _absent = '\u2014';
const _intensitySize = 96.0;
const _sessionBadgeSize = 32.0;
const _traceHeight = 180.0;
const _traceStroke = 1.5;

/// Full-scale gal for a trace whose largest absolute sample is [peak].
///
/// The result is at least 1, then the next 1, 2 or 5 times a power of ten
/// at or above [peak], so every sample fits a tick the label can show.
@visibleForTesting
double seismometerTraceScale(double peak) {
  if (!peak.isFinite || peak <= 1) return 1;
  final exponent = (math.log(peak) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  final mantissa = peak / magnitude;
  final step = mantissa <= 1
      ? 1.0
      : mantissa <= 2
      ? 2.0
      : mantissa <= 5
      ? 5.0
      : 10.0;
  return step * magnitude;
}

/// Phone seismometer: instrumental intensity, a three-axis trace, and the
/// session peaks.
class SeismometerPage extends StatefulWidget {
  const SeismometerPage({
    super.key,
    required this.tabIndex,
    this.createController,
  });

  /// Called once from [State.initState]. Null uses [SeismometerController.new].
  @visibleForTesting
  final SeismometerController Function()? createController;

  /// The shell branch this page lives in. The measurement stops while that
  /// branch is not the one on screen.
  final int tabIndex;

  @override
  State<SeismometerPage> createState() => _SeismometerPageState();
}

class _SeismometerPageState extends State<SeismometerPage>
    with WidgetsBindingObserver {
  late final SeismometerController _controller;
  VisibleTab? _visibleTab;
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    _controller = (widget.createController ?? SeismometerController.new)();
    _foreground = _inForeground(WidgetsBinding.instance.lifecycleState);
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visibleTab = VisibleTabScope.of(context);
    if (!identical(visibleTab, _visibleTab)) {
      _visibleTab?.removeListener(_syncRunning);
      _visibleTab = visibleTab;
      visibleTab?.addListener(_syncRunning);
    }
    _syncRunning();
  }

  /// `inactive` stays in the foreground: it is a transient overlay and the
  /// page is still on screen. A null state has not reported a background
  /// transition.
  bool _inForeground(AppLifecycleState? state) => switch (state) {
    AppLifecycleState.paused ||
    AppLifecycleState.hidden ||
    AppLifecycleState.detached => false,
    AppLifecycleState.resumed || AppLifecycleState.inactive || null => true,
  };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = _inForeground(state);
    if (foreground == _foreground) return;
    _foreground = foreground;
    _syncRunning();
  }

  /// No [VisibleTabScope] means the page is outside the shell, so only the
  /// app lifecycle can hide it.
  bool get _onScreen => _visibleTab?.isOnScreen(widget.tabIndex) ?? true;

  void _syncRunning() {
    if (_foreground && _onScreen) {
      _controller.start();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _visibleTab?.removeListener(_syncRunning);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seismometerTitle),
        actions: [
          IconButton(
            tooltip: l10n.seismometerReset,
            onPressed: _controller.resetSession,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      // The trace widget is built with the readings so a stop, which
      // empties the buffer without bumping [waveformRevision], replaces
      // the painter. Batches themselves only repaint.
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _ReadingCard(controller: _controller),
              const SizedBox(height: AppSpacing.md),
              _WaveformCard(controller: _controller),
              const SizedBox(height: AppSpacing.md),
              _StatsRow(controller: _controller),
              const SizedBox(height: AppSpacing.lg),
              _Footnote(l10n.seismometerDisclaimer),
              const SizedBox(height: AppSpacing.sm),
              _Footnote(l10n.seismometerAlgorithm),
            ],
          );
        },
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.controller});

  final SeismometerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final latest = controller.latest;
    final level = latest == null ? null : Intensity.toScale(latest.intensity);
    final status = _status(l10n);
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.large,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _badge(level, _intensitySize, colors),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.seismometerIntensity,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    latest == null
                        ? _absent
                        : latest.intensity.toStringAsFixed(2),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(status, style: theme.textTheme.bodyMedium),
                  ],
                  if (controller.phase == SeismometerPhase.buffering) ...[
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(value: controller.bufferProgress),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _SessionMax(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _status(AppLocalizations l10n) => switch (controller.phase) {
    SeismometerPhase.idle => null,
    SeismometerPhase.calibrating => l10n.seismometerCalibrating(
      controller.calibrationRemainingSeconds,
    ),
    SeismometerPhase.buffering => l10n.seismometerBuffering(
      (controller.bufferProgress * 100).round().clamp(0, 100),
    ),
    SeismometerPhase.measuring => l10n.seismometerMeasuring,
    SeismometerPhase.unavailable => l10n.seismometerUnavailable,
  };
}

class _SessionMax extends StatelessWidget {
  const _SessionMax({required this.controller});

  final SeismometerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = controller.sessionMax;
    final level = session == null ? null : Intensity.toScale(session.intensity);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.seismometerSessionMax,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        _badge(level, _sessionBadgeSize, colors),
        const SizedBox(width: AppSpacing.sm),
        Text(
          session == null ? _absent : session.intensity.toStringAsFixed(2),
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

Widget _badge(int? level, double size, ColorScheme colors) {
  return IntensityBadge(
    label: level == null ? _absent : Intensity.label(level),
    color: level == null
        ? colors.surfaceContainerHighest
        : IntensityColors.discrete(level),
    size: size,
  );
}

class _WaveformCard extends StatelessWidget {
  const _WaveformCard({required this.controller});

  final SeismometerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelStyle =
        Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.onSurfaceVariant) ??
        TextStyle(color: colors.onSurfaceVariant);
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(
          height: _traceHeight,
          width: double.infinity,
          child: RepaintBoundary(
            child: CustomPaint(
              willChange: true,
              painter: _WaveformPainter(
                waveform: controller.waveform,
                repaint: controller.waveformRevision,
                xColor: colors.primary,
                yColor: colors.tertiary,
                zColor: colors.secondary,
                lineColor: colors.outline,
                labelStyle: labelStyle,
                textDirection: Directionality.of(context),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three bands, X then Y then Z, sharing one symmetric gal scale.
///
/// Newest sample sits on the right. A full buffer spans the width, which
/// is 30 s at 50 Hz. An empty buffer draws only the center lines.
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveform,
    required Listenable repaint,
    required this.xColor,
    required this.yColor,
    required this.zColor,
    required this.lineColor,
    required this.labelStyle,
    required this.textDirection,
  }) : builtLength = waveform.length,
       super(repaint: repaint);

  final SeismicWaveform waveform;

  /// [waveform.length] when this painter was created.
  ///
  /// [SeismometerController.stop] clears the buffer without notifying the
  /// repaint listenable, so the next build compares this snapshot.
  final int builtLength;
  final Color xColor;
  final Color yColor;
  final Color zColor;
  final Color lineColor;
  final TextStyle labelStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final band = size.height / 3;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final length = waveform.length;
    final scale = length == 0 ? 1.0 : _windowScale(waveform);
    final tick = _tickLabel(scale);
    for (var index = 0; index < 3; index++) {
      final top = band * index;
      final center = top + band / 2;
      canvas.drawLine(Offset(0, center), Offset(size.width, center), line);
      if (length == 0) continue;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, top, size.width, band));
      _drawTrace(canvas, size, index, center, band, scale, length);
      canvas.restore();
      _label(
        canvas,
        _axisName(index),
        Offset(AppSpacing.xs, top + AppSpacing.xs),
      );
      _label(
        canvas,
        tick,
        Offset(size.width - AppSpacing.xs, top + AppSpacing.xs),
        alignRight: true,
      );
    }
  }

  double _sample(int axis, int index) => switch (axis) {
    0 => waveform.h1(index),
    1 => waveform.h2(index),
    _ => waveform.v(index),
  };

  Color _color(int axis) => switch (axis) {
    0 => xColor,
    1 => yColor,
    _ => zColor,
  };

  String _axisName(int axis) => switch (axis) {
    0 => 'X',
    1 => 'Y',
    _ => 'Z',
  };

  void _drawTrace(
    Canvas canvas,
    Size size,
    int axis,
    double center,
    double band,
    double scale,
    int length,
  ) {
    final span = SeismicWaveform.capacity - 1;
    final step = size.width / span;
    final paint = Paint()
      ..color = _color(axis)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _traceStroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (length == 1) {
      final y = center - (_sample(axis, 0) / scale) * (band / 2);
      canvas.drawCircle(
        Offset(size.width, y),
        _traceStroke,
        paint..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path();
    for (var i = 0; i < length; i++) {
      final x = size.width - (length - 1 - i) * step;
      final y = center - (_sample(axis, i) / scale) * (band / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset offset, {
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final dx = alignRight ? offset.dx - painter.width : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.builtLength != builtLength ||
      oldDelegate.xColor != xColor ||
      oldDelegate.yColor != yColor ||
      oldDelegate.zColor != zColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.textDirection != textDirection;
}

double _windowScale(SeismicWaveform wave) {
  var peak = 0.0;
  for (var i = 0; i < wave.length; i++) {
    final h1 = wave.h1(i).abs();
    final h2 = wave.h2(i).abs();
    final v = wave.v(i).abs();
    if (h1 > peak) peak = h1;
    if (h2 > peak) peak = h2;
    if (v > peak) peak = v;
  }
  return seismometerTraceScale(peak);
}

String _tickLabel(double scale) {
  final whole = scale.roundToDouble();
  final text = (scale - whole).abs() < 0.05
      ? whole.toStringAsFixed(0)
      : scale.toStringAsFixed(1);
  return '\u00b1$text gal';
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final SeismometerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Stat(
            label: l10n.seismometerAcceleration,
            value: '${controller.acceleration.toStringAsFixed(1)} gal',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Stat(
            label: l10n.seismometerPeakAcceleration,
            value: '${controller.peakAcceleration.toStringAsFixed(1)} gal',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _Stat(
            label: l10n.seismometerSampleRate,
            value: '${controller.sampleRateHz.round()} Hz',
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
