/// 權限檢查 — the standalone permission checklist, reachable any time from the
/// More tab.
///
/// The same rows onboarding shows, kept available afterwards because that is
/// when they are actually needed: an alert that never arrived is almost always
/// a permission that was declined months ago, and the system settings app does
/// not explain which of DPIP's four grants is the missing one. Each row states
/// its own status and offers the only action that can still change it.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_checklist.dart';
import 'package:flutter/material.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.permissionsTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            l10n.permissionsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const PermissionChecklist(),
        ],
      ),
    );
  }
}
