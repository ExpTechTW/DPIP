/// The 強震監視器's EEW alert card — a condensed version of the earthquake
/// monitor's `EewCard`, sharing its domain math (`estimateLocalShaking`) and
/// its tile styling (`EewEstimateTile`), so the map overlay's numbers and
/// colours can never drift from the monitor's. The S-wave countdown ticks
/// against the calibrated [AppTime] clock and stops on dispose.
///
/// Lives in this feature (not `features/earthquake`) because the layering gate
/// forbids `features/map` importing another feature's presentation; the home
/// sheet's realtime section makes the same trade for the same reason.
library;

import 'dart:async';

import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
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
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/eew_estimate_tile.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One live EEW alert in the monitor's overlay sheet — compact so the map stays
/// visible around it.
class MonitorEewCard extends StatefulWidget {
  const MonitorEewCard({super.key, required this.alert});

  final Eew alert;

  @override
  State<MonitorEewCard> createState() => _MonitorEewCardState();
}

class _MonitorEewCardState extends State<MonitorEewCard> with SecondTicker {
  /// The RTS panel's own gate suppresses feed-notify rebuilds behind other
  /// tabs, but the countdown has its own timer — same gate here.
  @override
  bool get secondTickerActive =>
      VisibleTabScope.of(context)?.isOnScreen(MapPage.tabIndex) ?? true;

  /// The CWA P/S travel-time table once it resolves — the countdown settles on
  /// the table's arrival time the moment it loads (see [estimateLocalShaking]).
  SeismicTravelTimeTable? _table;

  /// The user's GPS fix, resolved once on mount — the estimate is for where
  /// the user actually is, not the selected township's centroid.
  LatLng? _fix;

  @override
  void initState() {
    super.initState();
    // The per-second countdown rebuild lives in [SecondTicker]; the gate
    // above stops it behind other tabs and under the lock screen.
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
    final info = widget.alert.info;

    // The observer point is the user's GPS fix when one is available, else the
    // selected township's centroid — same resolution the home weather uses.
    // 全國 (or 所在地 without a GPS fix) has no point to estimate for, so the
    // local tiles drop rather than invent one.
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
        : estimateLocalShaking(widget.alert, observer, table: _table);

    final originUtc = DateTime.fromMillisecondsSinceEpoch(info.time);
    final maxIntensity = Intensity.displayForReport(info.max, originUtc);
    final remaining = estimate == null
        ? null
        : originUtc
              .add(Duration(seconds: estimate.sArrivalSeconds))
              .difference(AppTime.utc)
              .inSeconds;
    final arrived = remaining != null && remaining <= 0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                IntensityBadge(
                  label: maxIntensity.label,
                  color: IntensityColors.discrete(maxIntensity.colorLevel),
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.eewSummary(
                info.magnitude.toStringAsFixed(1),
                info.depth.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (estimate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: EewEstimateTile(
                      label: l10n.eewLocalIntensity,
                      value: Intensity.label(estimate.scale),
                      background: colors.primaryContainer,
                      foreground: colors.onPrimaryContainer,
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
        ),
      ),
    );
  }
}
