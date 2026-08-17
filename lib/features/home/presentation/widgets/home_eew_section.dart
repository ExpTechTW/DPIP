/// Live EEW alert section for the home sheet — the highest-priority card on the
/// dashboard, shown only while an alert is actually active.
///
/// Consumes the feed through its **core** supertype [RealtimeNotifier] (which
/// `earthquakeProviders` also registers), so this feature never imports the
/// earthquake feature's presentation — same seam the map's RTS layer uses. The
/// card's numbers come from the shared domain math (`estimateLocalShaking`), the
/// same source the earthquake monitor's card uses, so the two can't drift.
///
/// Gated on feed liveness as well as alert presence: a stale/offline feed's
/// alerts may no longer describe the current situation, and a safety feed that
/// aged out must never present its last snapshot as now. Calm state (no alert,
/// or an unverified feed) renders nothing at all, so the sheet's ordinary layout
/// is untouched outside an earthquake.
library;

import 'dart:async';

import 'package:dpip/shared/widgets/second_ticker.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_local_estimate.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/eew_estimate_tile.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// A live EEW alert block: a small header row and the primary alert's card.
/// Tapping the card opens the full earthquake monitor ([AppRoutes.eew]).
class HomeEewSection extends StatelessWidget {
  const HomeEewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RealtimeNotifier<List<Eew>>>();
    final state = controller.state;
    final alerts = state.data;
    // No alert, or a feed that has aged past live — render nothing. This keeps
    // the stale case from ever masquerading as a current alert on the home
    // surface (the monitor page shows the freshness banner instead).
    if (state.status != RealtimeStatus.live ||
        alerts == null ||
        alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    return _EewSectionBody(alert: alerts.first);
  }
}

class _EewSectionBody extends StatelessWidget {
  const _EewSectionBody({required this.alert});

  final Eew alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_outlined, size: 18, color: colors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.eewTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.eewSerial(alert.serial),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.pushNamed(AppRoutes.eew),
            child: _EewAlertCard(alert: alert),
          ),
        ),
      ],
    );
  }
}

/// The home sheet's alert card — a condensed version of the monitor page's
/// `EewCard`, sharing its domain math. The S-wave countdown ticks against the
/// calibrated [AppTime] clock and stops updating on dispose.
class _EewAlertCard extends StatefulWidget {
  const _EewAlertCard({required this.alert});

  final Eew alert;

  @override
  State<_EewAlertCard> createState() => _EewAlertCardState();
}

class _EewAlertCardState extends State<_EewAlertCard> with SecondTicker {
  /// The home shell wraps hidden tabs in `TickerMode(enabled: false)`; a
  /// Timer is not a Ticker, so without this gate the countdown kept rebuilding
  /// behind whichever tab the user switched to during an alert.
  @override
  bool get secondTickerActive => TickerMode.valuesOf(context).enabled;

  /// The CWA P/S travel-time table once it resolves — the countdown settles on
  /// the table's arrival time the moment it loads (see [estimateLocalShaking]).
  SeismicTravelTimeTable? _table;

  /// The user's GPS fix, resolved once on mount — the estimate is for where
  /// the user actually is, not the selected township's centroid.
  LatLng? _fix;

  @override
  void initState() {
    super.initState();
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        // Unlike the 地震頁 list (every row is already an EEW card, so the
        // colour would be redundant), this one sits on the home dashboard
        // among unrelated sections — it needs to stand out on its own, so it
        // keeps the severity border the map monitor's card also carries.
        side: BorderSide(
          color: IntensityColors.discrete(maxIntensity.colorLevel),
          width: 2,
        ),
      ),
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
        ),
      ),
    );
  }
}
