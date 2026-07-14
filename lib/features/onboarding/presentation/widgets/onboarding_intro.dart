/// The first onboarding step: what DPIP is. Scroll to the end to continue.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class OnboardingIntroPage extends StatelessWidget {
  const OnboardingIntroPage({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return OnboardingScaffold(
      actionBuilder: (context, atEnd) => OnboardingCta(
        label: l10n.onboardingNext,
        onPressed: atEnd ? onNext : null,
        hint: l10n.onboardingScrollHint,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            l10n.onboardingIntroTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.onboardingIntroBody,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
