/// The permission checklist: one row per grant, each showing its state and
/// offering the only action that can still change it.
///
/// Shared because it is read twice — once during onboarding, and later from
/// **更多 → 權限檢查**, where it is the answer to "why did I not get an alert".
/// A checklist that only exists on first launch is a checklist nobody can
/// consult on the day it matters.
///
/// Every row goes through the same path: ask, and when the system will not ask
/// again, say so and offer to open its settings. Both platforms prompt once, so
/// a row that only re-requests is a button that visibly does nothing — which is
/// how this screen used to dead-end.
library;

import 'dart:async';
import 'dart:io';

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/permissions/system_settings.dart';
import 'package:dpip/core/platform/background_execution.dart';
import 'package:dpip/core/platform/battery_optimization.dart';
import 'package:dpip/core/platform/unused_app_restrictions.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _PermissionItem {
  notify,
  critical,
  location,
  background,
  execution,
  battery,
  unusedApp,
  vendor,
}

enum PermissionRowFeedback { stillNeeded, verifyManually }

/// What the checklist currently sees, so a host can react to it — onboarding
/// nudges before finishing, the standalone page shows a summary.
class PermissionState {
  const PermissionState({
    required this.notify,
    required this.critical,
    required this.location,
    required this.background,
    required this.battery,
  });

  final bool notify;
  final bool critical;
  final bool location;
  final bool background;
  final bool battery;

  /// The two that localized alerting cannot work without.
  bool get essentialsGranted => notify && location;
}

class PermissionChecklist extends StatefulWidget {
  const PermissionChecklist({super.key, this.onChanged});

  /// Called after every re-check, so the host can update around it.
  final ValueChanged<PermissionState>? onChanged;

  @override
  State<PermissionChecklist> createState() => _PermissionChecklistState();
}

