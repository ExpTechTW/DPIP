/// Bottom sheet for a CWA tsunami bulletin: the report picker, the bulletin
/// text, the source earthquake, and the predicted / observed coastal heights.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/map/presentation/layers/tsunami_layer.dart';
import 'package:dpip/features/tsunami/domain/tsunami_report.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/selectable_pill.dart';
import 'package:dpip/shared/widgets/sheet_extent.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Collapsible tsunami bulletin sheet — the text half of the layer, on the same
/// peek / rest / full skeleton as the station, DPM and typhoon sheets.
///
/// It renders [TsunamiMapLayer.state] rather than fetching again: the layer
/// already asked for exactly this bulletin to draw, and a second request would
/// let the map and the panel show two different reports.
class TsunamiPanel extends StatefulWidget {
  const TsunamiPanel({super.key, required this.layer});

  final TsunamiMapLayer layer;

  /// Collapsed peek height — also what the scaffold frames around.
  static const double peekExtent = 0.22;
  static const double _rest = 0.58;
  static const double _expanded = 1;

  @override
  State<TsunamiPanel> createState() => _TsunamiPanelState();
}

class _TsunamiPanelState extends State<TsunamiPanel> {
  final ValueNotifier<double> _extent = ValueNotifier(TsunamiPanel.peekExtent);

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExtentSheetChrome(
    extent: _extent,
    keyValue: 'tsunami',
    initial: TsunamiPanel.peekExtent,
    min: TsunamiPanel.peekExtent,
    max: TsunamiPanel._expanded,
    snapSizes: const [TsunamiPanel._rest],
    content: (context, scrollController) => ListView(
      controller: scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
      ),
      children: [
        SheetGrip(extent: _extent),
        // The picker sits above the report it picks, so it is reachable at the
        // sheet's resting height — switching 第1報 / 第3報 must not require
        // dragging the sheet open first.
        _ReportPicker(layer: widget.layer),
        ValueListenableBuilder<Result<TsunamiReport?>?>(
          valueListenable: widget.layer.state,
          builder: (context, state, _) => switch (state) {
            null => const _Pending(),
            // `Ok(null)` is CWA having issued nothing: an all-clear, not an
            // error, so it gets the calm empty state rather than a retry button
            // that would only fetch the same nothing.
            Ok(value: null) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: EmptyView(
                icon: Icons.check_circle_outline,
                message: AppLocalizations.of(context).tsunamiEmpty,
              ),
            ),
            Err(:final failure) => ErrorView(
              headline: AppLocalizations.of(context).commonFetchFailed,
              detail: failure.message,
              onRetry: widget.layer.load,
            ),
            Ok(:final value?) => _Bulletin(report: value),
          },
        ),
      ],
    ),
  );
}

/// The fetch is still in flight.
class _Pending extends StatelessWidget {
  const _Pending();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: LoadingView(),
  );
}

/// 第N報 pills for the newest event's reports, newest first.
///
/// One request per report is what CWA's index is for (`reports` carries the
/// summaries), and it is the only way to read the predictions at all: an event
/// ends with a 海嘯警報解除 report, which carries observations and no predicted
/// heights, so "the newest report only" would hide the forecast exactly when a
/// reader wants to compare it with what happened.
class _ReportPicker extends StatelessWidget {
  const _ReportPicker({required this.layer});

