import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "More" menu — categorised entry points into settings and tools.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        children: [
          SectionHeader(l10n.moreSectionAdvanced),
          _MoreTile(
            icon: Icons.science_outlined,
            title: l10n.experimentalFeatures,
            onTap: () => context.pushNamed(AppRoutes.experimental),
          ),
          _MoreTile(
            icon: Icons.article_outlined,
            title: l10n.appLogs,
            onTap: () => context.pushNamed(AppRoutes.log),
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
