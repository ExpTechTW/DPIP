/// This build's own release note.
///
/// The version card on More leads here instead of the full changelog: a user
/// who taps "what changed in *this* build" wants one answer, not thirty
/// entries with an accordion full of context. The page fetches the same
/// releases list, finds the entry whose tag or name matches the running
/// label, and shows just that body with the type colour of the build — green
/// for a release, orange for a snapshot, the same pairing the badge on the
/// card carries.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/domain/update_check.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// One release note — the one that names this build.
class VersionNotesPage extends StatelessWidget {
  const VersionNotesPage({super.key});

  static const Color _stableColor = Color(0xFF2E7D32);
  static const Color _snapshotColor = Color(0xFFEF6C00);

  /// Whether a release answers for the running [label]. Mirrors the changelog
  /// page's match (tag or name, `v` stripped) so both pages agree on which
  /// entry is "current" without sharing state.
  static bool _isCurrent(ReleaseNote note, String label) {
    final tag = note.tagName.replaceFirst(RegExp(r'^v'), '');
    final name = note.name.replaceFirst(RegExp(r'^v'), '');
    return tag == label || name == label;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<ChangelogRepository>();
    final label = AppBuild.label;
    final stable = RegExp(r'^\d+\.\d+$').hasMatch(label);
    final typeColor = stable ? _stableColor : _snapshotColor;
    final refresh = RefreshSignal();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreVersionNotes)),
      body: AsyncView<List<ReleaseNote>>(
        future: () => repo.releases(page: 1),
        refreshSignal: refresh,
        isEmpty: (notes) => notes.isEmpty,
        empty: (_) => EmptyView(
          icon: Icons.history_outlined,
          message: l10n.moreVersionNotesEmpty,
        ),
        builder: (context, notes) {
          final note = notes.where((n) => _isCurrent(n, label)).firstOrNull;
          if (note == null) {
            return EmptyView(
              icon: Icons.question_mark_outlined,
              message: l10n.moreVersionNotesEmpty,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refresh.fire(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                _Header(note: note, isStable: stable),
                const SizedBox(height: AppSpacing.md),
                _Body(
                  body: note.body.isEmpty
                      ? l10n.changelogBodyEmpty
                      : localizedReleaseBody(
                          note.body,
                          Localizations.localeOf(context).toLanguageTag(),
                        ),
                  accent: typeColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The type chip, name, label and date — what the release calls itself and
/// when it went out.
class _Header extends StatelessWidget {
  const _Header({required this.note, required this.isStable});

  final ReleaseNote note;
  final bool isStable;

  static const Color _stableColor = Color(0xFF2E7D32);
  static const Color _snapshotColor = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typeColor = isStable ? _stableColor : _snapshotColor;
    final title = note.name.isEmpty ? note.tagName : note.name;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(note.publishedAt.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: Icon(
            isStable ? Icons.verified_outlined : Icons.science_outlined,
            size: 18,
            color: Colors.white,
          ),
          label: Text(
            isStable ? l10n.changelogTypeStable : l10n.changelogTypePrerelease,
          ),
          backgroundColor: typeColor,
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          side: const BorderSide(color: Colors.transparent),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          date,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The release note body, rendered like the changelog's expanded tile so a
/// user sees the same typography in both places.
class _Body extends StatelessWidget {
  const _Body({required this.body, required this.accent});

  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: MarkdownBody(
          data: body,
          selectable: true,
          styleSheet: _sheet(theme, colors, accent),
          softLineBreak: true,
          onTapLink: (text, href, title) => _openLink(href),
        ),
      ),
    );
  }

  MarkdownStyleSheet _sheet(ThemeData theme, ColorScheme colors, Color accent) {
    return MarkdownStyleSheet(
      p: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        height: 1.6,
      ),
      pPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colors.onSurface,
        letterSpacing: -0.3,
      ),
      h1Padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: accent,
        letterSpacing: -0.2,
      ),
      h2Padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      h3Padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      h4: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurfaceVariant,
      ),
      h4Padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      em: theme.textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: colors.onSurfaceVariant,
      ),
      strong: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: colors.onSurface,
      ),
      del: theme.textTheme.bodyMedium?.copyWith(
        decoration: TextDecoration.lineThrough,
        color: colors.onSurfaceVariant,
      ),
      a: theme.textTheme.bodyMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: colors.primary.withValues(alpha: 0.5),
      ),
      blockSpacing: AppSpacing.md,
      listIndent: AppSpacing.xl,
      listBullet: theme.textTheme.bodyMedium?.copyWith(
        color: accent,
        fontWeight: FontWeight.w800,
      ),
      listBulletPadding: const EdgeInsets.only(right: AppSpacing.sm),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      blockquoteDecoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: AppRadius.small,
        border: Border(left: BorderSide(color: accent, width: 4)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        color: colors.primary,
        backgroundColor: colors.primaryContainer.withValues(alpha: 0.45),
      ),
      codeblockPadding: const EdgeInsets.all(AppSpacing.md),
      codeblockDecoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.small,
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.35), width: 2),
        ),
      ),
      tableHead: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      tableBody: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
      tableBorder: TableBorder.all(color: colors.outlineVariant, width: 1),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      checkbox: theme.textTheme.bodyMedium?.copyWith(color: accent),
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'version notes link failed: $href');
    }
  }
}
