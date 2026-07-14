/// An app-wide banner shown when notifications are disabled (so disaster alerts
/// can't reach the user), with a one-tap route to system settings.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/app_settings.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Watches notification permission and renders a warning bar while it's off,
/// re-checking whenever the app returns to the foreground (the user may grant it
/// in Settings). Zero height when notifications are allowed — a healthy app is
/// unaffected. Place it at the top of the shell body, beside the location
/// banner. Notifications can't be *required* (App Store 4.5.4 / 5.1.2(i)), so
/// this is the compliant nudge: visible, dismissable by granting, never a block.
class NotificationPermissionBanner extends StatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  State<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends State<NotificationPermissionBanner>
    with WidgetsBindingObserver {
  // Optimistic: assume allowed so the banner shows only once confirmed off.
  bool _allowed = true;

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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final allowed = await context.read<NotificationService>().isAllowed();
    if (!mounted || allowed == _allowed) return;
    setState(() => _allowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_off_outlined,
                color: colors.onErrorContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.notifyBannerDisabled,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: openAppSettings,
                child: Text(l10n.locationBannerFix),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
