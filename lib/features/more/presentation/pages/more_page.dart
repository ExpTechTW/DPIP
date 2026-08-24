import 'dart:typed_data';

import 'package:dpip/app/theme/app_gold.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_counter.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/more/domain/developer_note.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/shared/diagnostics/dump_action.dart';
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
    final mapLayer = context.watch<DefaultMapLayerController>().layer;
    final eewCwaOnly = context.watch<EewCwaOnlySettings>().enabled;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          // The shell uses extendBody, so the list runs behind the bottom nav bar;
          // pad the bottom by the obscured height (reported via MediaQuery) so the
          // last rows can scroll clear of it.
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            // The four cards above the menu, one block: version fills the left
            // half of the line, support takes the top half of the right column,
            // and Discord and announcements split the bottom half of it.
            const _HeroCards(),
            // Straight under the support callout: the developers' current
            // word, tracked in Dart rather than ARB because it moves faster
            // than a release cycle.
            const _DeveloperNoteCard(),
            SectionHeader(l10n.moreSectionRegion),
            _MoreGroup(
              children: [
                const _SavedRegionsTile(),
                _SaveNote(l10n: l10n),
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
                // Kept beside the notification settings: when an alert does not
                // arrive, the grant is the first thing to check.
                _MoreTile(
                  icon: Icons.verified_user_outlined,
                  title: l10n.permissionsTitle,
                  // The same dot the More tab carries, on the row it leads to —
                  // otherwise the tab says something is wrong and the page the
                  // user opens looks no different from every other row.
                  alert: context.select<PermissionHealth, bool>(
                    (health) => health.needsAttention,
                  ),
                  onTap: () => context.pushNamed(AppRoutes.permissions),
                ),
                // What the system says actually went out — a status page, kept
                // in the notification group because that is where you look when
                // an alert did not arrive.
                _MoreLinkTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.moreNotifyLog,
                  host: 'status.exptech.com.tw',
                  url: 'https://status.exptech.com.tw/notify',
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
                _MoreTile(
                  icon: mapLayer.icon,
                  title: l10n.defaultMapLayerSettings,
                  subtitle: mapLayer.label(l10n),
                  onTap: () => context.pushNamed(AppRoutes.defaultMapLayer),
                ),
                _MoreTile(
                  icon: Icons.filter_alt_outlined,
                  title: l10n.eewSourceSettings,
                  subtitle: eewCwaOnly
                      ? l10n.eewSourceCwaOnly
                      : l10n.eewSourceAll,
                  onTap: () => context.pushNamed(AppRoutes.eewSource),
                ),
              ],
            ),
            // Its own section rather than a row under 進階: the LoRa mesh is the
            // app's off-grid reception path, not a developer curiosity, and the
            // radio it pairs with is a physical thing the user owns and manages.
            SectionHeader(l10n.moreSectionMesh),
            _MoreGroup(
              children: [
                _MoreTile(
                  icon: Icons.router_outlined,
                  title: l10n.meshtasticTitle,
                  // A message arrived in a conversation the user has not read —
                  // the same state as the chat page's unread pills, selected
                  // down to one boolean so only this tile rebuilds.
                  alert: context.select<MeshUnread, bool>((u) => u.hasUnread),
                  onTap: () => context.pushNamed(AppRoutes.meshtastic),
                ),
              ],
            ),
            SectionHeader(l10n.moreSectionAdvanced),
            _MoreGroup(
              children: [
                // Hidden until ten taps on the Developer page's version row
                // (ExperimentalSettings.unlocked).
                if (context.watch<ExperimentalSettings>().unlocked)
                  _MoreTile(
                    icon: Icons.science_outlined,
                    title: l10n.experimentalFeatures,
                    onTap: () => context.pushNamed(AppRoutes.experimental),
                  ),
                _MoreTile(
                  icon: Icons.history_outlined,
                  title: l10n.changelogTitle,
                  onTap: () => context.pushNamed(AppRoutes.changelog),
                ),
                _MoreTile(
                  icon: Icons.bug_report_outlined,
                  title: l10n.moreBugReports,
                  // The count rides the same ETag-cached index the page reads;
                  // loaded once per session here, resynced by the list's own
                  // pull-to-refresh.
                  trailing: _BugReportCount(
                    counter: context.watch<BugTrackerCounter>(),
                    onLoad: () =>
                        context.read<BugTrackerCounter>().ensureLoaded(),
                  ),
                  onTap: () => context.pushNamed(AppRoutes.bugTracker),
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
                // Directly under the page it dumps. Everything a report needs
                // is on that page already, and it was still being retyped row by
                // row — this sends the whole thing, plus the log that explains
                // it, and hands back one link.
                const _DumpTile(),
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
                  url: 'https://play.google.com/store/apps/details?id=com.exptech.dpip',
                ),
                _MoreLinkTile(
                  icon: Icons.apple,
                  title: l10n.moreAppStore,
                  host: 'apps.apple.com',
                  url: 'https://apps.apple.com/tw/app/dpip/id6468026362',
                ),
              ],
            ),
            // The bleeding-edge builds, one per store, each with its own opt-in.
            SectionHeader(l10n.moreSectionBeta),
            _MoreGroup(
              children: [
                _MoreLinkTile(
                  icon: Icons.android,
                  title: l10n.moreAndroidBeta,
                  host: 'play.google.com',
                  url: 'https://play.google.com/apps/testing/com.exptech.dpip',
                ),
                _MoreLinkTile(
                  icon: Icons.apple,
                  title: l10n.moreTestFlight,
                  host: 'testflight.apple.com',
                  url: 'https://testflight.apple.com/join/8aPWtOxk',
                ),
              ],
            ),
            // The people who make DPIP run — the same list as the README.
            SectionHeader(l10n.moreSectionPartners),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.morePartnersNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _MoreGroup(
              children: [
                _MoreLinkTile(
                  icon: Icons.business_outlined,
                  title: l10n.morePartnerGeoscience,
                  host: 'geoscience.com.tw',
                  url: 'https://www.geoscience.com.tw/',
                ),
                _MoreLinkTile(
                  icon: Icons.cloud_outlined,
                  title: l10n.morePartnerTwds,
                  host: 'twds.com.tw',
                  url: 'https://www.twds.com.tw/',
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
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'DPIP',
                  ),
                ),
                _MoreLinkTile(
                  icon: Icons.help_outline,
                  title: l10n.faq,
                  host: 'exptech.com.tw',
                  url: 'https://exptech.com.tw',
                ),
              ],
            ),
            const _DataSourceAttributions(),
          ],
        ),
      ),
    );
  }
}