  final TsunamiMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([layer.bulletins, layer.selectedId]),
      builder: (context, _) {
        final bulletins = layer.bulletins.value;
        if (bulletins.length < 2) return const SizedBox.shrink();
        final selected = layer.selectedId.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final bulletin in bulletins)
                SelectablePill(
                  label: reportLabel(l10n, bulletin),
                  selected: bulletin.id == selected,
                  onTap: () => layer.selectBulletin(bulletin.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The pill's label for one report: CWA's own `第3報` re-numbered through the
/// catalogue (`Report 3` in English), or the raw text when it holds no number.
String reportLabel(AppLocalizations l10n, TsunamiBulletin bulletin) {
  final digits = RegExp(r'\d+').firstMatch(bulletin.report)?.group(0);
  final number = digits == null ? null : int.tryParse(digits);
  return number == null ? bulletin.report : l10n.tsunamiReportNumber(number);
}

class _Bulletin extends StatelessWidget {
  const _Bulletin({required this.report});

  final TsunamiReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final stamp = TsunamiStamp(Localizations.localeOf(context));
    final cancelled = report.msgType == 'Cancel';
    final earthquake = report.earthquake;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                cancelled ? Icons.check_circle : Icons.tsunami,
                color: cancelled ? colors.primary : colors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.type, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${report.report} · ${stamp.of(report.sent)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(report.content, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.tsunamiEarthquake, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _FactRow(
            label: l10n.reportDetailEpicenter,
            value: earthquake.location,
          ),
          _FactRow(
            label: l10n.reportDetailMagnitude,
            value: l10n.reportListMagnitude(
              earthquake.magnitude.toStringAsFixed(1),
            ),
          ),
          _FactRow(
            label: l10n.reportDetailDepth,
            value: l10n.reportFilterDepthKm(
              earthquake.depth.toStringAsFixed(1),
            ),
          ),
          _FactRow(
            label: l10n.reportDetailOriginTime,
            value: stamp.of(earthquake.time),
          ),
          if (report.predictions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.tsunamiPredictions, style: theme.textTheme.titleMedium),
            for (final prediction in report.predictions)
              _CoastalRow(
                title: prediction.area,
                subtitle: prediction.coast,
                // CWA's own text (`<1`), not a band: the predicted height is a
                // range the agency chose, and bucketing `<1` onto one colour
                // would state a metre figure CWA did not.
                chip: prediction.height,
                trailing: stamp.of(prediction.arrivalTime),
              ),
          ],
          if (report.observations.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.tsunamiObservations, style: theme.textTheme.titleMedium),
            for (final observation in report.observations)
              _CoastalRow(
                title: observation.name,
                chip: _observedLabel(l10n, observation),
                band: observedBand(observation),
                trailing: stamp.of(observation.time),
              ),
          ],
        ],
      ),
    );
  }

  /// The observed reading, in centimetres where CWA's text holds a number so
  /// the unit localises (`27公分` → `27 cm`), and verbatim where it does not.
  static String _observedLabel(
    AppLocalizations l10n,
    TsunamiObservation observation,
  ) {
    final centimeters = parseObservedCentimeters(observation.height);
    return centimeters == null
        ? observation.height
        : l10n.tsunamiWaveHeightCm(centimeters);
  }
}

/// `label ————— value`, the label/value row both the earthquake facts and the
/// bulletin body already read as.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// One coastal entry: the area or station, its height chip, and the time.
class _CoastalRow extends StatelessWidget {
  const _CoastalRow({
    required this.title,
    required this.chip,
    required this.trailing,
    this.subtitle,
    this.band,
  });

  final String title;
  final String? subtitle;

  /// The chip's text — a height, in CWA's words or localised.
  final String chip;

  /// The band the chip is coloured by; null keeps it neutral.
  final TsunamiWaveBand? band;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  trailing,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _HeightChip(text: chip, band: band),
        ],
      ),
    );
  }
}

/// The height chip: the band's colour, or a neutral surface when the height
/// could not be placed on the scale.
///
/// Ink follows the fill — white reads on every band except the yellow one,
/// which is why the legacy app darkened it there and this does the same.
class _HeightChip extends StatelessWidget {
  const _HeightChip({required this.text, this.band});

  final String text;
  final TsunamiWaveBand? band;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fill = switch (band) {
      final band? =>
        colorFromHexRgb(TsunamiMapLayer.bandColor(band)) ??
            colors.surfaceContainerHighest,
      null => colors.surfaceContainerHighest,
    };
    final ink = switch (band) {
      TsunamiWaveBand.from30cm => const Color(0xFF202020),
      null => colors.onSurfaceVariant,
      _ => Colors.white,
    };
    return Container(
      constraints: const BoxConstraints(minWidth: 68),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Formats the feed's Unix-millisecond stamps as Taipei wall time, via
/// [AppTime.taipei] — the same fixed +8 the rest of the app reads server stamps
/// with. `toLocal()` would relabel a CWA coastal arrival time with whatever
/// timezone the reader happens to be in.
///
/// The locale goes through [intlDateLocale] first: `intl` carries its own locale
/// data, separate from `flutter_localizations`, and throws "Invalid locale" on a
/// tag it does not know (`yue`, which this app ships).
class TsunamiStamp {
  TsunamiStamp(Locale locale)
    : _format = DateFormat('MM/dd HH:mm', intlDateLocale(locale));

  final DateFormat _format;

  String of(int milliseconds) => _format.format(
    AppTime.taipei(
      DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true),
    ),
  );
}
