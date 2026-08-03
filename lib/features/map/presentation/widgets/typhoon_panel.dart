/// The typhoon layer's detail sheet (拖盤): CWA-style bulletin, warning,
/// dataset history scrubber, satellite imagery, and tapped forecast detail.
///
/// Mechanics match [StationSheet]: drag to full height (`1.0`), flush with the
/// status bar, grip hides at top. The storm name is the hero typography.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/typhoon/domain/compass_direction.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_intensity.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TyphoonPanel extends StatefulWidget {
  const TyphoonPanel({super.key, required this.layer});

  final TyphoonMapLayer layer;

  /// Collapsed peek height — also used by the map scaffold when framing.
  static const double peekExtent = 0.22;
  static const double _rest = 0.55;
  static const double _expanded = 1.0;
  static const double _atTopEpsilon = 0.02;

  static bool _isAtTop(double extent) => extent >= _expanded - _atTopEpsilon;

  @override
  State<TyphoonPanel> createState() => _TyphoonPanelState();
}

class _TyphoonPanelState extends State<TyphoonPanel> {
  final ValueNotifier<double> _extent = ValueNotifier(TyphoonPanel.peekExtent);
  int? _seededRevision;
  String? _seededTap;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: layer.tapRevision,
      builder: (context, revision, _) => ValueListenableBuilder<String?>(
        valueListenable: layer.tapped,
        builder: (context, tapped, _) {
          final popped = tapped != null;
          final initial = popped ? TyphoonPanel._rest : TyphoonPanel.peekExtent;
          if (revision != _seededRevision || tapped != _seededTap) {
            _seededRevision = revision;
            _seededTap = tapped;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _extent.value = initial;
            });
          }
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _extent.value = notification.extent;
              return false;
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                key: ValueKey(popped ? 'wp-$revision' : 'peek'),
                expand: false,
                initialChildSize: initial,
                minChildSize: TyphoonPanel.peekExtent,
                maxChildSize: TyphoonPanel._expanded,
                snap: true,
                snapSizes: const [TyphoonPanel._rest],
                builder: (context, scrollController) {
                  final body = ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      bottom:
                          MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                    ),
                    children: [
                      _Grip(extent: _extent),
                      _Bulletin(layer: layer, extent: _extent),
                      _WarningBlock(layer: layer),
                      _TappedWaypoint(layer: layer),
                      _HistorySelector(layer: layer),
                      _TimeSelector(layer: layer),
                    ],
                  );
                  return ValueListenableBuilder<double>(
                    valueListenable: _extent,
                    child: body,
                    builder: (context, extent, child) {
                      final atTop = TyphoonPanel._isAtTop(extent);
                      final topInset = MediaQuery.paddingOf(context).top;
                      return AnnotatedRegion<SystemUiOverlayStyle>(
                        value: SystemUiOverlayStyle(
                          statusBarColor: atTop
                              ? colors.surface
                              : Colors.transparent,
                          statusBarIconBrightness:
                              theme.brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark,
                          statusBarBrightness: theme.brightness,
                        ),
                        child: _Surface(
                          flushTop: atTop,
                          child: Padding(
                            padding: EdgeInsets.only(top: atTop ? topInset : 0),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.flushTop = false});

  final Widget child;
  final bool flushTop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = flushTop ? BorderRadius.zero : AppRadius.topSheet;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: flushTop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Grab handle — hidden once the sheet is flush with the top.
class _Grip extends StatefulWidget {
  const _Grip({required this.extent});

  final ValueListenable<double> extent;

  @override
  State<_Grip> createState() => _GripState();
}

class _GripState extends State<_Grip> {
  late bool _show = !TyphoonPanel._isAtTop(widget.extent.value);

  @override
  void initState() {
    super.initState();
    widget.extent.addListener(_onExtent);
  }

  @override
  void didUpdateWidget(_Grip old) {
    super.didUpdateWidget(old);
    if (old.extent != widget.extent) {
      old.extent.removeListener(_onExtent);
      widget.extent.addListener(_onExtent);
      _onExtent();
    }
  }

  @override
  void dispose() {
    widget.extent.removeListener(_onExtent);
    super.dispose();
  }

  void _onExtent() {
    final next = !TyphoonPanel._isAtTop(widget.extent.value);
    if (next == _show) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final show = !TyphoonPanel._isAtTop(widget.extent.value);
      if (show != _show) setState(() => _show = show);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Header + CWA-worded fact sheet (position / motion / intensity / radii).
class _Bulletin extends StatelessWidget {
  const _Bulletin({required this.layer, required this.extent});

  final TyphoonMapLayer layer;
  final ValueListenable<double> extent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final useZh = Localizations.localeOf(context).languageCode == 'zh';

    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.summary,
        layer.track,
        layer.selectedHistory,
        layer.selectedCycloneKey,
        extent,
      ]),
      builder: (context, _) {
        final summary = layer.summary.value;
        final cyclone = layer.track.value?.cyclones.isNotEmpty == true
            ? layer.track.value!.cyclones.first
            : null;
        final fix = cyclone != null && cyclone.analysis.isNotEmpty
            ? cyclone.analysis.last
            : null;
        final now = cyclone?.now;
        final atTop = TyphoonPanel._isAtTop(extent.value);

        if (summary == null && cyclone == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              l10n.typhoonNoActive,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          );
        }

        final name =
            summary?.cwaName ??
            cyclone?.cwaName ??
            summary?.name ??
            cyclone?.name ??
            '';
        final engName = summary?.name ?? cyclone?.name;
        final lat = fix?.latitude ?? summary?.latitude;
        final lon = fix?.longitude ?? summary?.longitude;
        final wind = fix?.wind ?? summary?.wind;
        final gust = fix?.gust ?? summary?.gust;
        final pressure = fix?.pressure ?? summary?.pressure;
        final speed = now?.speed ?? summary?.speed;
        final dirCode = now?.direction ?? summary?.direction;
        final compass = compassDirection(dirCode);
        final dirLabel = compass == null
            ? dirCode
            : (useZh ? compass.zh : compass.en);
        final intensity = typhoonIntensityFromWind(wind);

        // Name is the hero — large at peek, larger when full-bleed.
        final nameStyle =
            (atTop
                    ? theme.textTheme.displayMedium
                    : theme.textTheme.displaySmall)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.5,
                );
        final dataSec = layer.bulletinSecond;
        final dataTime = dataSec == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                dataSec * 1000,
                isUtc: true,
              ).add(const Duration(hours: 8));

        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            atTop ? AppSpacing.md : 0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: nameStyle),
                        if (engName != null && engName != name)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              engName,
                              style:
                                  (atTop
                                          ? theme.textTheme.titleMedium
                                          : theme.textTheme.titleSmall)
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                        letterSpacing: 0.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (intensity != null)
                        _IntensityChip(intensity: intensity),
                      if (dataTime != null)
                        Padding(
                          padding: EdgeInsets.only(
                            top: intensity != null ? AppSpacing.xs : 0,
                          ),
                          child: Text(
                            l10n.typhoonDataTime(
                              '${dataTime.month.toString().padLeft(2, '0')}/'
                              '${dataTime.day.toString().padLeft(2, '0')} '
                              '${dataTime.hour.toString().padLeft(2, '0')}:'
                              '${dataTime.minute.toString().padLeft(2, '0')}',
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: AppRadius.small,
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  children: [
                    if (lat != null && lon != null)
                      _TableRow(
                        label: l10n.typhoonLabelPosition,
                        value: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.typhoonValueLat(_fmt1(lat)),
                              style: _valueStyle(theme),
                            ),
                            Text(
                              l10n.typhoonValueLon(_fmt1(lon)),
                              style: _valueStyle(theme),
                            ),
                          ],
                        ),
                      ),
                    if (dirLabel != null && dirLabel.isNotEmpty)
                      _TableRow(
                        label: l10n.typhoonLabelDirection,
                        value: Text(dirLabel, style: _valueStyle(theme)),
                      ),
                    if (speed != null)
                      _TableRow(
                        label: l10n.typhoonLabelSpeed,
                        value: Text(
                          l10n.typhoonValueKm(speed.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                      ),
                    if (pressure != null)
                      _TableRow(
                        label: l10n.typhoonLabelPressure,
                        value: Text(
                          l10n.typhoonValueHpa(pressure.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                      ),
                    if (wind != null)
                      _TableRow(
                        label: l10n.typhoonLabelWind,
                        value: Text(
                          l10n.typhoonValueMs(wind.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                      ),
                    if (gust != null)
                      _TableRow(
                        label: l10n.typhoonLabelGust,
                        value: Text(
                          l10n.typhoonValueMs(gust.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                        showDivider: now?.c15 != null || now?.c25 != null,
                      ),
                    if (now?.c15 != null)
                      _StormRadiusBlock(
                        title: l10n.typhoonLabelGaleAvg,
                        circle: now!.c15!,
                        accent: const Color(0xFF9C27B0),
                      ),
                    if (now?.c25 != null)
                      _StormRadiusBlock(
                        title: l10n.typhoonLabelStormAvg,
                        circle: now!.c25!,
                        accent: const Color(0xFFFFA000),
                        showDivider: false,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt1(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? v.toStringAsFixed(0) : s;
  }

  static TextStyle? _valueStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Label | value row with a hairline divider — table-like bulletin layout.
class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final Widget value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 4,
              child: Align(alignment: Alignment.centerRight, child: value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Average radius row + 2×2 quadrant cells.
class _StormRadiusBlock extends StatelessWidget {
  const _StormRadiusBlock({
    required this.title,
    required this.circle,
    required this.accent,
    this.showDivider = true,
  });

  final String title;
  final StormCircle circle;
  final Color accent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm + 2,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  l10n.typhoonValueKm(circle.avg.toStringAsFixed(0)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuadCell(
                    label: l10n.typhoonLabelNw,
                    value: l10n.typhoonValueKm(circle.nw.toStringAsFixed(0)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuadCell(
                    label: l10n.typhoonLabelNe,
                    value: l10n.typhoonValueKm(circle.ne.toStringAsFixed(0)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuadCell(
                    label: l10n.typhoonLabelSw,
                    value: l10n.typhoonValueKm(circle.sw.toStringAsFixed(0)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuadCell(
                    label: l10n.typhoonLabelSe,
                    value: l10n.typhoonValueKm(circle.se.toStringAsFixed(0)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuadCell extends StatelessWidget {
  const _QuadCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntensityChip extends StatelessWidget {
  const _IntensityChip({required this.intensity});

  final TyphoonIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = switch (intensity) {
      TyphoonIntensity.td => l10n.typhoonIntensityTd,
      TyphoonIntensity.mild => l10n.typhoonIntensityMild,
      TyphoonIntensity.moderate => l10n.typhoonIntensityModerate,
      TyphoonIntensity.intense => l10n.typhoonIntensityIntense,
    };
    final color = Color(
      int.parse(intensity.colorHex.substring(1), radix: 16) + 0xFF000000,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// CAP warning bulletin + affected counties.
class _WarningBlock extends StatelessWidget {
  const _WarningBlock({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([layer.warning, layer.summary]),
      builder: (context, _) {
        final warn = layer.matchedWarning;
        if (warn == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.45),
              borderRadius: AppRadius.small,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.typhoonWarningTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    warn.headline,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${warn.msgType} · ${warn.severity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  if (warn.sections.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (final s in warn.sections.take(3)) ...[
                      Text(
                        s.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(s.text, style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                  if (warn.areas.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.typhoonWarningAreas(
                        warn.areas.map((a) => a.name).join(', '),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TappedWaypoint extends StatelessWidget {
  const _TappedWaypoint({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ValueListenableBuilder<String?>(
      valueListenable: layer.tapped,
      builder: (context, label, _) {
        if (label == null) return const SizedBox.shrink();
        final forecast = layer.forecastForLabel(label);
        final useZh =
            Localizations.localeOf(context).languageCode == 'zh';
        final compass = compassDirection(forecast?.direction);
        final dirLabel = compass == null
            ? forecast?.direction
            : (useZh ? compass.zh : compass.en);
        final state = forecast?.state;
        final stateNote = state == null || state.isEmpty
            ? null
            : (useZh
                      ? state.first
                      : (state.length > 1 ? state[1] : state.first))
                  .trim();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: AppRadius.small,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                  ),
                  child: Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (forecast != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.typhoonForecastLead(
                              forecast.tau.toString(),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (forecast.pressure != null)
                            Text(
                              '${l10n.typhoonLabelPressure}  '
                              '${l10n.typhoonValueHpa(forecast.pressure!.toStringAsFixed(0))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (forecast.wind != null)
                            Text(
                              '${l10n.typhoonLabelWind}  '
                              '${l10n.typhoonValueMs(forecast.wind!.toStringAsFixed(0))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (forecast.gust != null)
                            Text(
                              '${l10n.typhoonLabelGust}  '
                              '${l10n.typhoonValueMs(forecast.gust!.toStringAsFixed(0))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (forecast.speed != null)
                            Text(
                              '${l10n.typhoonLabelSpeed}  '
                              '${l10n.typhoonValueKm(forecast.speed!.toStringAsFixed(0))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (dirLabel != null && dirLabel.isNotEmpty)
                            Text(
                              '${l10n.typhoonLabelDirection}  $dirLabel',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (forecast.r15 != null)
                            Text(
                              '${l10n.typhoonLabelGaleAvg}  '
                              '${l10n.typhoonValueKm(forecast.r15!.toStringAsFixed(0))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (forecast.r70 != null)
                            Text(
                              '${l10n.typhoonLabelProbCircle}  '
                              '${l10n.typhoonValueKm(forecast.r70!.toStringAsFixed(0))}',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (stateNote != null && stateNote.isNotEmpty)
                            Text(
                              stateNote,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: layer.clearForecastSelection,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Scrubs potential/track/probability/warning snapshots.
class _HistorySelector extends StatelessWidget {
  const _HistorySelector({required this.layer});

  final TyphoonMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<List<int>>(
      valueListenable: layer.historyFrames,
      builder: (context, frames, _) {
        if (frames.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.typhoonHistoryTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ValueListenableBuilder<int?>(
                valueListenable: layer.selectedHistory,
                builder: (context, selected, _) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: frames.length + 1,
                  itemBuilder: (context, i) {
                    if (i == frames.length) {
                      return _TimeChip(
                        label: l10n.typhoonHistoryLive,
                        selected: selected == null,
                        onTap: () => layer.selectHistory(null),
                      );
                    }
                    final sec = frames[i];
                    final time = DateTime.fromMillisecondsSinceEpoch(
                      sec * 1000,
                      isUtc: true,
                    ).add(const Duration(hours: 8));
                    return _TimeChip(
                      time: time,
                      selected: selected == sec,
                      onTap: () => layer.selectHistory(sec),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeSelector extends StatefulWidget {
  const _TimeSelector({required this.layer});

  final TyphoonMapLayer layer;

  @override
  State<_TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<_TimeSelector> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ValueListenableBuilder<List<int>>(
      valueListenable: widget.layer.imageFrames,
      builder: (context, frames, _) {
        if (frames.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.typhoonSatelliteTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ValueListenableBuilder<int>(
                valueListenable: widget.layer.selectedFrame,
                builder: (context, selected, _) => ListView.builder(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: frames.length,
                  itemBuilder: (context, i) => _TimeChip(
                    time: DateTime.fromMillisecondsSinceEpoch(
                      frames[i] * 1000,
                      isUtc: true,
                    ).add(const Duration(hours: 8)),
                    selected: i == selected,
                    onTap: () => widget.layer.showFrame(i),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    this.time,
    this.label,
    required this.selected,
    required this.onTap,
  }) : assert(time != null || label != null);

  final DateTime? time;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: label != null ? 64 : 72,
        margin: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: AppRadius.small,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null)
              Text(
                label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                AppLocalizations.of(context).typhoonTimeChip(
                  '${time!.day}',
                  time!.hour.toString().padLeft(2, '0'),
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
