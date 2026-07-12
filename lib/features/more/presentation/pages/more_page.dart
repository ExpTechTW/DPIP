import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:dpip/features/settings/presentation/pages/experimental_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "More" menu — categorised entry points into settings and tools.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  /// Route path.
  static const String path = '/more';

  /// Route name.
  static const String name = 'more';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        children: [
          _SectionHeader(l10n.moreSectionAdvanced),
          _MoreTile(
            icon: Icons.science_outlined,
            title: l10n.experimentalFeatures,
            onTap: () => context.pushNamed(ExperimentalPage.name),
          ),
          _MoreTile(
            icon: Icons.article_outlined,
            title: l10n.appLogs,
            onTap: () => context.pushNamed(LogPage.name),
          ),
        ],
      ),
    );
  }
}

/// A single navigable row in the More menu — leading icon, title, chevron.
class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// A Material-style settings section header.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
