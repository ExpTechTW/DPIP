/// Says that a permission can only be granted in system settings, then takes
/// the user there — on confirmation, never before.
///
/// Both platforms prompt for a permission once. After that the request is
/// silent, so a screen that just calls it again gives the user a button that
/// visibly does nothing. Sending them straight to Settings instead is not much
/// better: they arrive in a system screen with no idea why, and no idea what to
/// turn on.
///
/// So this states which permission, why the app cannot ask again, and lets the
/// user decide to go. It is shared because every permission row on every
/// surface has the same dead end.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// One concise instruction shown before Android hands control to Settings.
class PermissionSettingsGuide {
  const PermissionSettingsGuide({required this.instruction});

  final String instruction;
}

/// Explains, then opens system settings if the user agrees.
///
/// [what] is the permission's own name, as the row calls it, so the sentence
/// reads as being about the thing the user just tapped.
Future<bool> promptForSystemSettings(
  BuildContext context, {
  required String what,
  required Future<bool> Function() openSettings,
  PermissionSettingsGuide? guide,
}) async {
  Log.info('permission[$what]: showing the settings prompt');
  final l10n = AppLocalizations.of(context);
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_outlined, color: colors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.permissionSettingsTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.permissionSettingsMessage(what)),
                  if (guide != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: AppRadius.medium,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            color: colors.onPrimaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              guide.instruction,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.permissionSettingsHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.permissionOpenSettings),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.commonCancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  Log.info('permission[$what]: settings prompt confirmed = $confirmed');
  if (!(confirmed ?? false)) return false;
  return openSettings();
}
