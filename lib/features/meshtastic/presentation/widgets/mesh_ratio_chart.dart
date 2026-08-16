/// The radio's own counters, as four questions with four charts.
///
/// These were one row of small tiles. At a quarter of a phone's width a
/// sparkline is a squiggle — you can see that something moved, never when or
/// how much — so each reading gets the full width and a real axis, and the
/// number that used to be the tile's headline moves into the legend.
///
/// The numbers come from `LocalStats`, which the firmware sends down the BLE
/// link every ~15 minutes and never over the air. Nothing here costs a symbol
/// of airtime.
///
/// Each point is that **slice's own** ratio, not a running total. A cumulative
/// line answers "what has the day averaged", which is the tile's question; a
/// chart's question is "when did it change", and a cumulative line buries that
/// under everything that came before. A slice with too small a denominator to
/// mean anything is a gap rather than a wild swing.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/features/meshtastic/presentation/widgets/mesh_charts.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Which counter pair a chart plots.
enum MeshRatio {
  /// Share of what this radio sent that was carried for someone else. The
  /// mesh's whole premise is that ordinary nodes relay; this says whether
  /// yours actually does.
  relayShare,

  /// Of the rebroadcasts this radio started, how many it completed. Cancelled
  /// means another node got there first — so a *high* figure means this radio
  /// is often the only path, which reads as good and means fragile.
  relayCompleted,

  /// Share of receptions the mesh had already delivered. Not a fault: it is
  /// the resilience of this radio's physical position. Near zero means one
  /// relay dying cuts it off.
  duplicates,

  /// Share of receptions that failed CRC. The one signal that separates
  /// interference from congestion — rising here while airtime stays flat is
  /// somebody else's noise, not a busy mesh.
  errors,
}

class MeshRatioChart extends StatelessWidget {
  const MeshRatioChart({super.key, required this.ratio, required this.samples});

  final MeshRatio ratio;

  /// Oldest first, already windowed by the section.
  final List<MeshMetricSample> samples;

  /// Below this many events a slice's ratio is noise — three packets can only
  /// be 0%, 33%, 67% or 100%, and plotting that produces a cliff where nothing
  /// happened. Such a slice is a gap, which is the honest shape of "not enough
  /// to say".
  static const int _minimumDenominator = 8;

  /// Series colours, stepped per mode and kept clear of the hues the other
  /// mesh charts already use, so no colour ever means two things.
  static const Color _lightTone = Color(0xFF00695C);
  static const Color _darkTone = Color(0xFF35A093);
  static const Color _lightWarn = Color(0xFFB4531B);
  static const Color _darkWarn = Color(0xFFD4772F);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // Only the error rate is a fault; the rest are descriptions of a healthy
    // mesh and must not wear an alarm colour.
    final warn = ratio == MeshRatio.errors;
    final color = warn
        ? (dark ? _darkWarn : _lightWarn)
        : (dark ? _darkTone : _lightTone);

    final points = <(MeshMetricSample, double?)>[
      for (final sample in samples) (sample, _ratioOf(sample)),
    ];
    final known = [for (final (_, v) in points) ?v];
    if (known.length < 2) return const MeshChartEmpty();

    var sum = 0.0, peak = 0.0;
    for (final v in known) {
      sum += v;
      if (v > peak) peak = v;
    }
    final average = sum / known.length;
    final latest = known.last;

    // A percentage axis that follows the data: relay shares run near 100 and
    // error rates near 0, and pinning both to 0–100 would flatten one of them
    // into the axis. Floored at 10 so a quiet metric is not magnified.
    final ceiling = peak <= 10 ? 10.0 : (peak * 1.15).clamp(0, 100).toDouble();

    return MeshChart(
      legend: [
        MeshChartLegendEntry(
          color: color,
          label: _label(l10n),
          // l10n-ignore: percentage readout
          text: '${latest.toStringAsFixed(latest >= 10 ? 0 : 1)}%',
        ),
      ],
      stats: [
        // l10n-ignore: percentage readout
        (l10n.meshtasticStatAvg, '${average.toStringAsFixed(1)}%'),
        // l10n-ignore: percentage readout
        (l10n.meshtasticStatPeak, '${peak.toStringAsFixed(1)}%'),
      ],
      minY: 0,
      maxY: ceiling,
      // l10n-ignore: percentage axis tick
      leftLabel: (value) => '${value.round()}%',
      first: samples.first.at,
      last: samples.last.at,
      series: meshChartLine(
        [for (final (sample, _) in points) sample],
        _ratioOf,
        color,
        filled: true,
      ),
      tooltipUnit: '%',
      caption: _caption(l10n, average),
    );
  }

  /// This slice's ratio, or null when the slice cannot support one.
  double? _ratioOf(MeshMetricSample sample) {
    final (num, den) = switch (ratio) {
      MeshRatio.relayShare => (sample.lsTxRelay, sample.lsTx),
      MeshRatio.relayCompleted => (
        sample.lsTxRelay,
        _sum(sample.lsTxRelay, sample.lsTxRelayCancel),
      ),
      MeshRatio.duplicates => (sample.lsRxDupe, sample.lsRx),
      MeshRatio.errors => (sample.lsRxBad, _sum(sample.lsRx, sample.lsRxBad)),
    };
    if (den == null || den < _minimumDenominator) return null;
    // A missing numerator beside a known denominator is a zero, not an
    // unknown: the counters arrive as one block, so "we counted receptions but
    // not bad ones" means none were bad.
    return (num ?? 0) / den * 100;
  }

  /// Null only when *both* parts are missing — one absent counter next to a
  /// present one is a zero, not an unknown.
  static int? _sum(int? a, int? b) =>
      a == null && b == null ? null : (a ?? 0) + (b ?? 0);

  String _label(AppLocalizations l10n) => switch (ratio) {
    MeshRatio.relayShare => l10n.meshtasticStatRelayShare,
    MeshRatio.relayCompleted => l10n.meshtasticStatRelayValue,
    MeshRatio.duplicates => l10n.meshtasticStatRedundancy,
    MeshRatio.errors => l10n.meshtasticStatErrorRate,
  };

  /// One sentence saying what this shape means, because the number alone is
  /// only legible to someone who already knows the mesh's mechanics.
  String _caption(AppLocalizations l10n, double average) => switch (ratio) {
    MeshRatio.relayShare => l10n.meshtasticStatRelayShareHint,
    MeshRatio.relayCompleted =>
      average >= 90
          ? l10n.meshtasticStatRelaySolePath
          : l10n.meshtasticStatRelayRedundant,
    MeshRatio.duplicates =>
      average < 5
          ? l10n.meshtasticStatThinEdge
          : l10n.meshtasticStatWellCovered,
    MeshRatio.errors => l10n.meshtasticStatErrorRateHint,
  };

  /// The section title for this ratio.
  static String titleOf(MeshRatio ratio, AppLocalizations l10n) =>
      switch (ratio) {
        MeshRatio.relayShare => l10n.meshtasticStatRelayShare,
        MeshRatio.relayCompleted => l10n.meshtasticStatRelayValue,
        MeshRatio.duplicates => l10n.meshtasticStatRedundancy,
        MeshRatio.errors => l10n.meshtasticStatErrorRate,
      };
}
