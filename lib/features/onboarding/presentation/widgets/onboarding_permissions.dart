/// The third onboarding step: grant the permissions DPIP needs to alert in real
/// time — notifications, critical alerts (iOS), location, and a battery
/// exemption (Android). Permissions are encouraged but the step can be finished
/// regardless (they're changeable later in system settings).
///
/// The rows themselves are [PermissionChecklist], shared with the standalone
/// 權限檢查 page so the same list can be consulted later, on the day an alert
/// did not arrive. This page adds only the onboarding framing: a heading, and
/// the nudge before finishing without the two that matter.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/permission_checklist.dart';
import 'package:flutter/material.dart';

class OnboardingPermissionsPage extends StatefulWidget {
  const OnboardingPermissionsPage({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingPermissionsPage> createState() =>
      _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage> {
  /// The last state the checklist reported — what [_finish] reads.
  PermissionState? _state;

  /// Finishes onboarding — but if a permission that makes localized alerts work
  /// (notifications or location) is still missing, confirm first. We *can't*
  /// require them (App Store 5.1.2(i) / 4.5.4 forbid gating the app on a
  /// permission), so this is a strong nudge, never a block; a persistent in-app
  /// banner keeps reminding afterwards.
  Future<void> _finish() async {
    if (_state?.essentialsGranted ?? false) {
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
          PermissionChecklist(
            onChanged: (state) => setState(() => _state = state),
          ),
        ],
      ),
    );
  }
}
