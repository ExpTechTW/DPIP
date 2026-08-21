/// The 強震監視器 overlay UI: the active EEW alert as a card (tap to cycle
/// through more than one, same as the report replay page's map overlay) above
/// a bottom freshness strip showing the feed status, the snapshot time, and the
/// live latency (s). The intensity legend lives on the scaffold via
/// [MapLayer.buildLegend].
library;

import 'dart:async';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/build/demo_flags.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_local_estimate.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/map/presentation/monitor_eew_announcement_controller.dart';
import 'package:dpip/features/map/presentation/widgets/monitor_eew_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/alert_cycle_chip.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:dpip/shared/seismic/spoken_intensity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The RTS layer's overlay, laid over the full map (via the scaffold's
/// `buildSheet` slot): the active EEW alert card above a freshness strip at
/// the bottom. Small so the map stays visible and interactive above it.
class RtsMonitorPanel extends StatefulWidget {
  const RtsMonitorPanel({
    super.key,
    required this.feed,
    required this.eew,
    required this.eewIndex,
  });

  final RealtimeNotifier<Rts> feed;
  final RealtimeNotifier<List<Eew>> eew;

  /// Which active alert the card shows — owned by [RtsMapLayer], not this
  /// widget, because the map's own area fill has to track the same
  /// selection (see `RtsMapLayer._updateAreaFill`).
  final ValueNotifier<int> eewIndex;

  /// Roughly how much of the map height the bottom status strip covers at rest.
  /// Declared (not measured) because the strip is a floating overlay, not a
  /// bounded child the scaffold can size; the map subtracts it when framing.
  static const double bottomStripFraction = 0.1;

  /// …and the whole stack (status strip + the single alert card) while an
  /// alert is active — deliberate framing subtracts this so an epicentre is
  /// never framed behind its own alert.
  static const double expandedBottomFraction = 0.45;

  @override
  State<RtsMonitorPanel> createState() => _RtsMonitorPanelState();
}

class _RtsMonitorPanelState extends State<RtsMonitorPanel>
    with WidgetsBindingObserver {
  /// Whether the map tab is the shell's visible one. The RTS feed keeps
  /// notifying at ~1 Hz behind other tabs (the polling itself must continue —
  /// it is a safety feed), but rebuilding a hidden panel for every poll is
  /// work nobody sees; a hidden notify becomes a no-op and the panel catches
  /// up in one build on return.
  bool _visible = true;
  VisibleTab? _visibleTab;
  MonitorEewAnnouncementController? _announcement;
  AppLocalizations? _l10n;
  String _languageTag = 'zh-TW';
  AppLifecycleState? _lifecycleState;
  bool _demoWarningSubmitted = false;

  void _onData() {
    _syncAnnouncement();
    if (_visible && mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    widget.feed.addListener(_onData);
    widget.eew.addListener(_onData);
    widget.eewIndex.addListener(_onData);
  }

  @override
  void didUpdateWidget(RtsMonitorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.feed, widget.feed)) {
      oldWidget.feed.removeListener(_onData);
      widget.feed.addListener(_onData);
    }
    if (!identical(oldWidget.eew, widget.eew)) {
      oldWidget.eew.removeListener(_onData);
      widget.eew.addListener(_onData);
    }
    if (!identical(oldWidget.eewIndex, widget.eewIndex)) {
      oldWidget.eewIndex.removeListener(_onData);
      widget.eewIndex.addListener(_onData);
    }
    _syncAnnouncement();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    _languageTag = Localizations.localeOf(context).toLanguageTag();
    _announcement ??= _createAnnouncementController();
    final visibleTab = VisibleTabScope.of(context);
    if (!identical(visibleTab, _visibleTab)) {
      _visibleTab?.removeListener(_syncVisibility);
      _visibleTab = visibleTab;
      visibleTab?.addListener(_syncVisibility);
      _syncVisibility();
    }
    _syncAnnouncement();
  }

  MonitorEewAnnouncementController? _createAnnouncementController() {
    // Nullable reads keep this leaf widget independently testable; the app's
    // core provider list always supplies both services.
    final speech = context.read<SpeechService?>();
    final notifications = context.read<NotificationService?>();
    if (speech == null || notifications == null) return null;
    final location = context.read<LocationService>();
    return MonitorEewAnnouncementController(
      speech,
      notifications.foregroundEewGate,
      (alert) async {
        // A warning cannot wait on a live GPS timeout. Use the OS's recent
        // cached fix; when none is fresh enough, announce the EEW max instead.
        final fix = await location.lastKnownFix();
        if (fix == null) {
          return (scale: alert.info.max.clamp(0, 9), isLocal: false);
        }
        final estimate = estimateLocalShaking(alert, LatLng(fix.lat, fix.lng));
        return (scale: estimate.scale, isLocal: true);
      },
    );
  }

  void _syncVisibility() {
    final visible = _visibleTab?.isOnScreen(MapPage.tabIndex) ?? true;
    if (visible == _visible) return;
    _visible = visible;
    _syncAnnouncement();
    // Coming back: one build to catch up on everything missed while hidden.
    if (visible && mounted) setState(() {});
  }

  /// Sound must use a stricter visibility check than rendering. This widget
  /// can be mounted before the shell installs [VisibleTabScope], and treating
  /// that transient state as visible would announce an alert from a map branch
  /// the user has not opened yet.
  bool get _isMonitorOnScreen =>
      _visibleTab?.isOnScreen(MapPage.tabIndex) ?? false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncAnnouncement();
  }

  void _syncAnnouncement() {
    final controller = _announcement;
    final l10n = _l10n;
    if (controller == null || l10n == null) return;
    final foreground =
        _lifecycleState == null || _lifecycleState == AppLifecycleState.resumed;
    controller.setActive(_isMonitorOnScreen && foreground);
    controller.update(
      widget.eew.state,
      languageTag: _languageTag,
      format: (estimate) {
        final intensity = spokenIntensityLabel(estimate.scale, _languageTag);
        return estimate.isLocal
            ? l10n.eewSpokenLocalIntensity(intensity)
            : l10n.eewSpokenMaxIntensity(intensity);
      },
    );
    _submitDemoWarning(l10n);
  }

  void _submitDemoWarning(AppLocalizations l10n) {
    final foreground =
        _lifecycleState == null || _lifecycleState == AppLifecycleState.resumed;
    if (!kMonitorDemoSoundEnabled ||
        _demoWarningSubmitted ||
        !_isMonitorOnScreen ||
        !foreground) {
      return;
    }
    final state = widget.eew.state;
    final alerts = state.data;
    if (state.status != RealtimeStatus.live ||
        alerts == null ||
        alerts.isEmpty) {
      return;
    }
    _demoWarningSubmitted = true;
    final intensity = spokenIntensityLabel(
      alerts.first.info.max.clamp(0, 9),
      _languageTag,
    );
    unawaited(
      context.read<NotificationService>().showDebugEewWarning(
        title: l10n.mapLayerMonitor,
        body: l10n.eewSpokenMaxIntensity(intensity),
      ),
    );
  }

  @override
  void dispose() {
    widget.feed.removeListener(_onData);
    widget.eew.removeListener(_onData);
    widget.eewIndex.removeListener(_onData);
    _visibleTab?.removeListener(_syncVisibility);
    WidgetsBinding.instance.removeObserver(this);
    _announcement?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EewAlert(
                eew: widget.eew,
                index: widget.eewIndex.value,
                onCycle: (next) => widget.eewIndex.value = next,
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatusBar(state: widget.feed.state, eew: widget.eew),
            ],
          ),
        ),
      ),
    );
  }
}

