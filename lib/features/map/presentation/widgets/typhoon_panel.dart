/// The typhoon layer's detail sheet (拖盤): CWA-style bulletin, warning,
/// and tapped forecast detail (latest bulletin; satellite aligned on the map).
///
/// Mechanics match [StationSheet]: drag to full height (`1.0`), flush with the
/// status bar, grip hides at top. The storm name is the hero typography.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/format.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/typhoon/domain/compass_direction.dart';
import 'package:dpip/features/typhoon/domain/cyclone_identity.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_intensity.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/sheet_extent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TyphoonPanel extends StatefulWidget {
  const TyphoonPanel({super.key, required this.layer});

  final TyphoonMapLayer layer;

  /// Collapsed peek height — also used by the map scaffold when framing.
  static const double peekExtent = 0.22;
  static const double _rest = 0.55;
  static const double _expanded = 1.0;

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
          return ExtentSheetChrome(
            extent: _extent,
            keyValue: popped ? 'wp-$revision' : 'peek',
            initial: initial,
            min: TyphoonPanel.peekExtent,
            max: TyphoonPanel._expanded,
            snapSizes: const [TyphoonPanel._rest],
            content: (context, scrollController) => ListView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              ),
              children: [
                SheetGrip(extent: _extent),
                _Bulletin(layer: layer, extent: _extent),
                _WarningBlock(layer: layer),
                _TappedWaypoint(layer: layer),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Header + CWA-worded fact sheet (position / motion / intensity / radii).
/// Formats the sheet hero / picker title for one cyclone.
String cycloneSheetTitle(
  AppLocalizations l10n, {
  String? name,
  String? cwaName,
  String? tyNo,
  String? tdNo,
}) {
  final spec = cycloneTitleSpec(
    name: name,
    cwaName: cwaName,
    tyNo: tyNo,
    tdNo: tdNo,
  );
  if (spec.isTyphoon && spec.number != null && spec.displayName != null) {
    return l10n.typhoonPickerNamed(spec.number!, spec.displayName!);
  }
  if (spec.number != null) {
    return l10n.typhoonPickerTd(spec.number!);
  }
  return spec.displayName ?? l10n.typhoonIntensityTd;
}

class _Bulletin extends StatefulWidget {
  const _Bulletin({required this.layer, required this.extent});

  final TyphoonMapLayer layer;
  final ValueListenable<double> extent;

  @override
  State<_Bulletin> createState() => _BulletinState();
}

/// Self-listens to [_Bulletin.extent] for just the `atTop` flip — the same
/// technique as [_Grip] above — instead of merging `extent` straight into the
/// [ListenableBuilder] below. `extent` used to sit in that same
/// `Listenable.merge`, which fired this whole bulletin's rebuild (cyclone-name
/// formatting, the picker menu, the position/wind/pressure table) on every
/// pixel of the sheet's drag, even though only four style choices below
/// actually read `atTop`. `setState` only runs when the derived boolean
/// changes, so the bulletin now rebuilds on data updates plus the (rare) top
/// threshold crossing — not on every drag tick.
class _BulletinState extends State<_Bulletin> with SheetExtentFlag<_Bulletin> {
  @override
  ValueListenable<double> get sheetExtent => widget.extent;

  @override
  bool sheetFlagFrom(double extent) => sheetExtentIsAtTop(extent);

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final useZh = Localizations.localeOf(context).languageCode == 'zh';
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      layer.rememberFrameMetrics(
        viewport: size,
        topInset: topInset,
        bottomInset: size.height * TyphoonPanel.peekExtent,
      );
    });

    return ListenableBuilder(
      listenable: Listenable.merge([
        layer.summary,
        layer.track,
        layer.selectedCycloneKey,
      ]),
      builder: (context, _) {
        // Sheet SoT = selected track. Index summary is only a fallback when
        // `/track` has no entry for the focused key — never mix fields across
        // two storms (summary name + track metrics used to cross-wire).
        final track = layer.selectedTrack;
        final summary = track == null ? layer.summary.value : null;
        final fix = track != null && track.analysis.isNotEmpty
            ? track.analysis.last
            : null;
        final now = track?.now;
        final atTop = sheetFlag;

        if (track == null && summary == null) {
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

        final title = cycloneSheetTitle(
          l10n,
          name: track?.name ?? summary?.name,
          cwaName: track?.cwaName ?? summary?.cwaName,
          tyNo: track?.tyNo ?? summary?.tyNo,
          tdNo: track?.tdNo ?? summary?.tdNo,
        );
        final engName = presentText(track?.name ?? summary?.name);
        // Hide the English line when the hero already embeds that name, or when
        // the picker title is the TD form (no separate international name).
        final showEng =
            engName != null &&
            !title.contains(engName) &&
            cycloneDisplayName(
                  cwaName: track?.cwaName ?? summary?.cwaName,
                  name: track?.name ?? summary?.name,
                ) !=
                null;
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
            : AppTime.taipei(
                DateTime.fromMillisecondsSinceEpoch(
                  dataSec * 1000,
                  isUtc: true,
                ),
              );

        final options = <({String key, String title})>[
          for (final t in layer.track.value?.cyclones ?? const <TyphoonTrack>[])
            (
              key: cycloneKeyOf(name: t.name, cwaName: t.cwaName, tdNo: t.tdNo),
              title: cycloneSheetTitle(
                l10n,
                name: t.name,
                cwaName: t.cwaName,
                tyNo: t.tyNo,
                tdNo: t.tdNo,
              ),
            ),
        ];
        if (options.isEmpty) {
          for (final c in layer.activeCyclones) {
            options.add((
              key: cycloneKey(c),
              title: cycloneSheetTitle(
                l10n,
                name: c.name,
                cwaName: c.cwaName,
                tyNo: c.tyNo,
                tdNo: c.tdNo,
              ),
            ));
          }
        }
        final selectedKey = layer.selectedCycloneKey.value;
        final multi = options.length > 1;

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
                  Container(
                    width: atTop ? 56 : 46,
                    height: atTop ? 56 : 46,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cyclone,
                      color: colors.primary,
                      size: atTop ? 32 : 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (multi)
                          PopupMenuButton<String>(
                            initialValue: selectedKey,
                            tooltip: title,
                            padding: EdgeInsets.zero,
                            onSelected: layer.selectCyclone,
                            itemBuilder: (context) => [
                              for (final o in options)
                                PopupMenuItem(
                                  value: o.key,
                                  child: Text(
                                    o.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: o.key == selectedKey
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                  ),
                                ),
                            ],
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(title, style: nameStyle)),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.sm,
                                  ),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: colors.onSurface,
                                    size: atTop ? 36 : 32,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(title, style: nameStyle),
                        if (showEng)
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
                        icon: Icons.place_outlined,
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
                        icon: Icons.explore_outlined,
                        label: l10n.typhoonLabelDirection,
                        value: Text(dirLabel, style: _valueStyle(theme)),
                      ),
                    if (speed != null)
                      _TableRow(
                        icon: Icons.navigation_outlined,
                        label: l10n.typhoonLabelSpeed,
                        value: Text(
                          l10n.typhoonValueKm(speed.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                      ),
                    if (pressure != null)
                      _TableRow(
                        icon: Icons.compress_outlined,
                        label: l10n.typhoonLabelPressure,
                        value: Text(
                          l10n.typhoonValueHpa(pressure.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                      ),
                    if (wind != null)
                      _TableRow(
                        icon: Icons.air_outlined,
                        label: l10n.typhoonLabelWind,
                        value: Text(
                          l10n.typhoonValueMs(wind.toStringAsFixed(0)),
                          style: _valueStyle(theme),
                        ),
                      ),
                    if (gust != null)
                      _TableRow(
                        icon: Icons.air,
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

  static String _fmt1(double v) => trimTrailingZero(v);

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
    this.icon,
    this.showDivider = true,
  });

  final String label;
  final Widget value;

  /// Leading glyph, so the fact sheet scans by picture (position → place pin,
  /// motion → heading, pressure → gauge) instead of by caption.
  final IconData? icon;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icon = this.icon;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
            ],
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
      listenable: Listenable.merge([
        layer.warning,
        layer.summary,
        layer.selectedCycloneKey,
      ]),
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
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.typhoonWarningTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
        final useZh = Localizations.localeOf(context).languageCode == 'zh';
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
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: AppRadius.small,
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              if (forecast != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  l10n.typhoonForecastLead(
                                    forecast.tau.toString(),
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: layer.clearForecastSelection,
                      ),
                    ],
                  ),
                ),
                if (forecast != null) ...[
                  const _WaypointDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: [
                        if (forecast.pressure != null)
                          _WaypointRow(
                            icon: Icons.compress_outlined,
                            label: l10n.typhoonLabelPressure,
                            value: l10n.typhoonValueHpa(
                              forecast.pressure!.toStringAsFixed(0),
                            ),
                          ),
                        if (forecast.wind != null)
                          _WaypointRow(
                            icon: Icons.air_outlined,
                            label: l10n.typhoonLabelWind,
                            value: l10n.typhoonValueMs(
                              forecast.wind!.toStringAsFixed(0),
                            ),
                          ),
                        if (forecast.gust != null)
                          _WaypointRow(
                            icon: Icons.air,
                            label: l10n.typhoonLabelGust,
                            value: l10n.typhoonValueMs(
                              forecast.gust!.toStringAsFixed(0),
                            ),
                          ),
                        if (forecast.speed != null)
                          _WaypointRow(
                            icon: Icons.navigation_outlined,
                            label: l10n.typhoonLabelSpeed,
                            value: l10n.typhoonValueKm(
                              forecast.speed!.toStringAsFixed(0),
                            ),
                          ),
                        if (dirLabel != null && dirLabel.isNotEmpty)
                          _WaypointRow(
                            icon: Icons.explore_outlined,
                            label: l10n.typhoonLabelDirection,
                            value: dirLabel,
                          ),
                        if (forecast.r15 != null || forecast.r70 != null)
                          const _WaypointDivider(indented: true),
                        if (forecast.r15 != null)
                          _WaypointRow(
                            icon: Icons.radio_button_unchecked,
                            label: l10n.typhoonLabelGaleAvg,
                            value: l10n.typhoonValueKm(
                              forecast.r15!.toStringAsFixed(0),
                            ),
                          ),
                        if (forecast.r70 != null)
                          _WaypointRow(
                            icon: Icons.radio_button_checked,
                            label: l10n.typhoonLabelProbCircle,
                            value: l10n.typhoonValueKm(
                              forecast.r70!.toStringAsFixed(0),
                            ),
                          ),
                        if (stateNote != null && stateNote.isNotEmpty) ...[
                          const _WaypointDivider(indented: true),
                          _WaypointNote(text: stateNote),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A thin rule grouping the waypoint rows; [indented] aligns it under the text
/// column (right of the leading icon), so the groups read as subdivisions.
class _WaypointDivider extends StatelessWidget {
  const _WaypointDivider({this.indented = false});

  final bool indented;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: indented ? AppSpacing.lg + AppSpacing.md : 0,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Label | value row for a forecast metric — same icon hierarchy as the DPM
/// sheet: small grey caption over a weighted value, scanning by picture.
class _WaypointRow extends StatelessWidget {
  const _WaypointRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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

/// Free-form note (the CWA forecast-state sentence) under the metric rows.
class _WaypointNote extends StatelessWidget {
  const _WaypointNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
