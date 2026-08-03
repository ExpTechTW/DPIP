/// Screen-space Flutter callouts for typhoon forecast points.
///
/// Full CWA-style forecast cards projected via `toScreenLocation`. Layout is
/// vertical only (above / below); leaders attach to the chip edge facing the
/// point. Hidden while the map gesture is active; restored on release / idle.
///
/// l10n-ignore-file: CWA bulletin tips are fixed Traditional Chinese on the map
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/typhoon/domain/compass_direction.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Min zoom before forecast Flutter tips appear.
const double kTyphoonCalloutMinZoom = 6.0;

/// Gap between forecast point and card edge (px).
const double _leaderGap = 36;

/// Fixed card width — keeps columns aligned across tips.
const double _cardW = 172;

/// Flutter overlay: full forecast cards + leader lines over the map.
class TyphoonForecastCalloutOverlay extends StatefulWidget {
  const TyphoonForecastCalloutOverlay({super.key, required this.layer});

  final TyphoonMapLayer layer;

  @override
  State<TyphoonForecastCalloutOverlay> createState() =>
      _TyphoonForecastCalloutOverlayState();
}

class _TyphoonForecastCalloutOverlayState
    extends State<TyphoonForecastCalloutOverlay> {
  List<_PlacedCallout> _placed = const [];
  int _gen = 0;
  MapLibreMapController? _boundController;

  @override
  void initState() {
    super.initState();
    widget.layer.track.addListener(_schedule);
    widget.layer.selectedCycloneKey.addListener(_schedule);
    widget.layer.selectedHistory.addListener(_schedule);
    widget.layer.tapped.addListener(_schedule);
    widget.layer.suppressCallouts.addListener(_onSuppress);
    widget.layer.showForecastCallouts.addListener(_onToggleCallouts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindController();
      _schedule();
    });
  }

  @override
  void didUpdateWidget(covariant TyphoonForecastCalloutOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bindController();
      _schedule();
    });
  }

  @override
  void dispose() {
    _boundController?.removeListener(_onController);
    widget.layer.track.removeListener(_schedule);
    widget.layer.selectedCycloneKey.removeListener(_schedule);
    widget.layer.selectedHistory.removeListener(_schedule);
    widget.layer.tapped.removeListener(_schedule);
    widget.layer.suppressCallouts.removeListener(_onSuppress);
    widget.layer.showForecastCallouts.removeListener(_onToggleCallouts);
    super.dispose();
  }

  void _bindController() {
    final c = widget.layer.mapController;
    if (identical(c, _boundController)) return;
    _boundController?.removeListener(_onController);
    _boundController = c;
    _boundController?.addListener(_onController);
  }

  void _onToggleCallouts() {
    if (!widget.layer.showForecastCallouts.value) {
      _invalidateAndHide();
      return;
    }
    _schedule();
  }

  /// MapLibre notifies on camera-move start/idle — hide immediately on move
  /// so a late `toScreenLocationBatch` can't paint tips mid-pan.
  void _onController() {
    final c = _boundController;
    if (c == null || !mounted) return;
    if (c.isCameraMoving) {
      _invalidateAndHide();
    }
  }

  void _onSuppress() {
    if (widget.layer.suppressCallouts.value) {
      _invalidateAndHide();
      return;
    }
    _schedule();
  }

  void _invalidateAndHide() {
    _gen++; // drop any in-flight reproject
    if (_placed.isNotEmpty) setState(() => _placed = const []);
  }

  bool get _blocked {
    final c = widget.layer.mapController;
    return !widget.layer.showForecastCallouts.value ||
        widget.layer.suppressCallouts.value ||
        (c?.isCameraMoving ?? false);
  }

  void _schedule() {
    _bindController();
    if (_blocked) {
      _invalidateAndHide();
      return;
    }
    final gen = ++_gen;
    unawaited(_reproject(gen));
  }

  Future<void> _reproject(int gen) async {
    final controller = widget.layer.mapController;
    if (controller == null || !mounted) {
      if (mounted) setState(() => _placed = const []);
      return;
    }
    if (_blocked || gen != _gen) {
      if (mounted && gen == _gen) setState(() => _placed = const []);
      return;
    }
    final zoom = controller.cameraPosition?.zoom ?? 0;
    if (zoom < kTyphoonCalloutMinZoom) {
      if (mounted && gen == _gen) setState(() => _placed = const []);
      return;
    }
    final forecasts = widget.layer.selectedForecasts;
    if (forecasts.isEmpty) {
      if (mounted && gen == _gen) setState(() => _placed = const []);
      return;
    }
    final ordered = [...forecasts]..sort((a, b) => a.tau.compareTo(b.tau));
    late final List<math.Point<num>> screens;
    try {
      screens = await controller.toScreenLocationBatch([
        for (final f in ordered) LatLng(f.latitude, f.longitude),
      ]);
    } catch (_) {
      if (mounted && gen == _gen) setState(() => _placed = const []);
      return;
    }
    // Re-check after the await — a pan may have started while we projected.
    if (!mounted || gen != _gen || _blocked) {
      if (mounted && gen == _gen) setState(() => _placed = const []);
      return;
    }

    final size = MediaQuery.sizeOf(context);
    final placed = <_PlacedCallout>[];
    final boxes = <Rect>[];
    final tappedTau =
        widget.layer.forecastForLabel(widget.layer.tapped.value)?.tau;

    for (var i = 0; i < ordered.length; i++) {
      final anchor = Offset(
        screens[i].x.toDouble(),
        screens[i].y.toDouble(),
      );
      if (anchor.dx < -40 ||
          anchor.dy < -40 ||
          anchor.dx > size.width + 40 ||
          anchor.dy > size.height + 40) {
        continue;
      }
      final data = ForecastCalloutData.from(ordered[i]);
      final chipH = data.estimatedHeight;
      final pick = _pickVerticalTip(
        anchor: anchor,
        preferAbove: i.isEven,
        chipW: _cardW,
        chipH: chipH,
        occupied: boxes,
        viewport: size,
      );
      boxes.add(Rect.fromLTWH(pick.tip.dx, pick.tip.dy, _cardW, chipH));
      placed.add(
        _PlacedCallout(
          anchor: anchor,
          tip: pick.tip,
          width: _cardW,
          height: chipH,
          above: pick.above,
          data: data,
          selected: tappedTau == ordered[i].tau,
        ),
      );
    }
    if (!mounted || gen != _gen || _blocked) return;
    setState(() => _placed = placed);
  }

  @override
  Widget build(BuildContext context) {
    if (_placed.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        CustomPaint(
          painter: _LeaderPainter(
            callouts: _placed,
            color: colors.tertiary.withValues(alpha: 0.9),
          ),
          size: Size.infinite,
        ),
        for (final c in _placed)
          Positioned(
            left: c.tip.dx,
            top: c.tip.dy,
            width: c.width,
            child: _CalloutCard(data: c.data, selected: c.selected),
          ),
      ],
    );
  }
}