/// One active EEW alert as a card — tapping it cycles through the rest of the
/// active set (parallel earthquakes, overlapping reports), same UX as the
/// report replay page's map overlay. Renders nothing when calm or when the
/// feed has aged past live — a stale alert must never be presented as a
/// current one.
class _EewAlert extends StatelessWidget {
  const _EewAlert({
    required this.eew,
    required this.index,
    required this.onCycle,
  });

  final RealtimeNotifier<List<Eew>> eew;

  /// Which alert to show; clamped modulo the active count below, so a report
  /// leaving the set mid-cycle can't point past the list.
  final int index;

  /// Reports the next index to show once the card is tapped.
  final ValueChanged<int> onCycle;

  @override
  Widget build(BuildContext context) {
    final state = eew.state;
    final alerts = state.data;
    if (state.status != RealtimeStatus.live ||
        alerts == null ||
        alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    final current = index % alerts.length;
    return MonitorEewCard(
      alert: alerts[current],
      trailing: alerts.length > 1
          ? AlertCycleChip(position: current + 1, count: alerts.length)
          : null,
      onTap: alerts.length > 1
          ? () => onCycle((current + 1) % alerts.length)
          : null,
    );
  }
}

/// A compact bottom card: status dot + title + the snapshot time, then the live
/// latency in seconds (or the feed status word when not live). While an EEW
/// alert is active it turns red-on-`errorContainer` as a whole — the legacy
/// monitor's `MorphingSheet` did the same (`borderColor`/`backgroundColor` on
/// `activeEew.isNotEmpty`, binary rather than scaled by severity) — so the
/// strip reads as urgent even collapsed, not just the card above it.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state, required this.eew});

