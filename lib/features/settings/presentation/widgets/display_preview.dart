/// The live sample at the top of the Display settings page: one mock
/// earthquake-report list plus the CWA intensity scale, drawn under whatever
/// the five display settings currently say.
///
/// **Nothing is plumbed in, on purpose.** All five settings are applied at the
/// app root (`app/app.dart`), so this widget only has to read the ambient
/// `Theme` and `MediaQuery` to already be live: contrast and weight arrive as a
/// new `ThemeData` (cross-faded by `MaterialApp`'s `AnimatedTheme`), size as a
/// `TextScaler`.
///
/// **Colour vision is the one exception**, and it is a trap. It never touches
/// `ThemeData` — it lives in the `AppColorVision` global that `IntensityColors`
/// reads — so it publishes no inherited dependency and cannot rebuild anything
/// by itself. [build] therefore opens by watching `ColorVisionController` and
/// discarding the value, and neither this widget nor [_IntensityScaleBar] has a
/// `const` constructor: an identical const instance short-circuits
/// `Element.updateChild`, so the subtree would be skipped on a parent rebuild
/// and the badges would keep the previous palette while the rest of the app
/// recoloured. That is compiler-enforced rather than commented because it reads
/// exactly like a missing `const` — and `prefer_const_constructors` would
/// otherwise ask a reviewer to reintroduce the bug. Do not delete the watch as
/// unused, and do not add `const` back.
///
/// The sample is a *shape*, not a copy: it follows `report_list_page.dart`'s
/// geometry closely enough to be recognisable, and shares its badge, palette
/// and gold through `shared/`, but it is not a pixel replica and does not have
/// to track that page's layout.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/seismic/report_colors.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One mock report row.
typedef _Sample = ({int level, String location, String magnitude, String time});

/// Strongest first, so the row that survives on the shortest screen is the one
/// that shows the most of the scale.
const List<_Sample> _samples = [
  (
    level: 7,
    // l10n-ignore: CWA publishes epicentre names in Chinese at every locale and the app prints them verbatim.
    location: '宜蘭縣近海',
    magnitude: '6.2',
    time: '14:07:33',
  ),
  (
    level: 4,
    // l10n-ignore: as above — the wire value is Chinese at every locale.
    location: '花蓮縣壽豐鄉',
    magnitude: '4.8',
    time: '09:21:05',
  ),
  (
    level: 3,
    // l10n-ignore: as above.
    location: '嘉義縣大埔鄉',
    magnitude: '3.9',
    time: '04:55:12',
  ),
];

/// The sample panel. [availableHeight] is the height the page can spare;
/// `double.infinity` means it sits in a scroller and may draw everything.
class DisplayPreview extends StatelessWidget {
  // Not `const`, and the lint is suppressed rather than obeyed — see the
  // library doc. A const instance is canonicalised, so `Element.updateChild`
  // would skip this subtree on a parent rebuild and the sample would keep the
  // previous colour-vision palette.
  // ignore: prefer_const_constructors_in_immutables
  DisplayPreview({super.key, required this.availableHeight});

  /// The enclosing body's height, used only to decide how many sample rows fit.
  final double availableHeight;

  /// Rough dp cost at text scale 1 of everything that is not a sample row —
  /// caption, day row, scale bar, frame and paddings — and of one sample row.
  ///
  /// Estimates, biased **high** on purpose. Over-estimating draws one row fewer
  /// than would have fitted; under-estimating would push a row past the panel's
  /// cap, where the enclosing viewport clips it. Losing a row is the cheaper
  /// mistake, and it is the only one a wrong number here can make: the panel is
  /// inside a clipping viewport, so no arithmetic error can produce a
  /// `RenderFlex` overflow.
  static const double _chromeCost = 140;
  static const double _rowCost = 80;

  /// The fraction of the body the panel may occupy — mirrored by the caller's
  /// `ConstrainedBox`. Both must move together.
  static const double heightFraction = 0.55;

  int _rowCount(BuildContext context) {
    if (!availableHeight.isFinite) return _samples.length;
    // 14 is Material's reference body size, so this reads the effective scale
    // whether the platform scaler is linear or not.
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final budget = availableHeight * heightFraction / scale;
    return ((budget - _chromeCost) / _rowCost).floor().clamp(
      1,
      _samples.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The colour-vision dependency. See the library doc — this is the only
    // wire that setting has into this subtree, and it looks unused.
    context.watch<ColorVisionController>();

    final l10n = AppLocalizations.of(context);
    final rows = _samples.take(_rowCount(context)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The caption is also the disclaimer: this is a fabricated 6⁻ report
        // inside a disaster-prevention app, and screenshots travel. It must
        // never be dropped to save height.
        SectionHeader(l10n.displayPreviewSample),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          // A picture of a screen, not a screen: nothing here is real, so a
          // screen reader must not read out an invented earthquake.
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MockReportList(rows: rows),
                const SizedBox(height: AppSpacing.sm),
                _IntensityScaleBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The framed mock: a day header and a card of report rows, shaped like the
/// report list.
class _MockReportList extends StatelessWidget {
  const _MockReportList({required this.rows});

  final List<_Sample> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.reportListToday,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.reportListDayCount(rows.length),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                children: [
                  for (final (i, sample) in rows.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppSpacing.md + 48 + AppSpacing.md,
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    _MockReportRow(sample: sample),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One mock row: intensity badge, place and time, magnitude.
class _MockReportRow extends StatelessWidget {
  const _MockReportRow({required this.sample});

  final _Sample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          IntensityBadge(
            label: Intensity.label(sample.level),
            color: IntensityColors.discrete(sample.level),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sample.location,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  sample.time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.reportListMagnitude(sample.magnitude),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: ReportColors.numberedMagnitude,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The felt-intensity scale, 1 → 7, as one labelled bar.
///
/// The densest demonstrator on the page: nine hues show what a colour-vision
/// option does, nine labels drawn on those hues show what contrast does, and
/// they are real text, so size and weight move them too. It sits outside the
/// mock frame because the report list has no scale bar — putting one inside
/// would make the sample a diagram pretending to be a screenshot.
class _IntensityScaleBar extends StatelessWidget {
  // Not `const` — see the library doc; a canonicalised instance would freeze
  // this bar's colours when the colour-vision setting changed.
  // ignore: prefer_const_constructors_in_immutables
  _IntensityScaleBar();

  /// Unscaled: this is a colour key, and letting it grow with the text setting
  /// costs the sample a whole report row on a short screen.
  static const double _height = 22;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return ClipRRect(
      borderRadius: AppRadius.small,
      child: SizedBox(
        height: _height,
        child: Row(
          children: [
            for (var level = 1; level <= 9; level++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final fill = IntensityColors.discrete(level);
                    // Derived from the already-corrected fill, exactly as
                    // IntensityBadge does — never transformed a second time.
                    final ink =
                        ThemeData.estimateBrightnessForColor(fill) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black87;
                    return Container(
                      color: fill,
                      margin: EdgeInsets.only(right: level < 9 ? 1 : 0),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Intensity.label(level),
                          style: labelStyle?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