/// Structured rows for a full forecast tip (also used by tests).
@immutable
class ForecastCalloutData {
  const ForecastCalloutData({
    required this.title,
    required this.rows,
    this.note,
  });

  factory ForecastCalloutData.from(TrackForecast f) {
    final rows = <({String label, String value})>[];
    if (f.pressure != null) {
      rows.add((
        label: '中心氣壓',
        value: '${f.pressure!.toStringAsFixed(0)} 百帕',
      ));
    }
    if (f.wind != null) {
      rows.add((
        label: '最大風速',
        value: '每秒 ${f.wind!.toStringAsFixed(0)} 公尺',
      ));
    }
    if (f.gust != null) {
      rows.add((
        label: '瞬間陣風',
        value: '每秒 ${f.gust!.toStringAsFixed(0)} 公尺',
      ));
    }
    if (f.speed != null) {
      rows.add((
        label: '移動時速',
        value: '${f.speed!.toStringAsFixed(0)} 公里／時',
      ));
    }
    final dir = compassDirection(f.direction);
    if (dir != null) {
      rows.add((label: '移動方向', value: dir.zh));
    } else if (f.direction != null && f.direction!.isNotEmpty) {
      rows.add((label: '移動方向', value: f.direction!));
    }
    if (f.r15 != null) {
      rows.add((
        label: '七級風半徑',
        value: '${f.r15!.toStringAsFixed(0)} 公里',
      ));
    }
    String? note;
    final state = f.state;
    if (state != null && state.isNotEmpty && state.first.trim().isNotEmpty) {
      note = state.first.trim();
    }
    return ForecastCalloutData(
      title: '預測 +${f.tau} 小時',
      rows: rows,
      note: note,
    );
  }