class _PermissionChecklistState extends State<PermissionChecklist>
    with WidgetsBindingObserver {
  final BatteryOptimization _battery = BatteryOptimization();
  final UnusedAppRestrictionsService _unusedApp =
      UnusedAppRestrictionsService();
  final BackgroundExecutionService _execution = BackgroundExecutionService();

  bool _notify = false;
  bool _critical = false;
  bool _location = false;
  bool _background = false;
  bool _batteryOk = false;

  /// Whether Android will hibernate the app and revoke its permissions.
  /// Starts at [UnusedAppRestrictions.unavailable] so the row stays hidden
  /// until the platform has actually answered — showing a warning for one
  /// frame on a device that turns out to be exempt is worse than showing it
  /// a frame late.
  UnusedAppRestrictions _unusedAppStatus = UnusedAppRestrictions.unavailable;

  /// Whether the OS will run background work at all, and what the vendor adds
  /// on top. Starts unknown for the same reason as above — every field defaults
  /// to the healthy answer, so nothing is accused before the platform speaks.
  BackgroundExecutionStatus _executionStatus =
      const BackgroundExecutionStatus();

  _PermissionItem? _busy;
  _PermissionItem? _awaitingReturn;
  _PermissionItem? _feedbackItem;
  PermissionRowFeedback? _feedback;
  int _refreshEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Every grant that cannot be made in-app is made in system settings, so
    // coming back is the moment to look again.
    if (state != AppLifecycleState.resumed) return;
    final pending = _awaitingReturn;
    unawaited(_refresh(feedbackFor: pending));
  }

  Future<void> _refresh({_PermissionItem? feedbackFor}) async {
    final epoch = ++_refreshEpoch;
    Log.debug('permission: refreshing');
    final notifications = context.read<NotificationService>();
    final location = context.read<LocationService>();
    final notify = await notifications.isAllowed();
    final critical = Platform.isIOS
        ? await notifications.criticalAllowed()
        : false;
    final locationGranted = await location.granted();
    final backgroundGranted = await location.backgroundGranted();
    final batteryOk = Platform.isAndroid ? await _battery.isIgnoring() : true;
    final unusedApp = await _unusedApp.status();
    final execution = await _execution.status();
    if (!mounted || epoch != _refreshEpoch) return;
    Log.info(
      'permission state: notify=$notify critical=$critical '
      'location=$locationGranted background=$backgroundGranted '
      'battery=$batteryOk unusedApp=${unusedApp.name} '
      'bgExec=${execution.restricted ? "restricted" : "ok"} '
      'bucket=${execution.standbyBucket} vendor=${execution.manufacturer}',
    );
    // The shell's badge reads PermissionHealth, not this widget's private copy,
    // so without this the page would show a fresh grant while the dot stayed
    // up — the two surfaces disagreeing about the same fact.
    unawaited(context.read<PermissionHealth>().refresh());
    final satisfied = _isSatisfied(
      feedbackFor,
      notify: notify,
      critical: critical,
      location: locationGranted,
      background: backgroundGranted,
      execution: execution,
      battery: batteryOk,
      unusedApp: unusedApp,
    );
    setState(() {
      _notify = notify;
      _critical = critical;
      _location = locationGranted;
      _background = backgroundGranted;
      _batteryOk = batteryOk;
      _unusedAppStatus = unusedApp;
      _executionStatus = execution;
      _busy = null;
      _awaitingReturn = null;
      if (feedbackFor == _PermissionItem.vendor) {
        _feedbackItem = feedbackFor;
        _feedback = PermissionRowFeedback.verifyManually;
      } else if (feedbackFor != null) {
        _feedbackItem = satisfied ? null : feedbackFor;
        _feedback = satisfied ? null : PermissionRowFeedback.stillNeeded;
      } else if (_feedbackItem != null &&
          _isSatisfied(
            _feedbackItem,
            notify: notify,
            critical: critical,
            location: locationGranted,
            background: backgroundGranted,
            execution: execution,
            battery: batteryOk,
            unusedApp: unusedApp,
          )) {
        _feedbackItem = null;
        _feedback = null;
      }
    });
    widget.onChanged?.call(
      PermissionState(
        notify: notify,
        critical: critical,
        location: locationGranted,
        background: backgroundGranted,
        battery: batteryOk,
      ),
    );
  }

  bool _isSatisfied(
    _PermissionItem? item, {
    required bool notify,
    required bool critical,
    required bool location,
    required bool background,
    required BackgroundExecutionStatus execution,
    required bool battery,
    required UnusedAppRestrictions unusedApp,
  }) => switch (item) {
    _PermissionItem.notify => notify,
    _PermissionItem.critical => critical,
    _PermissionItem.location => location,
    _PermissionItem.background => background,
    _PermissionItem.execution => !execution.restricted,
    _PermissionItem.battery => battery,
    _PermissionItem.unusedApp => unusedApp == UnusedAppRestrictions.exempt,
    _PermissionItem.vendor || null => false,
  };

  void _begin(_PermissionItem item) {
    setState(() {
      _busy = item;
      if (_feedbackItem == item) {
        _feedbackItem = null;
        _feedback = null;
      }
    });
  }

  void _cancel(_PermissionItem item) {
    if (!mounted || _busy != item) return;
    setState(() => _busy = null);
  }

  Future<bool> _leaveForSettings(
    _PermissionItem item,
    Future<bool> Function() openSettings,
  ) async {
    _awaitingReturn = item;
    final opened = await openSettings();
    if (!opened && mounted && _awaitingReturn == item) {
      _awaitingReturn = null;
    }
    return opened;
  }

  /// Asks for a permission, and when the system will not ask again, says so
  /// and offers to open its settings.
  Future<void> _grant(
    _PermissionItem item,
    Future<PermissionOutcome> Function() request,
    Future<bool> Function() openSettings,
    String what,
    Future<PermissionSettingsGuide> Function() guide,
  ) async {
    // Logged end to end. A permission row that appears to do nothing has
    // several indistinguishable causes — the tap never arrived, the request
    // returned "granted" or "denied" so no dialog was due, the plugin never
    // answered, or something threw and the unawaited future swallowed it — and
    // none of them leave a trace by default.
    Log.info('permission[$what]: tapped');
    _begin(item);
    try {
      final outcome = await request();
      Log.info('permission[$what]: outcome = ${outcome.name}');
      if (!mounted) {
        Log.warning('permission[$what]: page gone before the outcome landed');
        return;
      }
      if (outcome == PermissionOutcome.needsSettings) {
        final settingsGuide = await guide();
        if (!mounted) return;
        _begin(item);
        var attempted = false;
        final opened = await promptForSystemSettings(
          context,
          what: what,
          guide: settingsGuide,
          openSettings: () {
            attempted = true;
            return _leaveForSettings(item, openSettings);
          },
        );
        if (!opened) {
          if (attempted) {
            await _refresh(feedbackFor: item);
          } else {
            _cancel(item);
          }
        }
        return;
      }
    } catch (error, stackTrace) {
      // Nothing awaits this handler, so without catching here an async failure
      // becomes an unhandled zone error and the button is simply inert.
      Log.handle(error, stackTrace, 'permission[$what]');
    }
    if (mounted) await _refresh();
  }

  Future<void> _grantNotify() {
    final notifications = context.read<NotificationService>();
    final l10n = AppLocalizations.of(context);
    return _grant(
      _PermissionItem.notify,
      notifications.requestPermission,
      notifications.openSystemSettings,
      l10n.onboardingPermNotify,
      () async => PermissionSettingsGuide(
        instruction: l10n.permissionGuideNotification,
      ),
    );
  }

  /// The critical alert is a separate iOS grant, so it needs its own request —
  /// asking for it as part of the ordinary one meant the row did nothing once
  /// notifications were already allowed.
  ///
  /// It can also be refused with no prompt at all, because it depends on an
  /// entitlement Apple grants per team; the dialog is then the only thing that
  /// tells the user anything happened.
  Future<void> _grantCritical() {
    final notifications = context.read<NotificationService>();
    final l10n = AppLocalizations.of(context);
    return _grant(
      _PermissionItem.critical,
      notifications.requestCritical,
      notifications.openSystemSettings,
      l10n.onboardingPermCritical,
      () async => PermissionSettingsGuide(
        instruction: l10n.permissionGuideNotification,
      ),
    );
  }

  // Foreground location only. Background ("Always") is a SEPARATE step —
  // Android 11+ silently denies both if they're requested in the same gesture.
  Future<void> _grantLocation() {
    final location = context.read<LocationService>();
    final l10n = AppLocalizations.of(context);
    return _grant(
      _PermissionItem.location,
      location.requestPermission,
      location.openSettings,
      l10n.onboardingPermLocation,
      () async => PermissionSettingsGuide(
        instruction: l10n.permissionGuideForegroundLocation,
      ),
    );
  }

  // Background ("Always"): only meaningful after foreground is granted; on
  // Android 11+ and on iOS after "While Using" it lives only in Settings, so
  // this almost always ends in the dialog rather than a prompt.
  Future<void> _grantBackground() {
    final location = context.read<LocationService>();
    final l10n = AppLocalizations.of(context);
    return _grant(
      _PermissionItem.background,
      location.requestBackground,
      location.openSettings,
      l10n.onboardingPermBackground,
      () async {
        final option =
            await backgroundLocationOptionLabel() ??
            l10n.permissionBackgroundLocationOption;
        return PermissionSettingsGuide(
          instruction: l10n.permissionGuideBackgroundLocation(option),
        );
      },
    );
  }

  Future<void> _grantBattery() async {
    const item = _PermissionItem.battery;
    _begin(item);
    final opened = await _leaveForSettings(item, _battery.request);
    if (!opened && mounted) await _refresh(feedbackFor: item);
  }

  Future<void> _exemptUnusedApp() async {
    final l10n = AppLocalizations.of(context);
    final instruction = switch (await _unusedApp.guide()) {
      UnusedAppSettingsGuide.pause => l10n.permissionGuideUnusedPause,
      UnusedAppSettingsGuide.freeSpace => l10n.permissionGuideUnusedFreeSpace,
      UnusedAppSettingsGuide.revoke => l10n.permissionGuideUnusedRevoke,
      UnusedAppSettingsGuide.playProtect =>
        l10n.permissionGuideUnusedPlayProtect,
    };
    await _openGuidedSettings(
      _PermissionItem.unusedApp,
      l10n.onboardingPermUnusedApp,
      PermissionSettingsGuide(instruction: instruction),
      _unusedApp.openSettings,
    );
  }

  /// The manufacturer as a person would write it. `Build.MANUFACTURER` is not
  /// display text — it arrives as `samsung`, `HUAWEI`, `Xiaomi` — and this
  /// string is read inside a sentence, so it is title-cased rather than shown
  /// raw. Multi-word names keep every word capitalised.
  String get _vendorName {
    final raw = _executionStatus.manufacturer?.trim() ?? '';
    if (raw.isEmpty) return raw;
    return raw
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.length <= 1
              ? word.toUpperCase()
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Future<void> _openGuidedSettings(
    _PermissionItem item,
    String what,
    PermissionSettingsGuide guide,
    Future<bool> Function() openSettings,
  ) async {
    _begin(item);
    var attempted = false;
    final opened = await promptForSystemSettings(
      context,
      what: what,
      guide: guide,
      openSettings: () {
        attempted = true;
        return _leaveForSettings(item, openSettings);
      },
    );
    if (opened || !mounted) return;
    if (attempted) {
      await _refresh(feedbackFor: item);
    } else {
      _cancel(item);
    }
  }

  Future<void> _openExecutionSettings() {
    final l10n = AppLocalizations.of(context);
    return _openGuidedSettings(
      _PermissionItem.execution,
      l10n.onboardingPermBackgroundExec,
      PermissionSettingsGuide(
        instruction: l10n.permissionGuideBackgroundExecution,
      ),
      () async {
        final opened = await _execution.openSystemSettings();
        Log.info('permission[background execution]: opened $opened');
        return opened != 'none';
      },
    );
  }

  Future<void> _openVendorSettings() {
    final l10n = AppLocalizations.of(context);
    return _openGuidedSettings(
      _PermissionItem.vendor,
      l10n.onboardingPermVendorPower,
      PermissionSettingsGuide(
        instruction: l10n.permissionGuideVendorPower(_vendorName),
      ),
      () async {
        final opened = await _execution.openOemSettings();
        Log.info('permission[vendor power]: opened $opened');
        return opened != 'none';
      },
    );
  }

  bool _loading(_PermissionItem item) => _busy == item;

  PermissionRowFeedback? _rowFeedback(_PermissionItem item) =>
      _feedbackItem == item ? _feedback : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PermissionRow(
          icon: Icons.notifications_active_outlined,
          title: l10n.onboardingPermNotify,
          description: l10n.onboardingPermNotifyDesc,
          granted: _notify,
          loading: _loading(_PermissionItem.notify),
          blocked: _busy != null,
          feedback: _rowFeedback(_PermissionItem.notify),
          onGrant: _grantNotify,
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: AppSpacing.sm),
          PermissionRow(
            icon: Icons.notification_important_outlined,
            title: l10n.onboardingPermCritical,
            description: l10n.onboardingPermCriticalDesc,
            granted: _critical,
            loading: _loading(_PermissionItem.critical),
            blocked: _busy != null,
            feedback: _rowFeedback(_PermissionItem.critical),
            onGrant: _grantCritical,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        PermissionRow(
          icon: Icons.location_on_outlined,
          title: l10n.onboardingPermLocation,
          description: l10n.onboardingPermLocationDesc,
          granted: _location,
          loading: _loading(_PermissionItem.location),
          blocked: _busy != null,
          feedback: _rowFeedback(_PermissionItem.location),
          onGrant: _grantLocation,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Background ("Always") — a separate step, unlocked once foreground is on.
        PermissionRow(
          icon: Icons.my_location_outlined,
          title: l10n.onboardingPermBackground,
          description: l10n.onboardingPermBackgroundDesc,
          granted: _background,
          loading: _loading(_PermissionItem.background),
          blocked: _busy != null,
          feedback: _rowFeedback(_PermissionItem.background),
          onGrant: _location ? _grantBackground : null,
        ),
        // Not a permission and not optional: the OS can refuse to run this
        // app's background work while every grant above still reads "granted".
        // On iOS it is the sharpest failure on the page — with Background App
        // Refresh off, no significant-change or region event is delivered at
        // all, so the location spine reports itself armed and never fires.
        // Hidden until the platform answers, and hidden when a management
        // profile owns the switch, because then there is nothing to tap.
        if (_executionStatus.known && !_executionStatus.lockedByPolicy) ...[
          const SizedBox(height: AppSpacing.sm),
          PermissionRow(
            icon: Icons.play_circle_outline,
            title: l10n.onboardingPermBackgroundExec,
            description: l10n.onboardingPermBackgroundExecDesc,
            granted: !_executionStatus.restricted,
            loading: _loading(_PermissionItem.execution),
            blocked: _busy != null,
            feedback: _rowFeedback(_PermissionItem.execution),
            settingsAction: true,
            onGrant: _openExecutionSettings,
          ),
        ],
        if (Platform.isAndroid) ...[
          const SizedBox(height: AppSpacing.sm),
          PermissionRow(
            icon: Icons.battery_saver_outlined,
            title: l10n.onboardingPermBattery,
            description: l10n.onboardingPermBatteryDesc,
            granted: _batteryOk,
            loading: _loading(_PermissionItem.battery),
            blocked: _busy != null,
            feedback: _rowFeedback(_PermissionItem.battery),
            onGrant: _grantBattery,
          ),
          // Hidden where the platform cannot answer — a device too old for the
          // API, or without the Play services that back-port it, has nothing
          // the user could change, and an un-actionable warning on a disaster
          // app's permission page is worse than no row at all.
          if (_unusedAppStatus != UnusedAppRestrictions.unavailable) ...[
            const SizedBox(height: AppSpacing.sm),
            PermissionRow(
              icon: Icons.hotel_outlined,
              title: l10n.onboardingPermUnusedApp,
              description: l10n.onboardingPermUnusedAppDesc,
              granted: _unusedAppStatus == UnusedAppRestrictions.exempt,
              loading: _loading(_PermissionItem.unusedApp),
              blocked: _busy != null,
              feedback: _rowFeedback(_PermissionItem.unusedApp),
              settingsAction: true,
              onGrant: _exemptUnusedApp,
            ),
          ],
          // The manufacturer's own battery manager, which no API reports and
          // none exempts. Samsung puts an app it considers unused to sleep after
          // about three days — two orders of magnitude sooner than Android's own
          // hibernation — and Xiaomi, Huawei, OPPO and vivo each gate background
          // work behind an "auto-start" switch that is off by default. Advisory
          // because it is genuinely unmeasurable: a tick here would be a claim
          // the app cannot support, and a permanent warning would be worse.
          if (_executionStatus.vendorManaged) ...[
            const SizedBox(height: AppSpacing.sm),
            PermissionRow(
              icon: Icons.factory_outlined,
              title: l10n.onboardingPermVendorPower,
              description: l10n.onboardingPermVendorPowerDesc(_vendorName),
              granted: false,
              advisory: true,
              loading: _loading(_PermissionItem.vendor),
              blocked: _busy != null,
              feedback: _rowFeedback(_PermissionItem.vendor),
              settingsAction: true,
              onGrant: _openVendorSettings,
            ),
          ],
        ],
      ],
    );
  }
}

