import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// "More" menu — external ExpTech resources plus advanced tools, grouped into
/// tonal cards.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        children: [
          SectionHeader(l10n.moreSectionAdvanced),
          _MoreGroup(
            children: [
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
          SectionHeader(l10n.moreSectionLinks),
          _MoreGroup(
            children: [
              _MoreLinkTile(
                icon: Icons.crisis_alert_outlined,
                title: l10n.moreCwaEew,
                host: 'eew.exptech.dev',
                url: 'https://eew.exptech.dev/',
              ),
              _MoreLinkTile(
                icon: Icons.sensors_outlined,
                title: l10n.moreTremReport,
                host: 'report.exptech.dev',
                url: 'https://report.exptech.dev/',
              ),
              _MoreLinkTile(
                icon: Icons.dns_outlined,
                title: l10n.moreServerStatus,
                host: 'status.exptech.dev',
                url: 'https://status.exptech.dev/status',
              ),
              _MoreLinkTile(
                icon: Icons.campaign_outlined,
                title: l10n.moreAnnouncements,
                host: 'announcement.exptech.com.tw',
                url: 'https://announcement.exptech.com.tw/',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded tonal card grouping a section's rows, with hairline dividers
/// inset to the row text — the app's grouped-list surface.
class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.xxl + AppSpacing.xl,
            color: theme.colorScheme.outlineVariant,
          ),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// A navigable row into an in-app screen — leading icon, title, chevron.
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

/// A row that opens an external website in the browser — leading icon, title,
/// the host as a subtitle (so the destination is visible), and an
/// open-in-new affordance.
class _MoreLinkTile extends StatelessWidget {
  const _MoreLinkTile({
    required this.icon,
    required this.title,
    required this.host,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String host;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(host),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    // Capture context-bound objects before the async gap.
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).moreLinkOpenFailed;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('launchUrl returned false for $url');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'open external link $url');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}
