import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
        // The shell uses extendBody, so the list runs behind the bottom nav bar;
        // pad the bottom by the obscured height (reported via MediaQuery) so the
        // last rows can scroll clear of it.
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // Support CTA, kept prominent at the top in its own headerless group.
          _MoreGroup(
            children: [
              _MoreTile(
                icon: Icons.favorite_border,
                title: l10n.sponsorTitle,
                onTap: () => context.pushNamed(AppRoutes.sponsor),
              ),
            ],
          ),
          SectionHeader(l10n.moreSectionRegion),
          _MoreGroup(
            children: [
              const _SavedRegionsTile(),
            ],
          ),
          SectionHeader(l10n.moreSectionNotify),
          _MoreGroup(
            children: [
              _MoreTile(
                icon: Icons.notifications_outlined,
                title: l10n.notifySettingsMenu,
                onTap: () => context.pushNamed(AppRoutes.notifySettings),
              ),
            ],
          ),
          SectionHeader(l10n.moreSectionDisplay),
          _MoreGroup(
            children: [
              _MoreTile(
                icon: Icons.translate_outlined,
                title: l10n.languageSettings,
                onTap: () => context.pushNamed(AppRoutes.language),
              ),
              _MoreTile(
                icon: Icons.brightness_6_outlined,
                title: l10n.displaySettings,
                onTap: () => context.pushNamed(AppRoutes.display),
              ),
            ],
          ),
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
              _MoreTile(
                icon: Icons.developer_mode_outlined,
                title: l10n.moreDeveloper,
                onTap: () => context.pushNamed(AppRoutes.developer),
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
              _MoreLinkTile(
                icon: Icons.discord,
                title: l10n.moreDiscord,
                host: 'exptech.com.tw/dc',
                url: 'https://exptech.com.tw/dc',
              ),
              _MoreLinkTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.moreNotifyLog,
                host: 'status.exptech.com.tw',
                url: 'https://status.exptech.com.tw/notify',
              ),
              _MoreLinkTile(
                icon: Icons.smart_display_outlined,
                title: l10n.moreYoutube,
                host: 'youtube.com/@exptechtw',
                url: 'https://www.youtube.com/@exptechtw',
              ),
              _MoreLinkTile(
                icon: Icons.groups_outlined,
                title: l10n.moreGithub,
                host: 'github.com/ExpTechTW',
                url: 'https://github.com/ExpTechTW',
              ),
              _MoreLinkTile(
                icon: Icons.code_outlined,
                title: l10n.moreSourceCode,
                host: 'github.com/ExpTechTW/DPIP',
                url: 'https://github.com/ExpTechTW/DPIP',
              ),
            ],
          ),
          // Both stores shown side by side — DPIP is cross-platform.
          SectionHeader(l10n.moreSectionApp),
          _MoreGroup(
            children: [
              _MoreLinkTile(
                icon: Icons.android,
                title: l10n.moreGooglePlay,
                host: 'play.google.com',
                url:
                    'https://play.google.com/store/apps/details?id=com.exptech.dpip',
              ),
              _MoreLinkTile(
                icon: Icons.apple,
                title: l10n.moreAppStore,
                host: 'apps.apple.com',
                url: 'https://apps.apple.com/tw/app/dpip/id6468026362',
              ),
            ],
          ),
          SectionHeader(l10n.moreSectionAbout),
          _MoreGroup(
            children: [
              _MoreLinkTile(
                icon: Icons.gavel_outlined,
                title: l10n.termsOfService,
                host: 'exptech.com.tw',
                url: 'https://exptech.com.tw/tos',
              ),
              _MoreTile(
                icon: Icons.inventory_2_outlined,
                title: l10n.openSourceLicenses,
                // Flutter's built-in license viewer — no third-party package.
                onTap: () =>
                    showLicensePage(context: context, applicationName: 'DPIP'),
              ),
              _MoreLinkTile(
                icon: Icons.help_outline,
                title: l10n.faq,
                host: 'exptech.com.tw',
                url: 'https://exptech.com.tw',
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
      rows.add(Material(type: MaterialType.transparency, child: children[i]));
    }
    // Material (not DecoratedBox) so ListTile ink paints on this ancestor —
    // a colored DecoratedBox between tile and Material asserts in debug.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.medium,
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      ),
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

class _SavedRegionsTile extends StatefulWidget {
  const _SavedRegionsTile();

  @override
  State<_SavedRegionsTile> createState() => _SavedRegionsTileState();
}

class _SavedRegionsTileState extends State<_SavedRegionsTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final store = context.watch<RegionStore>();
    final saved = store.savedCodes;
    final canAdd = saved.length < RegionStore.maxSaved;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.pin_drop_outlined),
          title: Text(l10n.regionManageTitle),
          trailing: Icon(
            _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                if (saved.isEmpty)
                  _SavedRegionEmpty(message: l10n.regionEmpty)
                else
                  for (final code in saved)
                    _SavedRegionRow(
                      code: code,
                      onTap: () => _showRegionActions(context, code),
                    ),
                if (canAdd) ...[
                  if (saved.isNotEmpty) const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.pushNamed(
                        AppRoutes.regionSelect,
                        queryParameters: const {'returnToMore': '1'},
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.regionAddButton),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.regionSelectCount(
                          saved.length,
                          RegionStore.maxSaved,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }

  Future<void> _showRegionActions(BuildContext context, String code) async {
    final directory = context.read<TownDirectory>();
    final town = directory.byCode(code);
    final title = town == null ? code : '${town.cityName} ${town.townName}';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(title)),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(context).regionEdit),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.pushNamed(
                  AppRoutes.regionSelect,
                  queryParameters: {'replace': code, 'returnToMore': '1'},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(
                MaterialLocalizations.of(context).deleteButtonTooltip,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.read<RegionStore>().removeSaved(code);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(MaterialLocalizations.of(context).cancelButtonLabel),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

class _SavedRegionRow extends StatelessWidget {
  const _SavedRegionRow({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final directory = context.read<TownDirectory>();
    final town = directory.byCode(code);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
      leading: const Icon(Icons.location_on_outlined),
      title: Text(town?.townName ?? code),
      subtitle: Text(town?.cityName ?? ''),
      trailing: const Icon(Icons.more_horiz),
      onTap: onTap,
    );
  }
}

class _SavedRegionEmpty extends StatelessWidget {
  const _SavedRegionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
