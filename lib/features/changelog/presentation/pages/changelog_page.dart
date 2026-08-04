/// Changelog list — GitHub releases, newest first, accordion detail.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen release list (More → 更新日誌). One row expands at a time;
/// ETag revalidation keeps pull-to-refresh cheap when nothing changed.
class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  String? _installedVersion;

  /// Tag of the single open row; `null` = all collapsed.
  String? _expandedTag;
  bool _didAutoExpand = false;
  final _refresh = RefreshSignal();

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _installedVersion = info.version);
    });
  }

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<ChangelogRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changelogTitle)),
      body: AsyncView<List<ReleaseNote>>(
        future: repo.releases,
        refreshSignal: _refresh,
        isEmpty: (notes) => notes.isEmpty,
        empty: (_) => EmptyView(
          icon: Icons.history_outlined,
          message: l10n.changelogEmpty,
        ),
        builder: (context, notes) {
          _maybeAutoExpand(notes);
          return RefreshIndicator(
            onRefresh: () async {
              _refresh.fire();
              await repo.releases();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _ReleaseTile(
                  note: note,
                  isCurrent: _isCurrent(note),
                  isFirst: index == 0,
                  isLast: index == notes.length - 1,
                  expanded: _expandedTag == note.tagName,
                  onToggle: () => setState(() {
                    _expandedTag = _expandedTag == note.tagName
                        ? null
                        : note.tagName;
                  }),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _maybeAutoExpand(List<ReleaseNote> notes) {
    if (_didAutoExpand || notes.isEmpty) return;
    _didAutoExpand = true;
    final current = notes.where(_isCurrent).firstOrNull;
    final tag = current?.tagName ?? notes.first.tagName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _expandedTag == null) {
        setState(() => _expandedTag = tag);
      }
    });
  }

  bool _isCurrent(ReleaseNote note) {
    final installed = _installedVersion;
    if (installed == null) return false;
    final tag = note.tagName.replaceFirst(RegExp(r'^v'), '');
    final name = note.name.replaceFirst(RegExp(r'^v'), '');
    return tag == installed || name == installed;
  }
}

/// Soft card + timeline rail (no [IntrinsicHeight] — that collapsed the list).
class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({
    required this.note,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.expanded,
    required this.onToggle,
  });

  final ReleaseNote note;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final bool expanded;
  final VoidCallback onToggle;

  static const _stable = Color(0xFF2E7D32);
  static const _prerelease = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typeColor = note.prerelease ? _prerelease : _stable;
    final title = note.name.isEmpty ? note.tagName : note.name;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(note.publishedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Stack(
        children: [
          Positioned(
            left: 7,
            top: isFirst ? 22 : 0,
            bottom: isLast ? 22 : 0,
            child: Container(
              width: 2,
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          Positioned(
            left: 2,
            top: 18,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: (isCurrent || expanded) ? 12 : 8,
              height: (isCurrent || expanded) ? 12 : 8,
              margin: EdgeInsets.only(
                left: (isCurrent || expanded) ? 0 : 2,
                top: (isCurrent || expanded) ? 0 : 2,
              ),
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
                boxShadow: (isCurrent || expanded)
                    ? [
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Material(
              color: isCurrent
                  ? colors.primaryContainer.withValues(alpha: 0.4)
                  : colors.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
                side: BorderSide(
                  color: isCurrent
                      ? colors.primary.withValues(alpha: 0.4)
                      : expanded
                      ? typeColor.withValues(alpha: 0.4)
                      : colors.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                    _TypeChip(
                                      label: note.prerelease
                                          ? l10n.changelogTypePrerelease
                                          : l10n.changelogTypeStable,
                                      color: typeColor,
                                    ),
                                    if (isCurrent)
                                      _TypeChip(
                                        label: l10n.changelogCurrentVersion,
                                        color: colors.primary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  date,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: AppMotion.fast,
                            child: Icon(
                              Icons.expand_more,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: AppMotion.medium,
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: expanded
                        ? _ExpandedBody(
                            body: note.body.isEmpty
                                ? l10n.changelogBodyEmpty
                                : note.body,
                            accent: typeColor,
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.body, required this.accent});

  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final base = MarkdownStyleSheet.fromTheme(theme);
    final sheet = base.copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        height: 1.55,
      ),
      h1: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      h3: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      a: theme.textTheme.bodyMedium?.copyWith(
        color: colors.primary,
        decoration: TextDecoration.underline,
        decorationColor: colors.primary.withValues(alpha: 0.4),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: accent, width: 3)),
        color: accent.withValues(alpha: 0.06),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: colors.onSurface,
        backgroundColor: colors.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.small,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: MarkdownBody(
            data: body,
            selectable: true,
            styleSheet: sheet,
            onTapLink: (text, href, title) => _openLink(href),
          ),
        ),
      ],
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      Log.handle(e, st, 'changelog link failed: $href');
    }
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