  final RealtimeState<Rts> state;
  final RealtimeNotifier<List<Eew>> eew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasActiveEew =
        eew.state.status == RealtimeStatus.live &&
        (eew.state.data?.isNotEmpty ?? false);

    final time = state.data?.time ?? 0;
    final hasData = time != 0;

    // Snapshot wall-clock (UTC+8) and the feed's latency behind the SNTP-
    // corrected clock — both on the server clock, so the lag is device-skew
    // immune. Latency floored at 0 against sub-sync jitter.
    final dataTime = hasData
        ? DateFormat('HH:mm:ss').format(
            AppTime.taipei(
              DateTime.fromMillisecondsSinceEpoch(time, isUtc: true),
            ),
          )
        : null;
    final raw = AppTime.utc.millisecondsSinceEpoch - time;
    final int? delayMs = hasData ? (raw < 0 ? 0 : raw) : null;

    // Freshness is spoken as text (not colour alone, for colour-blind users).
    // Only a *live* feed shows a latency (green < 1 s, orange < 2 s, red beyond);
    // stale/offline/connecting show the status word instead.
    final (
      Color dot,
      String trailing,
      Color trailingColor,
    ) = switch (state.status) {
      RealtimeStatus.live => (
        Colors.green,
        delayMs == null
            ? l10n.monitorWaiting
            : l10n.monitorDelay((delayMs / 1000).toStringAsFixed(1)),
        _delayColor(delayMs),
      ),
      RealtimeStatus.stale => (Colors.amber, l10n.feedStale, colors.tertiary),
      RealtimeStatus.offline => (Colors.red, l10n.feedOffline, colors.error),
      RealtimeStatus.connecting => (
        Colors.grey,
        l10n.feedConnecting,
        colors.onSurfaceVariant,
      ),
    };

    final onTint = hasActiveEew ? colors.onErrorContainer : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: hasActiveEew
            ? colors.errorContainer.withValues(alpha: 0.94)
            : colors.surface.withValues(alpha: 0.94),
        borderRadius: AppRadius.medium,
        border: hasActiveEew ? Border.all(color: colors.error, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          LegendDot(color: dot),
          const SizedBox(width: AppSpacing.sm),
          // Yields to the trailing readouts so a long locale or large text scale
          // ellipsises the title instead of overflowing the row.
          Expanded(
            child: Text(
              l10n.mapLayerMonitor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: onTint,
              ),
            ),
          ),
          if (dataTime != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              dataTime,
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: onTint ?? colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onTint ?? trailingColor,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// The latency reading's colour by how far behind the feed is: green under
  /// 1 s, orange under 2 s, red beyond.
  Color _delayColor(int? ms) {
    if (ms == null) return Colors.grey;
    if (ms < 1000) return Colors.green;
    if (ms < 2000) return Colors.orange;
    return Colors.red;
  }
}
