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

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Explains, then opens system settings if the user agrees.
///
/// [what] is the permission's own name, as the row calls it, so the sentence
/// reads as being about the thing the user just tapped.
Future<void> promptForSystemSettings(
  BuildContext context, {
  required String what,
  required Future<void> Function() openSettings,
}) async {
  Log.info('permission[$what]: showing the settings prompt');
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.settings_outlined),
      title: Text(l10n.permissionSettingsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.permissionSettingsMessage(what)),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.permissionSettingsHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.permissionOpenSettings),
        ),
      ],
    ),
  );
  Log.info('permission[$what]: settings prompt confirmed = $confirmed');
  if (confirmed ?? false) await openSettings();
}