class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onGrant,
    this.advisory = false,
    this.loading = false,
    this.blocked = false,
    this.settingsAction = false,
    this.feedback,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;

  /// Grant handler; null disables the button (e.g. background before foreground).
  final Future<void> Function()? onGrant;

  /// A state the app cannot measure — it can only point at the screen where the
  /// user changes it. Such a row never shows a tick and never shows the
  /// unsatisfied styling, because both would be claims: a tick we cannot verify,
  /// or a permanent red mark for something that may already be fine. It offers
  /// the settings screen and says so, and [granted] is ignored.
  final bool advisory;
  final bool loading;
  final bool blocked;
  final bool settingsAction;
  final PermissionRowFeedback? feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final feedbackText = switch (feedback) {
      PermissionRowFeedback.stillNeeded => l10n.permissionStillRequired,
      PermissionRowFeedback.verifyManually => l10n.permissionVerifyManually,
      null => null,
    };
    final feedbackColor = switch (feedback) {
      PermissionRowFeedback.stillNeeded => colors.error,
      PermissionRowFeedback.verifyManually => colors.tertiary,
      null => null,
    };
    final borderColor =
        feedbackColor ??
        (loading ? colors.primary : colors.outlineVariant.withValues(alpha: 0));
    final action = onGrant == null || granted
        ? null
        : settingsAction || advisory
        ? OutlinedButton.icon(
            onPressed: loading || blocked ? null : () => onGrant!(),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.permissionOpenSettings),
          )
        : FilledButton.tonal(
            onPressed: loading || blocked ? null : () => onGrant!(),
            child: Text(l10n.onboardingGrant),
          );
    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: AppRadius.medium,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: advisory ? colors.onSurfaceVariant : colors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (feedbackText != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        feedbackText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: feedbackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: loading
                    ? SizedBox.square(
                        key: const ValueKey('loading'),
                        dimension: 24,
                        child: Semantics(
                          label: l10n.commonLoading,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : granted
                    ? Icon(
                        Icons.check_circle,
                        key: const ValueKey('granted'),
                        color: colors.primary,
                      )
                    : feedback == PermissionRowFeedback.stillNeeded
                    ? Icon(
                        Icons.error_outline,
                        key: const ValueKey('stillNeeded'),
                        color: colors.error,
                      )
                    : const SizedBox.shrink(key: ValueKey('idle')),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(alignment: Alignment.centerRight, child: action),
          ],
        ],
      ),
    );
  }
}
