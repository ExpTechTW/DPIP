/// What the AI chat is, where its data goes, and what it is not.
///
/// Shown in full the first time the tab is opened, and again from the chat's
/// info button. Every claim here is one the code keeps: the key in platform
/// key storage only, the conversation in memory only, township names and
/// codes (never coordinates) in the instructions.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/ai_chat/presentation/widgets/mcp_url_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class AiIntro extends StatelessWidget {
  const AiIntro({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: 40,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.aiIntroTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.aiIntroBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xl),
        _Point(
          icon: Icons.key_outlined,
          title: l10n.aiIntroOwnKeyTitle,
          body: l10n.aiIntroOwnKeyBody,
        ),
        _Point(
          icon: Icons.phone_android_outlined,
          title: l10n.aiIntroLocalTitle,
          body: l10n.aiIntroLocalBody,
        ),
        _Point(
          icon: Icons.swap_horiz,
          title: l10n.aiIntroDataTitle,
          body: l10n.aiIntroDataBody,
        ),
        _Point(
          icon: Icons.warning_amber_rounded,
          title: l10n.aiIntroCautionTitle,
          body: l10n.aiIntroCautionBody,
        ),
        _Point(
          icon: Icons.hub_outlined,
          title: l10n.aiIntroMcpTitle,
          body: l10n.aiIntroMcpBody,
        ),
        const McpUrlCard(),
      ],
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
