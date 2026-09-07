/// The 強震監視器's EEW alert card — a condensed version of the earthquake
/// monitor's `EewCard`, sharing its domain math (`estimateLocalShaking`) and
/// its tile styling (`EewEstimateTile`), so the map overlay's numbers and
/// colours can never drift from the monitor's. The S-wave countdown ticks
/// against the calibrated [AppTime] clock, pauses while the map tab is not the
/// selected branch, and stops on dispose.
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

/// One live EEW alert in the monitor's overlay sheet — compact so the map stays
/// visible around it. When [onTap] is set (the overlay has more than one active
/// alert to cycle through), the whole card is tappable and [trailing] carries
/// the "n/total" cycle chip — mirrors the report replay page's alert card.
class MonitorEewCard extends StatefulWidget {
  const MonitorEewCard({
    super.key,
    required this.alert,
    this.trailing,
    this.onTap,
  });

  final Eew alert;

  /// An extra widget in the header row, before the intensity badge.
  final Widget? trailing;

  /// Advances to the next alert; null when there is only one (or the overlay
  /// isn't meant to cycle).
  final VoidCallback? onTap;

  @override
  State<MonitorEewCard> createState() => _MonitorEewCardState();
}

class _MonitorEewCardState extends State<MonitorEewCard> with SecondTicker {
  /// The RTS panel's own gate suppresses feed-notify rebuilds behind other
  /// tabs, but the countdown has its own timer — same gate here.
  ///
  /// Deliberately the tab test only, not [VisibleTab.isOnScreen], and for a
  /// sharper reason than [RefreshOnAppear]'s: `isOnScreen` also goes false for
  /// *any* root-navigator push, and `showDialog` defaults to that navigator
  /// while painting a translucent barrier. Gating on it would freeze a live
  /// S-wave countdown at whatever second it held, in full view around the
  /// dialog — a stale safety number presented as current. An unselected branch
  /// is genuinely unpainted (`_RenderIndexedStack` paints only the selected
  /// child), so the branch test alone carries the whole saving safely.
  @override
  bool get secondTickerActive =>
      (_visibleTab?.value ?? MapPage.tabIndex) == MapPage.tabIndex;

  /// The shell's visible-tab notifier, subscribed to rather than merely read.
  ///
  /// [SecondTicker] re-reads [secondTickerActive] on every [syncSecondTicker],
  /// so the gate is not latched — but nothing *calls* that sync on a tab
  /// change, because [VisibleTabScope] hands the same instance down for the
  /// page's whole life and so never notifies its dependents. Reading the scope
  /// is how a consumer finds the notifier; only the subscription is a change
  /// signal. Before this, the timer stayed in whatever state the lifecycle
  /// edges last left it in. The panel that hosts this card subscribes the same
  /// way for the same reason.
  VisibleTab? _visibleTab;

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
  void didChangeDependencies() {
    // Ahead of `super`, which runs [SecondTicker]'s own first sync: the gate
    // above has to find the notifier before it is evaluated, or that sync
    // reads the null fallback and starts the timer on a hidden card.
    final visibleTab = VisibleTabScope.of(context);
    if (!identical(visibleTab, _visibleTab)) {
      _visibleTab?.removeListener(syncSecondTicker);
      _visibleTab = visibleTab;
      visibleTab?.addListener(syncSecondTicker);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _visibleTab?.removeListener(syncSecondTicker);
    super.dispose();
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
    final code = context.watch<RegionStore>().selectedCode;
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
        // The border reads off the same discrete scale as the badge — a
        // calm/low reading stays close to the neutral outline it replaces,
        // a severe one is unmistakable before you even read the number.
        side: BorderSide(
          color: IntensityColors.discrete(maxIntensity.colorLevel),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
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
                  if (widget.trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    widget.trailing!,
                  ],
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
      ),
    );
  }
}
