import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The name of a fact's kind, shown before its value.
String eventFactKindLabel(EventFactKind kind, AppLocalizations l10n) =>
    switch (kind) {
      EventFactKind.magnitude => l10n.eventFactMagnitude,
      EventFactKind.depth => l10n.eventFactDepth,
      EventFactKind.maxIntensity => l10n.eventFactMaxIntensity,
      EventFactKind.epicenter => l10n.eventFactEpicenter,
      EventFactKind.originTime => l10n.eventFactOriginTime,
      EventFactKind.serial => l10n.eventFactSerial,
      EventFactKind.waveHeight => l10n.eventFactWaveHeight,
      EventFactKind.arrivalTime => l10n.eventFactArrivalTime,
      EventFactKind.rainfall => l10n.eventFactRainfall,
      EventFactKind.windSpeed => l10n.eventFactWindSpeed,
      EventFactKind.gust => l10n.eventFactGust,
      EventFactKind.visibility => l10n.eventFactVisibility,
      EventFactKind.waterLevel => l10n.eventFactWaterLevel,
      EventFactKind.warningLevel => l10n.eventFactWarningLevel,
      EventFactKind.lightningStrikes => l10n.eventFactLightningStrikes,
      EventFactKind.road => l10n.eventFactRoad,
      EventFactKind.location => l10n.eventFactLocation,
      EventFactKind.station => l10n.eventFactStation,
    };

/// One headline fact of a report as a chip: its kind's name, then its value.
///
/// A maximum intensity is filled with the CWA intensity colour of its level,
/// the same colour the earthquake pages use for it; every other fact sits on
/// a neutral surface.
class EventFactChip extends StatelessWidget {
  const EventFactChip({super.key, required this.fact});

  /// The fact shown.
  final EventFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final level = fact.intensityLevel;
    final fill = level == null
        ? colors.surfaceContainerHighest
        : IntensityColors.discrete(level);
    final ink = level == null
        ? colors.onSurface
        : IntensityColors.onDiscrete(level);
    final label = eventFactKindLabel(fact.kind, AppLocalizations.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(color: ink.withValues(alpha: 0.8)),
              ),
              TextSpan(
                text: fact.display,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: theme.textTheme.labelMedium?.copyWith(color: ink),
        ),
      ),
    );
  }
}
