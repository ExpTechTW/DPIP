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

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/platform/battery_optimization.dart';
import 'package:dpip/core/platform/unused_app_restrictions.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
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
    if (!mounted) return;
    Log.info(
      'permission state: notify=$notify critical=$critical '
      'location=$locationGranted background=$backgroundGranted '
      'battery=$batteryOk unusedApp=${unusedApp.name}',
    );
    setState(() {
      _notify = notify;
      _critical = critical;
      _location = locationGranted;
      _background = backgroundGranted;
      _batteryOk = batteryOk;
      _unusedAppStatus = unusedApp;
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

  /// Asks for a permission, and when the system will not ask again, says so
  /// and offers to open its settings.
  Future<void> _grant(
    Future<PermissionOutcome> Function() request,
    Future<void> Function() openSettings,
    String what,
  ) async {
    // Logged end to end. A permission row that appears to do nothing has
    // several indistinguishable causes — the tap never arrived, the request
    // returned "granted" or "denied" so no dialog was due, the plugin never
    // answered, or something threw and the unawaited future swallowed it — and
    // none of them leave a trace by default.
    Log.info('permission[$what]: tapped');
    try {
      final outcome = await request();
      Log.info('permission[$what]: outcome = ${outcome.name}');
      if (!mounted) {
        Log.warning('permission[$what]: page gone before the outcome landed');
        return;
      }
      if (outcome == PermissionOutcome.needsSettings) {
        await promptForSystemSettings(
          context,
          what: what,
          openSettings: openSettings,
        );
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
    return _grant(
      notifications.requestPermission,
      notifications.openSystemSettings,
      AppLocalizations.of(context).onboardingPermNotify,
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
    return _grant(
      notifications.requestCritical,
      notifications.openSystemSettings,
      AppLocalizations.of(context).onboardingPermCritical,
    );
  }

  // Foreground location only. Background ("Always") is a SEPARATE step —
  // Android 11+ silently denies both if they're requested in the same gesture.
  Future<void> _grantLocation() {
    final location = context.read<LocationService>();
    return _grant(
      location.requestPermission,
      location.openSettings,
      AppLocalizations.of(context).onboardingPermLocation,
    );
  }

  // Background ("Always"): only meaningful after foreground is granted; on
  // Android 11+ and on iOS after "While Using" it lives only in Settings, so
  // this almost always ends in the dialog rather than a prompt.
  Future<void> _grantBackground() {
    final location = context.read<LocationService>();
    return _grant(
      location.requestBackground,
      location.openSettings,
      AppLocalizations.of(context).onboardingPermBackground,
    );
  }

  Future<void> _grantBattery() async {
    await _battery.request(); // re-checked on resume
  }

  Future<void> _exemptUnusedApp() async {
    // Not a permission — there is no prompt to await, only a settings page.
    await _unusedApp.openSettings(); // re-checked on resume
  }

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
          onGrant: _grantNotify,
        ),
        if (Platform.isIOS) ...[
          const SizedBox(height: AppSpacing.sm),
          PermissionRow(
            icon: Icons.notification_important_outlined,
            title: l10n.onboardingPermCritical,
            description: l10n.onboardingPermCriticalDesc,
            granted: _critical,
            onGrant: _grantCritical,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        PermissionRow(
          icon: Icons.location_on_outlined,
          title: l10n.onboardingPermLocation,
          description: l10n.onboardingPermLocationDesc,
          granted: _location,
          onGrant: _grantLocation,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Background ("Always") — a separate step, unlocked once foreground is on.
        PermissionRow(
          icon: Icons.my_location_outlined,
          title: l10n.onboardingPermBackground,
          description: l10n.onboardingPermBackgroundDesc,
          granted: _background,
          onGrant: _location ? _grantBackground : null,
        ),
        if (Platform.isAndroid) ...[
          const SizedBox(height: AppSpacing.sm),
          PermissionRow(
            icon: Icons.battery_saver_outlined,
            title: l10n.onboardingPermBattery,
            description: l10n.onboardingPermBatteryDesc,
            granted: _batteryOk,
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
              onGrant: _exemptUnusedApp,
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
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;

  /// Grant handler; null disables the button (e.g. background before foreground).
  final Future<void> Function()? onGrant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (granted)
            Icon(Icons.check_circle, color: theme.colorScheme.primary)
          else
            FilledButton.tonal(
              onPressed: onGrant == null ? null : () => onGrant!(),
              child: Text(l10n.onboardingGrant),
            ),
        ],
      ),
    );
  }
}
