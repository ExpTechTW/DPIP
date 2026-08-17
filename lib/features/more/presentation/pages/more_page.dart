import 'package:dpip/app/theme/app_gold.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:dpip/core/permissions/permission_health.dart';
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
          // The four cards above the menu, one block: version fills the left
          // half of the line, support takes the top half of the right column,
          // and Discord and announcements split the bottom half of it.
          const _HeroCards(),
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Marks the row with the same dot the shell uses, for something the user
  /// should act on. Off for every row that is merely a destination.
  final bool alert;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: alert ? Badge(child: Icon(icon)) : Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
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
  /// height) while the small cards beside it are shorter by design.
  static const double _versionHeight = 176;

  /// Height of a small card (Discord, announcement, status) and, matching it,
  /// the full-width support card below.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    SizedBox(
                      height: _smallCardHeight,
                      child: _DiscordCallout(),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      height: _smallCardHeight,
                      child: _AnnouncementCard(),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    SizedBox(height: _smallCardHeight, child: _StatusCard()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: _smallCardHeight, child: const _SupportCallout()),
        ],
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
class _SupportCallout extends StatelessWidget {
  const _SupportCallout();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gold = AppGold.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gold.fill,
        borderRadius: AppRadius.large,
        border: Border.all(color: gold.edge),
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

/// Server status, directly under the announcement card — the same flat,
/// quiet construction, because a status check is a passive read and needs no
/// more weight than a link.
class _StatusCard extends StatelessWidget {
  const _StatusCard();

  static const String _url = 'https://status.exptech.dev/status';

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
                  Icons.dns_outlined,
                  color: colors.onSurfaceVariant,
                  size: 19,
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
class _VersionCard extends StatelessWidget {
  const _VersionCard();

  /// A release label is a plain `major.minor`; every other shape (`26w33b`,
  /// `dev`, a local build) is a snapshot.
  static final RegExp _releaseLabel = RegExp(r'^\d+\.\d+$');

  /// Stable = green, snapshot = orange — the same pairing the changelog's
  /// release/production chips carry, so the badge and the entry it leads to
  /// agree without any logic in between.
  static const Color _stableColor = Color(0xFF2E7D32);
  static const Color _snapshotColor = Color(0xFFEF6C00);

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
              // A snapshot is named for the week it was cut, not a store
              // version, so the label goes below the number as fine print —
              // smaller, but still a headline next to the badge.
              if (!stable) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // Same treatment as the changelog's type chip: tinted wash,
              // hairline of the same hue, coloured label — not a solid fill,
              // which is the one marker the changelog never uses.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: typeColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  stable ? l10n.moreVersionStable : l10n.moreVersionSnapshot,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