class _DataSourceAttributions extends StatelessWidget {
  const _DataSourceAttributions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.62);
    final sources = [
      l10n.dataSourceTremNet,
      l10n.dataSourceCwa,
      l10n.dataSourceJma,
      l10n.dataSourceNcdr,
      l10n.dataSourceEcmwf,
      l10n.dataSourceNoaaGfs,
      l10n.dataSourceGovernmentOpenData,
      l10n.dataSourceOpenStreetMap,
      l10n.dataSourceNasaMoon,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moreDataSources,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final source in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      source,
                      style: theme.textTheme.labelSmall?.copyWith(color: color),
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
    this.subtitle,
    this.alert = false,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Marks the row with the same dot the shell uses, for something the user
  /// should act on. Off for every row that is merely a destination.
  final bool alert;

  /// Replaces the chevron. A row that *does* something rather than going
  /// somewhere passes its own — a chevron on it promises a page that never
  /// opens.
  final Widget? trailing;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: alert ? Badge(child: Icon(icon)) : Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? const Icon(Icons.chevron_right),
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
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.onSurfaceVariant),
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

// The relationship note: alerts follow GPS, saved regions only change the
// home screen. Rendered as a bold slogan row inside the Region group, right
// under the saved-regions row — reads at a glance, no second card.
class _SaveNote extends StatelessWidget {
  const _SaveNote({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.regionSaveNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
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

  Future<void> _open(BuildContext context) => openExternalLink(context, url);
}

/// Opens [url] in the browser, reporting a failure to the user rather than
/// leaving a row that silently does nothing.
Future<void> openExternalLink(BuildContext context, String url) async {
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

/// The four cards above the menu in one block — version fills the left half
/// full-height, support the top half of the right column, and Discord and
/// announcements split the bottom half of it.
///
/// The heights are fixed so the two columns meet exactly: the block's height
/// is set on the row, each right-column card gets its share of the remaining
/// space after the solder gaps, and the version card centers its content in
/// what is left. Anything textural here would only invite overflow, so the
/// cards are kept to icon-plus-word constructions.
class _HeroCards extends StatelessWidget {
  const _HeroCards();

  /// Height of the left version card — it leads the block, so it gets to
  /// declare its own height (its column uses a Spacer, which needs a bounded
  /// height) while the small cards beside it are shorter by design. It spans
  /// the right column's four small cards plus the three gaps between them, so
  /// its bottom edge lands exactly on the support card's.
  static const double _versionHeight = 4 * _smallCardHeight + 3 * AppSpacing.xs;

  /// Height of a small card (Discord, announcement, status, support).
  static const double _smallCardHeight = 56;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              height: _versionHeight,
              child: const _VersionCard(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              children: const [
                SizedBox(height: _smallCardHeight, child: _DiscordCallout()),
                SizedBox(height: AppSpacing.xs),
                SizedBox(height: _smallCardHeight, child: _AnnouncementCard()),
                SizedBox(height: AppSpacing.xs),
                SizedBox(height: _smallCardHeight, child: _StatusCard()),
                SizedBox(height: AppSpacing.xs),
                SizedBox(height: _smallCardHeight, child: _SupportCallout()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The developers' current word, right under the support callout.
///
/// A quiet flat card, one step below the hero column: it asks nothing and it
/// is not an entry point, so it carries the same neutral surface as the
/// announcement card but none of its link affordance. The copy lives in
/// [developerNoteFor] — Dart, not ARB, because a note about a live incident
/// is outdated by the time an ARB change reaches a store build.
class _DeveloperNoteCard extends StatelessWidget {
  const _DeveloperNoteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = developerNoteFor(Localizations.localeOf(context).toString());
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.large,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceContainerHighest,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: colors.onSurfaceVariant,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                note.body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's primary call to action.
///
/// DPIP carries no ads, so this is the only thing on the page actually asking
/// the user for something. It is painted in [AppGold] — the one colour in the
/// app from outside the [ColorScheme], because a card tinted from the same seed
/// as everything else reads as another menu row, whatever weight it is given.
/// Gold is what makes it read as *paid*.
///
/// It shares the row construction of the two cards under it — badge, label,
/// trailing arrow — so the right column reads as one aligned stack; the
/// ranking is carried by the gold alone, rendered flat: a warm champagne
/// fill, a hairline along the edge, and a filled badge holding the most
/// saturated step.
class _SupportCallout extends StatefulWidget {
  const _SupportCallout();

  @override
  State<_SupportCallout> createState() => _SupportCalloutState();
}

class _SupportCalloutState extends State<_SupportCallout>
    with SingleTickerProviderStateMixin {
  /// The border's breathing pulse — a slow sine that keeps the gold border
  /// gently swelling, so the card draws the eye without any of the strobing
  /// an opacity blink would. Repeats forever, but costs nothing when the card
  /// is off screen (the ticker pauses) and the test suite treats it as a
  /// plain animation.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
    lowerBound: 0.55,
    upperBound: 1.0,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gold = AppGold.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gold.fill,
        borderRadius: AppRadius.large,
        border: Border.all(color: gold.edge.withValues(alpha: _breath.value)),
        // No gradient: the card sits on the same tonal plane as its two
        // neighbours, and the ranking is carried by the gold colour alone —
        // the badge is what reads as paid, not the sheen.
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.large,
          onTap: () => context.pushNamed(AppRoutes.sponsor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Filled, not outlined: the one active affordance on a page
                // whose every other row is an outlined icon.
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.badge,
                  ),
                  child: Icon(Icons.favorite, color: gold.onBadge, size: 19),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.sponsorTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: gold.ink,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: gold.ink.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's second call to action, directly under [_SupportCallout].
///
/// Deliberately one step down: the same badge-and-label row as the callout
/// above, but a flat secondary container with no gradient and no shadow. That
/// is what makes the ranking legible — if this card also glowed, neither would
/// lead.
class _DiscordCallout extends StatelessWidget {
  const _DiscordCallout();

  static const String _url = 'https://exptech.com.tw/dc';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openExternalLink(context, _url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.secondary,
                ),
                child: Icon(Icons.discord, color: colors.onSecondary, size: 19),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.moreDiscord,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.open_in_new,
                size: 14,
                color: colors.onSecondaryContainer.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The news entry, directly under the two calls to action.
///
/// Not a call to action — it asks nothing of the user — so it carries none of
/// their weight: a flat neutral card, no gradient, no glow. It stays at the
/// top anyway, because announcements are how ExpTech reaches everyone at
/// once, and the row it replaced sat four deep in the links list.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard();

  static const String _url = 'https://announcement.exptech.com.tw/';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openExternalLink(context, _url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  color: colors.onSurfaceVariant,
                  size: 19,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.moreAnnouncements,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.open_in_new,
                size: 14,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bug-tracker tile's trailing count — the number of open threads the
/// tracker index reports, in GitHub's speech-bubble-plus-number shape. Null
/// while loading or after a failure: an unreachable tracker must not read as
/// "no bugs", and a missing count draws the plain chevron instead.
class _BugReportCount extends StatelessWidget {
  const _BugReportCount({required this.counter, required this.onLoad});

  final BugTrackerCounter counter;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    // Kick the one-shot load from outside build — notifyListeners during the
    // same frame's build would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) onLoad();
    });
    final count = counter.count;
    if (count == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mode_comment_outlined, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
        const SizedBox(width: AppSpacing.xs),
        Icon(Icons.chevron_right, size: 20, color: color),
      ],
    );
  }
}

/// Server status, directly under the announcement card — the same flat,
/// quiet construction, because a status check is a passive read and needs no
/// more weight than a link.
class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // The same dot the More tab carries: a service host the client has
    // stopped reaching is as actionable as a missing permission.
    final alert = context.select<EndpointHealthMonitor, bool>(
      (health) => health.needsAttention,
    );
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(AppRoutes.serverStatus),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Badge(
                isLabelVisible: alert,
                smallSize: 7,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.dns_outlined,
                    color: colors.onSurfaceVariant,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.moreServerStatus,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// This install's identity — the logo, the label, and which train it belongs
/// to — sized to lead the block.
///
/// A DPIP label is either a plain `X.Y` (a release, `26.1`) or a weekly
/// snapshot name (`26w33b`), and the two answer different questions: a release
/// is what the stores ship, a snapshot is what a tester runs between them.
/// Naming the current one here means a bug report can quote itself without
/// digging through settings, and a tester looking at a lagging device can see
/// at a glance which of the two trains it is sitting on.
///
/// The distinction is made by shape, not by lookup: the version string *is*
/// the channel under the current scheme (a release label is `\d+\.\d+`, a
/// snapshot is anything else).
///
/// The layout borrows the phone's "About" page voice — the mark small at the
/// top, and the version number as the thing the eye lands on — so the number,
/// not the card, is what reads first. The card itself is flat, one tonal
/// surface like the three cards across from it, and carries no gradient of its
/// own: the only colour beyond text and badge is the [ShaderMask] gradient the
/// number is painted in.
class _VersionCard extends StatefulWidget {
  const _VersionCard();

  @override
  State<_VersionCard> createState() => _VersionCardState();
}

class _VersionCardState extends State<_VersionCard> {
  /// A release label is a plain `major.minor`; every other shape (`26w33b`,
  /// `dev`, a local build) is a snapshot.
  static final RegExp _releaseLabel = RegExp(r'^\d+\.\d+$');

  /// Stable = green, snapshot = orange — the same pairing the changelog's
  /// release/production chips carry, so the badge and the entry it leads to
  /// agree without any logic in between.
  static const Color _stableColor = Color(0xFF2E7D32);
  static const Color _snapshotColor = Color(0xFFEF6C00);

  /// The contributors of the release this build answers for. A build that no
  /// published release names yet (a local/dev build, or a snapshot newer than
  /// the fetched page) falls back to the newest note's contributors — the
  /// closest published record — so the card is never bare once any note has
  /// been fetched. Empty only when the fetch itself fails.
  List<ReleaseContributor> _contributors = const [];

  /// Whether the avatar slot shows a skeleton. True from the first frame and
  /// **stays true when the fetch fails**: a failed request is indistinguishable
  /// from a slow one to the reader, and collapsing the slot would move the
  /// badge row and make the card feel broken — so the placeholder persists
  /// until real data replaces it.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContributors();
  }

  Future<void> _loadContributors() async {
    final result = await context.read<ChangelogRepository>().releases(page: 1);
    if (!mounted) return;
    setState(() {
      // Failure keeps the skeleton: `_loading` stays true, and the strip
      // below renders the placeholder instead of collapsing.
      switch (result) {
        case Ok(:final value):
          _loading = false;
          _contributors = _contributorsFor(value, AppBuild.label);
        case Err():
          Log.debug(
            'version card contributors: fetch failed: '
            '${result.failureOrNull}',
          );
      }
    });
  }

  List<ReleaseContributor> _contributorsFor(
    List<ReleaseNote> notes,
    String label,
  ) {
    for (final note in notes) {
      if (_isCurrent(note, label)) return contributorsFromBody(note.body);
    }
    if (notes.isEmpty) return const [];
    // No released note names this build (a dev/local label, or a snapshot
    // newer than this page) — fall back to the newest note's record. Newest
    // by publish time, not list position: a page's order is the API's to
    // promise, and the card must not depend on it.
    final newest = notes.reduce(
      (a, b) => a.publishedAt.isAfter(b.publishedAt) ? a : b,
    );
    return contributorsFromBody(newest.body);
  }

  /// Whether a release answers for the running [label]. Mirrors the version
  /// notes page's match (tag or name, `v` stripped) so both pages agree on
  /// which entry is "current" without sharing state.
  static bool _isCurrent(ReleaseNote note, String label) {
    final tag = note.tagName.replaceFirst(RegExp(r'^v'), '');
    final name = note.name.replaceFirst(RegExp(r'^v'), '');
    return tag == label || name == label;
  }

  /// The number's gradient, derived from the version string itself so every
  /// build wears its own colours — 26w34a is one pair, 26w34b another — and
  /// any one build stays stable across reloads. Two hues off the golden
  /// angle (137.5°) harmonise regardless of the hash's starting point; the
  /// lightness flips with the theme so the glyphs read on the card surface.
  static List<Color> _hashGradient(String seed, Brightness brightness) {
    var h = 7;
    for (final rune in seed.runes) {
      h = (h * 31 + rune) & 0x7fffffff;
    }
    final base = h % 360;
    const saturation = 0.62;
    final light = brightness == Brightness.dark ? 0.70 : 0.46;
    return [
      HSLColor.fromAHSL(1, base.toDouble(), saturation, light).toColor(),
      HSLColor.fromAHSL(
        1,
        (base + 137.508) % 360,
        saturation,
        light - 0.10,
      ).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = AppBuild.label;
    final stable = _releaseLabel.hasMatch(label);
    final typeColor = stable ? _stableColor : _snapshotColor;
    final train = AppBuild.train;
    return Material(
      color: colors.surfaceContainer,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: () => context.pushNamed(AppRoutes.versionNotes),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.small,
                    child: Image.asset(
                      'assets/DPIP.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DPIP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.moreTagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const Spacer(),
              // Gradient number, not a plain rect fill: the one stroke of
              // colour the flat card permits. White under srcIn — the gradient
              // takes over the glyphs entirely.
              ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _hashGradient(train, theme.brightness),
                ).createShader(rect),
                child: Text(
                  train,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1,
                  ),
                ),
              ),
              // Fine print below the number: a snapshot is named for the week
              // it was cut, so it prints its own label; a release's label is
              // identical to the train above, so it prints the platform's
              // recorded version instead (what Settings → app shows).
              const SizedBox(height: 2),
              Text(
                stable ? (AppBuild.platformVersion ?? train) : label,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_loading || _contributors.isNotEmpty) ...[
                // The strip sits between the fine-print version and the
                // type badge — a band of faces under the number. While the
                // fetch is in flight the slot is reserved by a skeleton, so
                // the badge row below never jumps when the avatars land.
                _loading
                    ? const _AvatarSkeleton()
                    : _ContributorStack(contributors: _contributors),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Same treatment as the changelog's type chip: tinted wash,
              // hairline of the same hue, coloured label — not a solid fill,
              // which is the one marker the changelog never uses. The badge
              // is followed by the day the build was cut.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      stable
                          ? l10n.moreVersionStable
                          : l10n.moreVersionSnapshot,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (AppBuild.buildDate.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // A snapshot's date can outgrow the narrow card, so the
                    // stamp yields rather than overflow the row.
                    Flexible(
                      child: Text(
                        AppBuild.buildDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The skeleton that reserves the contributor slot while the changelog fetch
/// is in flight — three dim circles at the stack's natural footprint, so the
/// card keeps its height from the first frame and the swap to real avatars
/// moves nothing below it.
class _AvatarSkeleton extends StatelessWidget {
  const _AvatarSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = colors.surfaceContainerHighest.withValues(alpha: 0.45);
    return SizedBox(
      width: 3 * _ContributorStack._extra + _ContributorStack._size,
      height: _ContributorStack._size,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * _ContributorStack._extra,
              child: Container(
                width: _ContributorStack._size - 4,
                height: _ContributorStack._size - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: colors.surfaceContainer, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A width-adaptive stack of contributor avatars for the version card.
///
/// Allocates as many avatars as the card's width offers — as the card is
/// narrow, the stack fits ~5 or 6 before the rest fold into a `+N` chip. Every
/// avatar loads its bytes through [ChangelogRepository.avatarBytes], so the
/// picture round-trips the app's ETag store just like the changelog's strip.
class _ContributorStack extends StatelessWidget {
  const _ContributorStack({required this.contributors});

  final List<ReleaseContributor> contributors;

  /// How much of each avatar the next one covers.
  static const double _overlap = 14;

  /// Avatar circle diameter, including the border.
  static const double _size = 30;

  /// Horizontal advance per avatar — size minus the overlap, so the far edge
  /// of each circle sits exactly under the previous one's border.
  static const double _extra = _size - _overlap;

  @override
  Widget build(BuildContext context) {
    if (contributors.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        // +N chip keeps its own width, counted after every full avatar.
        final chipWidth = _size - 4 + AppSpacing.xs;
        var shown = 1;
        // First avatar takes _size; each further one adds (size - overlap).
        var used = _size;
        while (shown < contributors.length &&
            used + _extra + chipWidth <= constraints.maxWidth) {
          used += _extra;
          shown++;
        }
        final hidden = contributors.length - shown;
        return SizedBox(
          width: used + (hidden > 0 ? chipWidth : 0),
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < shown; i++)
                Positioned(
                  left: i * _extra,
                  child: _VersionAvatar(contributor: contributors[i]),
                ),
              if (hidden > 0)
                Positioned(
                  left: used + AppSpacing.xs,
                  child: _MoreChip(count: hidden),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One avatar circle on the version card — loads its bytes via the shared
/// changelog repository, then paints them; until then, the login's initial.
class _VersionAvatar extends StatefulWidget {
  const _VersionAvatar({required this.contributor});

  final ReleaseContributor contributor;

  @override
  State<_VersionAvatar> createState() => _VersionAvatarState();
}

class _VersionAvatarState extends State<_VersionAvatar> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await context.read<ChangelogRepository>().avatarBytes(
      widget.contributor.login,
    );
    if (!mounted) return;
    setState(() {
      _bytes = switch (bytes) {
        Ok(:final value) => value,
        Err() => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.contributor.login,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.tryParse(widget.contributor.htmlUrl);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Container(
          width: _ContributorStack._size,
          height: _ContributorStack._size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surfaceContainerHighest,
            border: Border.all(color: colors.surfaceContainer, width: 2),
          ),
          child: CircleAvatar(
            radius: _ContributorStack._size / 2 - 2,
            backgroundColor: colors.surfaceContainerHighest,
            foregroundImage: _bytes == null ? null : MemoryImage(_bytes!),
            child: _bytes == null
                ? Text(
                    widget.contributor.login.isEmpty
                        ? '?'
                        : widget.contributor.login[0].toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// The `+N` tail for avatars the card's width could not hold.
class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: _ContributorStack._size - 4,
      height: _ContributorStack._size - 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
        border: Border.all(color: colors.surfaceContainer, width: 2),
      ),
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Uploads the diagnostics and the log, and shows the link.
///
/// Stateful only to hold the spinner: the collection reads a dozen subsystems
/// and the upload is a round trip, so without one the row looks like it did
/// nothing and gets tapped again — which uploads twice.
class _DumpTile extends StatefulWidget {
  const _DumpTile();

  @override
  State<_DumpTile> createState() => _DumpTileState();
}

class _DumpTileState extends State<_DumpTile> {
  bool _running = false;

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    try {
      await runDiagnosticsDump(context);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _MoreTile(
      icon: Icons.ios_share_outlined,
      title: l10n.moreDumpDiagnostics,
      subtitle: l10n.moreDumpDiagnosticsHint,
      // Sized either way, so the row does not shift when the spinner arrives.
      trailing: SizedBox.square(
        dimension: 18,
        child: _running
            ? const CircularProgressIndicator(strokeWidth: 2)
            : null,
      ),
      onTap: _run,
    );
  }
}
