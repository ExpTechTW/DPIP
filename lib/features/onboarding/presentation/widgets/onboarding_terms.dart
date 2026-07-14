/// The second onboarding step: the Terms of Service. Scroll to the end, tick the
/// checkbox, then agree.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class OnboardingTermsPage extends StatefulWidget {
  const OnboardingTermsPage({super.key, required this.onAccept});

  final VoidCallback onAccept;

  @override
  State<OnboardingTermsPage> createState() => _OnboardingTermsPageState();
}

class _OnboardingTermsPageState extends State<OnboardingTermsPage> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OnboardingScaffold(
      actionBuilder: (context, atEnd) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: _agreed,
              // Only checkable once the terms have been scrolled through.
              onChanged: atEnd
                  ? (value) => setState(() => _agreed = value ?? false)
                  : null,
              title: Text(l10n.onboardingTermsAgree),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            OnboardingCta(
              label: l10n.onboardingAgreeContinue,
              onPressed: atEnd && _agreed ? widget.onAccept : null,
              hint: atEnd ? null : l10n.onboardingScrollHint,
            ),
          ],
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingTermsTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.onboardingTermsBody,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
