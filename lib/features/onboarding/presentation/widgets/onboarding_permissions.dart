/// The third onboarding step: grant the permissions DPIP needs to alert in real
/// time — notifications, critical alerts (iOS), location, and a battery
/// exemption (Android). Permissions are encouraged but the step can be finished
/// regardless (they're changeable later in system settings).
library;

import 'dart:io';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/platform/battery_optimization.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingPermissionsPage extends StatefulWidget {
  const OnboardingPermissionsPage({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingPermissionsPage> createState() =>
      _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage>
    with WidgetsBindingObserver {
  final BatteryOptimization _battery = BatteryOptimization();

  bool _notify = false;
  bool _critical = false;
  bool _location = false;
  bool _background = false;
  bool _batteryOk = false;

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
    // The battery / settings prompts are resolved outside the app; re-check on
    // return.
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
    if (!mounted) return;
    Log.info(
      'permission state: notify=$notify critical=$critical '
      'location=$locationGranted background=$backgroundGranted '
      'battery=$batteryOk',
    );
    setState(() {
      _notify = notify;
      _critical = critical;
      _location = locationGranted;
      _background = backgroundGranted;
      _batteryOk = batteryOk;
    });
  }

  /// Asks for a permission, and when the system will not ask again, says so
  /// and offers to open its settings.
  ///
  /// This is the shape every row needs. Both platforms prompt once; after that
  /// the request returns silently, so a row that only calls it again is a
  /// button that does nothing — which is how this screen used to dead-end.
  Future<void> _grant(
    Future<PermissionOutcome> Function() request,
    Future<void> Function() openSettings,
    String what,
  ) async {
    // Logged end to end. A permission row that appears to do nothing has three
    // indistinguishable causes — the tap never arrived, the request returned
    // "granted" or "denied" so no dialog was due, or something threw and the
    // unawaited future swallowed it — and none of them leave a trace by
    // default. Each step says so now.
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

  /// Finishes onboarding — but if a permission that makes localized alerts work
  /// (notifications or location) is still missing, confirm first. We *can't*
  /// require them (App Store 5.1.2(i) / 4.5.4 forbid gating the app on a
  /// permission), so this is a strong nudge, never a block; a persistent in-app
  /// banner keeps reminding afterwards.
  Future<void> _finish() async {
    if (_notify && _location) {
      widget.onFinish();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.onboardingSkipTitle),
        content: Text(l10n.onboardingSkipBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.onboardingSkipStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.onboardingSkipLeave),
          ),
        ],
      ),
    );
    if (leave ?? false) widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final rows = <Widget>[
      _PermissionRow(
        icon: Icons.notifications_active_outlined,
        title: l10n.onboardingPermNotify,
        description: l10n.onboardingPermNotifyDesc,
        granted: _notify,
        onGrant: _grantNotify,
      ),
      if (Platform.isIOS)
        _PermissionRow(
          icon: Icons.notification_important_outlined,
          title: l10n.onboardingPermCritical,
          description: l10n.onboardingPermCriticalDesc,
          granted: _critical,
          onGrant: _grantCritical,
        ),
      _PermissionRow(
        icon: Icons.location_on_outlined,
        title: l10n.onboardingPermLocation,
        description: l10n.onboardingPermLocationDesc,
        granted: _location,
        onGrant: _grantLocation,
      ),
      // Background ("Always") — a separate step, unlocked once foreground is on.
      _PermissionRow(
        icon: Icons.my_location_outlined,
        title: l10n.onboardingPermBackground,
        description: l10n.onboardingPermBackgroundDesc,
        granted: _background,
        onGrant: _location ? _grantBackground : null,
      ),
      if (Platform.isAndroid)
        _PermissionRow(
          icon: Icons.battery_saver_outlined,
          title: l10n.onboardingPermBattery,
          description: l10n.onboardingPermBatteryDesc,
          granted: _batteryOk,
          onGrant: _grantBattery,
        ),
    ];

    return OnboardingScaffold(
      requireScrollToEnd: false,
      actionBuilder: (context, _) =>
          OnboardingCta(label: l10n.onboardingStart, onPressed: _finish),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingPermsTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.onboardingPermsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final row in rows) ...[
            row,
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// One permission: icon, title, description, and a grant control (a filled
/// tonal button, or a check once granted).
class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
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