  final String title;
  final List<({String label, String value})> rows;
  final String? note;

  /// Layout estimate for collision (header + rows + optional note + pad).
  double get estimatedHeight {
    var h = 34.0; // header
    h += rows.length * 18.0;
    if (note != null) h += 28.0;
    h += 14.0; // padding
    return h;
  }
}

/// Legacy alias kept for the unit test import path.
String compactForecastCalloutText(TrackForecast forecast) {
  final d = ForecastCalloutData.from(forecast);
  final buf = StringBuffer(d.title);
  for (final r in d.rows) {
    buf.write('\n${r.label} ${r.value}');
  }
  if (d.note != null) buf.write('\n${d.note}');
  return buf.toString();
}

({Offset tip, bool above}) _pickVerticalTip({
  required Offset anchor,
  required bool preferAbove,
  required double chipW,
  required double chipH,
  required List<Rect> occupied,
  required Size viewport,
}) {
  Offset place(bool above, {double xNudge = 0}) {
    final x = (anchor.dx - chipW / 2 + xNudge).clamp(
      4.0,
      viewport.width - chipW - 4,
    );
    final y = above
        ? (anchor.dy - chipH - _leaderGap)
              .clamp(4.0, viewport.height - chipH - 4)
        : (anchor.dy + _leaderGap).clamp(4.0, viewport.height - chipH - 4);
    return Offset(x, y);
  }

  bool fits(Offset tip) {
    final box = Rect.fromLTWH(tip.dx, tip.dy, chipW, chipH);
    return !occupied.any((o) => o.inflate(10).overlaps(box));
  }

  for (final above in [preferAbove, !preferAbove]) {
    for (final nudge in [0.0, 48.0, -48.0, 96.0, -96.0]) {
      final tip = place(above, xNudge: nudge);
      if (fits(tip)) return (tip: tip, above: above);
    }
  }
  return (tip: place(preferAbove), above: preferAbove);
}

class _PlacedCallout {
  const _PlacedCallout({
    required this.anchor,
    required this.tip,
    required this.width,
    required this.height,
    required this.above,
    required this.data,
    required this.selected,
  });

  final Offset anchor;
  final Offset tip;
  final double width;
  final double height;
  final bool above;
  final ForecastCalloutData data;
  final bool selected;
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.data, required this.selected});

  final ForecastCalloutData data;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = selected
        ? colors.tertiary
        : colors.outline.withValues(alpha: 0.35);

    return ClipRRect(
      borderRadius: AppRadius.small,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.88),
            borderRadius: AppRadius.small,
            border: Border.all(color: border, width: selected ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent header
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer.withValues(alpha: 0.75),
                  border: Border(
                    bottom: BorderSide(
                      color: colors.tertiary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs + 2,
                    AppSpacing.sm,
                    AppSpacing.xs + 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: colors.onTertiaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          data.title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onTertiaryContainer,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in data.rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SizedBox(
                              width: 68,
                              child: Text(
                                row.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.value,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (data.note != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Divider(
                          height: 1,
                          color: colors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          data.note!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.tertiary,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter({required this.callouts, required this.color});

  final List<_PlacedCallout> callouts;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;
    for (final c in callouts) {
      final attach = Offset(
        c.tip.dx + c.width / 2,
        c.above ? c.tip.dy + c.height : c.tip.dy,
      );
      _dashLine(canvas, paint, attach, c.anchor);
      canvas.drawCircle(c.anchor, 3, fill);
      canvas.drawCircle(
        c.anchor,
        3,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _dashLine(Canvas canvas, Paint paint, Offset a, Offset b) {
    const dash = 4.5;
    const gap = 3.0;
    final total = (b - a).distance;
    if (total < 1) return;
    final dir = (b - a) / total;
    var t = 0.0;
    while (t < total) {
      final t2 = math.min(t + dash, total);
      canvas.drawLine(a + dir * t, a + dir * t2, paint);
      t = t2 + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter oldDelegate) =>
      oldDelegate.callouts != callouts || oldDelegate.color != color;
}
