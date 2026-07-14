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
import 'package:dpip/core/platform/battery_optimization.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
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
    final notifications = context.read<NotificationService>();
    final location = context.read<LocationService>();
    final notify = await notifications.isAllowed();
    final critical = Platform.isIOS
        ? await notifications.criticalAllowed()
        : false;
    final locationGranted = await location.granted();
    final batteryOk = Platform.isAndroid ? await _battery.isIgnoring() : true;
    if (!mounted) return;
    setState(() {
      _notify = notify;
      _critical = critical;
      _location = locationGranted;
      _batteryOk = batteryOk;
    });
  }

  Future<void> _grantNotify() async {
    await context.read<NotificationService>().requestPermission();
    if (mounted) await _refresh();
  }

  Future<void> _grantLocation() async {
    final location = context.read<LocationService>();
    await location.requestPermission();
    await location.requestBackground(); // escalate to Always for background
    if (mounted) await _refresh();
  }

  Future<void> _grantBattery() async {
    await _battery.request(); // re-checked on resume
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
          onGrant: _grantNotify,
        ),
      _PermissionRow(
        icon: Icons.location_on_outlined,
        title: l10n.onboardingPermLocation,
        description: l10n.onboardingPermLocationDesc,
        granted: _location,
        onGrant: _grantLocation,
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
      actionBuilder: (context, _) => OnboardingCta(
        label: l10n.onboardingStart,
        onPressed: widget.onFinish,
      ),
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
  final Future<void> Function() onGrant;

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
              onPressed: () => onGrant(),
              child: Text(l10n.onboardingGrant),
            ),
        ],
      ),
    );
  }
}
