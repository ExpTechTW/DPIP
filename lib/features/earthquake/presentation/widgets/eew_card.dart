/// A single EEW alert card: report serial + max-intensity badge, epicentre
/// location with its magnitude and depth, and — when a township is selected —
/// the estimated local intensity and a live S-wave arrival countdown.
///
/// [EewCard] (a plain [Card] frame around [EewCardContent]) is used by the
/// live [EarthquakePage] monitor. The report replay page's map overlay needs
/// a different frame (tappable, bordered, with a cycle-count chip), so it
/// wraps [EewCardContent] directly instead of duplicating the header/tiles —
/// see `_EewAlertCard` in `report_replay_page.dart`. The map monitor overlay
/// and the home sheet's realtime section can't reuse this widget at all (the
/// layering gate forbids `features/map`/`features/home` importing another
/// feature's presentation) — they carry their own condensed copies
/// (`MonitorEewCard`, `home_eew_section.dart`).
///
/// The local shaking estimate comes from the same pure [EewEstimator] math
/// the hazard overlays use; the countdown ticks against the calibrated
/// [AppTime] clock (or the caller's own — the replay page passes its
/// [ReplayClock]), so the seconds are right even if the device clock drifts.
library;

import 'dart:async';

import 'package:dpip/shared/widgets/second_ticker.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_local_estimate.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/eew_estimate_tile.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EewCard extends StatelessWidget {
  const EewCard({super.key, required this.eew, this.clock});

  final Eew eew;

  /// The instant the S-wave countdown is measured against — the calibrated
  /// wall clock ([AppTime.utc]) by default for live pages; the replay page
  /// passes its [ReplayClock] so a historical alert counts down from its own
  /// timeline instead of being compared to real now (which is always after the
  /// event, so the arrival would read as long past).
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      // No colour-coded border here — 強震監視器 (the map monitor and its
      // replay, "frozen in time") already carries that signal; this is the
      // calmer 地震速報 list, so a plain rounded card (still [AppRadius.medium],
      // matching the other three EEW cards) is enough.
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EewCardContent(eew: eew, clock: clock),
      ),
    );
  }
}

/// The card's content only — no outer [Card]/margin — so a caller that needs
/// a different frame can reuse the same header/tiles instead of duplicating
/// them (see the file doc).
class EewCardContent extends StatefulWidget {
  const EewCardContent({
    super.key,
    required this.eew,
    this.clock,
    this.trailing,
  });

  final Eew eew;

  /// The instant the S-wave countdown is measured against — see [EewCard.clock].
  final DateTime Function()? clock;

  /// An extra widget in the header row, before the intensity badge — the
  /// replay page's "n/total" cycle chip.
  final Widget? trailing;

  @override
  State<EewCardContent> createState() => _EewCardContentState();
}

class _EewCardContentState extends State<EewCardContent> with SecondTicker {
  /// The CWA P/S travel-time table once it resolves — the countdown settles on
  /// the table's arrival time the moment it loads (see [estimateLocalShaking]).
  SeismicTravelTimeTable? _table;

  /// The user's GPS fix, resolved once on mount — the countdown/intensity are
  /// estimated from where the user actually is (legacy's
  /// `GlobalProviders.location.coordinates`), not the selected township's
  /// centroid. Falls back to the centroid when no fix is available.
  LatLng? _fix;

  @override
  void initState() {
    super.initState();
    // The per-second countdown rebuild lives in [SecondTicker], which stops
    // it while the app is hidden — an alert under the lock screen must not
    // keep the CPU on a 1 s leash.
    context.read<Future<SeismicTravelTimeTable>>().then((table) {
      if (mounted) setState(() => _table = table);
    });
    context.read<LocationService>().currentFix().then((fix) {
      if (mounted && fix != null) {
        setState(() => _fix = LatLng(fix.lat, fix.lng));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final info = widget.eew.info;

    // The observer point is the user's GPS fix when one is available, else the
    // selected township's centroid — same resolution the home weather uses.
    // 全國 (or 所在地 without a GPS fix) has no point to estimate for, so the
    // local tiles drop rather than invent one. GPS-first matches legacy, which
    // estimated from `GlobalProviders.location.coordinates`.
    final store = context.watch<RegionStore>();
    final code = switch (store.selected) {
      SavedArea(:final code) => code,
      CurrentArea(:final code) => code,
      NationwideArea() => null,
    };
    final town = code == null
        ? null
        : context.read<TownDirectory>().byCode(code);
    final observer = _fix ?? (town == null ? null : LatLng(town.lat, town.lng));
    final estimate = observer == null
        ? null
        : estimateLocalShaking(widget.eew, observer, table: _table);

    final originUtc = DateTime.fromMillisecondsSinceEpoch(info.time);
    final maxIntensity = Intensity.displayForReport(info.max, originUtc);
    final now = widget.clock?.call() ?? AppTime.utc;
    final remaining = estimate == null
        ? null
        : originUtc
              .add(Duration(seconds: estimate.sArrivalSeconds))
              .difference(now)
              .inSeconds;

    final arrived = remaining != null && remaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 15, color: colors.error),
            const SizedBox(width: 4),
            Text(
              'EEW',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.eewSerial(widget.eew.serial),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              widget.trailing!,
              const SizedBox(width: AppSpacing.sm),
            ],
            IntensityBadge(
              label: maxIntensity.label,
              color: IntensityColors.discrete(maxIntensity.colorLevel),
              size: 32,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                info.location,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.eewSummary(
                info.magnitude.toStringAsFixed(1),
                info.depth.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (estimate != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: EewEstimateTile(
                  label: l10n.eewLocalIntensity,
                  value: Intensity.label(estimate.scale),
                  background: IntensityColors.discrete(estimate.scale),
                  foreground: IntensityColors.onDiscrete(estimate.scale),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: EewEstimateTile(
                  label: l10n.eewSWave,
                  value: arrived
                      ? l10n.eewArrived
                      : l10n.eewCountdown(remaining ?? 0),
                  background: EewEstimateTile.alertRed(),
                  foreground: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
