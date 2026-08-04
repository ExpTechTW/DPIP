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
        builder: (context, notes) => RefreshIndicator(
          onRefresh: () async {
            _refresh.fire();
            await repo.releases();
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final note = notes[index];
              return _ReleaseTile(
                note: note,
                isCurrent: _isCurrent(note),
                expanded: _expandedTag == note.tagName,
                onToggle: () => setState(() {
                  _expandedTag = _expandedTag == note.tagName
                      ? null
                      : note.tagName;
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isCurrent(ReleaseNote note) {
    final installed = _installedVersion;
    if (installed == null) return false;
    final tag = note.tagName.replaceFirst(RegExp(r'^v'), '');
    final name = note.name.replaceFirst(RegExp(r'^v'), '');
    return tag == installed || name == installed;
  }
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({
    required this.note,
    required this.isCurrent,
    required this.expanded,
    required this.onToggle,
  });

  final ReleaseNote note;
  final bool isCurrent;
  final bool expanded;
  final VoidCallback onToggle;

  static const _stable = Color(0xFF2E7D32);
  static const _prerelease = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final typeColor = note.prerelease ? _prerelease : _stable;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(note.publishedAt.toLocal());

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _TypeChip(
                    label: note.prerelease
                        ? l10n.changelogTypePrerelease
                        : l10n.changelogTypeStable,
                    color: typeColor,
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _TypeChip(
                      label: l10n.changelogCurrentVersion,
                      color: colors.secondary,
                    ),
                  ],
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.name.isEmpty ? note.tagName : note.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
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
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: MarkdownBody(
                data: note.body.isEmpty ? l10n.changelogBodyEmpty : note.body,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                onTapLink: (text, href, title) => _openLink(href),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppMotion.medium,
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
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
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
