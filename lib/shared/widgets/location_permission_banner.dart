/// An app-wide banner shown when location can't be used (services off or
/// permission denied), with a one-tap route to system settings.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/location_monitor.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Watches [LocationMonitor]; renders a warning bar when location needs the
/// user's attention, and nothing (zero height) otherwise — so a healthy app is
/// unaffected. Place it at the top of the shell body.
class LocationPermissionBanner extends StatelessWidget {
  const LocationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<LocationMonitor>();
    if (!monitor.needsAttention) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final message = monitor.status == LocationStatus.serviceOff
        ? l10n.locationBannerServiceOff
        : l10n.locationBannerPermission;

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
              Icon(Icons.location_off_outlined, color: colors.onErrorContainer),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
              TextButton(
                onPressed: monitor.openSettings,
                child: Text(l10n.locationBannerFix),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
