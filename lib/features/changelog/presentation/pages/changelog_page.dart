/// Changelog list — GitHub releases, newest first, accordion detail.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/version/app_build.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/changelog/domain/update_check.dart';
import 'package:dpip/features/changelog/presentation/widgets/platform_tag.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
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

  /// Everything fetched so far, oldest page last.
  ///
  /// Pages accumulate here rather than being re-fetched whole: a snapshot is
  /// published on every push, so the list only grows, and re-reading all of it
  /// to add thirty entries would get slower every week.
  final List<ReleaseNote> _notes = [];
  final ScrollController _scroll = ScrollController();
  int _page = 1;
  bool _loading = false;

  /// A page shorter than the API's own page size is the last one — GitHub says
  /// so by answering short, and that is cheaper than parsing the `Link` header
  /// the response also carries.
  bool _exhausted = false;

  /// Whether snapshots are shown alongside releases.
  ///
  /// **On by default**: the page's job is to say what has changed, and a
  /// snapshot is a change that shipped. Hiding them would mean a build someone
  /// is actually running has no entry — every commit on main publishes one, so
  /// most installed builds *are* snapshots, and the row marked "installed"
  /// would be missing for them.
  ///
  /// The toggle is for the opposite want: someone tracking releases only, who
  /// can turn the rest off.
  bool _showSnapshots = true;

  List<ReleaseNote> get _visible => _showSnapshots
      ? _notes
      : [
          for (final note in _notes)
            if (!note.prerelease) note,
        ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // The build's own name, not the platform's: `PackageInfo.version` is the
    // train Apple was told (`26.1.0`), which every snapshot in a release cycle
    // shares. Marking "installed" against it would tick the wrong entry.
    AppBuild.ensureLoaded().then((_) {
      if (mounted) setState(() => _installedVersion = AppBuild.label);
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _refresh.dispose();
    super.dispose();
  }

  /// Fetches the next page while the reader is still a screen away from the
  /// end, so the list grows before it runs out under them.
  void _onScroll() {
    if (!_scroll.hasClients || _loading || _exhausted) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.offset;
    if (remaining < MediaQuery.sizeOf(context).height) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _exhausted) return;
    setState(() => _loading = true);
    final result = await context.read<ChangelogRepository>().releases(
      page: _page + 1,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _page++;
          if (value.length < ChangelogRepository.pageSize) _exhausted = true;
          // Guard against a duplicate: page one merges `/releases/latest`,
          // which can also appear on a later page.
          final seen = {for (final n in _notes) n.tagName};
          _notes.addAll(value.where((n) => !seen.contains(n.tagName)));
        case Err():
          // A failed page is not an error state — the list already on screen
          // is still good. Scrolling again retries.
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<ChangelogRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.changelogTitle),
        actions: [
          // Everything shows by default; this narrows it to releases. An
          // action rather than a setting, because it changes what this one
          // page shows and nothing else.
          IconButton(
            onPressed: () => setState(() => _showSnapshots = !_showSnapshots),
            isSelected: _showSnapshots,
            icon: const Icon(Icons.science_outlined),
            selectedIcon: const Icon(Icons.science),
            tooltip: l10n.changelogShowSnapshots,
          ),
        ],
      ),
      body: AsyncView<List<ReleaseNote>>(
        future: () => repo.releases(page: 1),
        refreshSignal: _refresh,
        isEmpty: (notes) => notes.isEmpty,
        empty: (_) => EmptyView(
          icon: Icons.history_outlined,
          message: l10n.changelogEmpty,
        ),
        builder: (context, notes) {
          _seedFirstPage(notes);
          final visible = _visible;
          _maybeAutoExpand(visible);
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _notes.clear();
                _page = 1;
                _exhausted = false;
              });
              _refresh.fire();
            },
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              // One extra row while more is coming, for the spinner.
              itemCount: visible.length + (_exhausted ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= visible.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final note = visible[index];
                return _ReleaseTile(
                  note: note,
                  isCurrent: _isCurrent(note),
                  isFirst: index == 0,
                  isLast: index == visible.length - 1 && _exhausted,
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

  /// Adopts the first page `AsyncView` fetched, so it is not fetched twice.
  ///
  /// The page owns the accumulated list from then on; `AsyncView` keeps owning
  /// the loading and error states for that first request, which is the one
  /// where there is nothing on screen yet to fall back to.
  void _seedFirstPage(List<ReleaseNote> notes) {
    if (_notes.isNotEmpty || notes.isEmpty) return;
    _notes.addAll(notes);
    if (notes.length < ChangelogRepository.pageSize) _exhausted = true;
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

/// Soft card + continuous timeline rail (painted through the inter-item gap).
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
  static const _railWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typeColor = note.prerelease ? _prerelease : _stable;
    final typeIcon = note.prerelease
        ? Icons.science_outlined
        : Icons.verified_outlined;
    final title = note.name.isEmpty ? note.tagName : note.name;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(note.publishedAt.toLocal());
    final emphasized = isCurrent || expanded;

    return CustomPaint(
      painter: _TimelinePainter(
        lineColor: colors.outlineVariant.withValues(alpha: 0.7),
        dotColor: typeColor,
        isFirst: isFirst,
        isLast: isLast,
        emphasized: emphasized,
        railWidth: _railWidth,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: _railWidth,
          bottom: isLast ? 0 : AppSpacing.md,
        ),
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
                                Icon(typeIcon, size: 22, color: typeColor),
                                Text(
                                  title,
                                  style: theme.textTheme.titleMedium?.copyWith(
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
                        // One language, not both: the published note carries
                        // 中文 and a folded English half, and the fold is HTML
                        // that this renderer does not implement.
                        body: note.body.isEmpty
                            ? l10n.changelogBodyEmpty
                            : localizedReleaseBody(
                                note.body,
                                Localizations.localeOf(context).toLanguageTag(),
                              ),
                        accent: typeColor,
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the left rail through the tile **and** its bottom gap so ListView
/// clipping cannot break the line between cards.
class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.lineColor,
    required this.dotColor,
    required this.isFirst,
    required this.isLast,
    required this.emphasized,
    required this.railWidth,
  });

  final Color lineColor;
  final Color dotColor;
  final bool isFirst;
  final bool isLast;
  final bool emphasized;
  final double railWidth;

  static const _dotCenterY = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final x = railWidth / 2;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    final top = isFirst ? _dotCenterY : 0.0;
    final bottom = isLast ? _dotCenterY : size.height;
    if (bottom > top) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), line);
    }

    final r = emphasized ? 6.0 : 4.0;
    if (emphasized) {
      canvas.drawCircle(
        Offset(x, _dotCenterY),
        r + 3,
        Paint()..color = dotColor.withValues(alpha: 0.28),
      );
    }
    canvas.drawCircle(Offset(x, _dotCenterY), r, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.lineColor != lineColor ||
      old.dotColor != dotColor ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.emphasized != emphasized ||
      old.railWidth != railWidth;
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.body, required this.accent});

  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sheet = MarkdownStyleSheet(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
        ColoredBox(
          color: colors.surface.withValues(alpha: 0.35),
          child: Padding(
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
              softLineBreak: true,
              onTapLink: (text, href, title) => _openLink(href),
              imageBuilder: platformTagIcon,
            ),
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
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
