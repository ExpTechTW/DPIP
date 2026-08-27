/// 已回報的錯誤 — a read-only, GitHub-issues-style view of the bug threads
/// mirrored from the Discord tracker.
///
/// Every thread row carries its tags as badges, a two-line body preview and
/// the reply count; tapping opens the full discussion. There is deliberately
/// no composer anywhere: triage happens on Discord, this is a window.
library;

import 'dart:typed_data';

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/bug_tracker/bug_tracker_counter.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:dpip/features/bug_tracker/presentation/widgets/bug_avatar_image.dart';
import 'package:dpip/features/bug_tracker/presentation/widgets/bug_tag_badge.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fetches one avatar through the shared ETag/gzip Dio stack.
typedef AvatarFetch = Future<Uint8List?> Function(String url);

/// The two sort modes the tracker offers.
enum BugSort {
  /// Threads whose conversation was replied to most recently.
  lastActivity,

  /// Threads with the most replies.
  mostDiscussed,
}

class BugListPage extends StatefulWidget {
  const BugListPage({super.key, this.repository});

  /// Injectable for tests; defaults to the provider-registered implementation.
  final BugRepository? repository;

  @override
  State<BugListPage> createState() => _BugListPageState();
}

class _BugListPageState extends State<BugListPage> {
  final RefreshSignal _refresh = RefreshSignal();

  /// Sort mode — switched from the chip bar above the list.
  BugSort _sort = BugSort.lastActivity;

  /// Active tag filters — a thread must carry every one of these to show.
  /// Toggled by tapping the filter chips; empty means no filter.
  final Set<String> _tagFilters = {};

  void _toggleTagFilter(String tag) {
    setState(() {
      _tagFilters.contains(tag)
          ? _tagFilters.remove(tag)
          : _tagFilters.add(tag);
    });
  }

  /// Threads passing the active filters and sort mode, in display order.
  List<BugThread> _visibleThreads(List<BugThread> threads) {
    var list = threads;
    if (_tagFilters.isNotEmpty) {
      list = [
        for (final thread in list)
          if (_tagFilters.every(thread.tags.contains)) thread,
      ];
    }
    final sorted = [...list];
    switch (_sort) {
      case BugSort.lastActivity:
        sorted.sort((a, b) => b.lastMessageId.compareTo(a.lastMessageId));
      case BugSort.mostDiscussed:
        sorted.sort((a, b) => b.messageCount.compareTo(a.messageCount));
    }
    return sorted;
  }

  /// Every distinct cleaned tag present in [threads], most-used first — the
  /// filter-chip row's contents.
  List<String> _knownTags(List<BugThread> threads) {
    final count = <String, int>{};
    for (final thread in threads) {
      for (final tag in thread.tags) {
        count[tag] = (count[tag] ?? 0) + 1;
      }
    }
    final entries = count.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries) e.key];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = widget.repository ?? context.read<BugRepository>();
    Future<Uint8List?> avatarFor(String url) =>
        repo.avatar(url).then((result) => result.valueOrNull);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreBugReports)),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: const _DiscordReportButton(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: AsyncView<List<BugThread>>(
              future: repo.threads,
              refreshSignal: _refresh,
              isEmpty: (threads) => threads.isEmpty,
              builder: (context, threads) {
                final theme = Theme.of(context);
                final visible = _visibleThreads(threads);
                final knownTags = _knownTags(threads);
                // Tag filtering happens at display time — the repository stays
                // a pure mirror of the source, and toggling is instant without
                // a re-fetch.
                return Column(
                  children: [
                    // Sort chips (neutral) then a divider, then the coloured
                    // tag filters — two groups, one bar.
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        children: [
                          ChoiceChip(
                            label: Text(l10n.bugTrackerSortLast),
                            selected: _sort == BugSort.lastActivity,
                            onSelected: (_) =>
                                setState(() => _sort = BugSort.lastActivity),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          ChoiceChip(
                            label: Text(l10n.bugTrackerSortMostDiscussed),
                            selected: _sort == BugSort.mostDiscussed,
                            onSelected: (_) =>
                                setState(() => _sort = BugSort.mostDiscussed),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: SizedBox(
                              height: 20,
                              child: VerticalDivider(
                                width: 1,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          for (final tag in knownTags)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: BugTagFilterChip(
                                tag: tag,
                                selected: _tagFilters.contains(tag),
                                onSelected: (_) => _toggleTagFilter(tag),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty && _tagFilters.isNotEmpty
                          ? ListView(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.xl,
                                AppSpacing.lg,
                                AppSpacing.xl,
                              ),
                              children: [
                                EmptyView(
                                  icon: Icons.filter_alt_off_outlined,
                                  message: l10n.bugTrackerNoMatch,
                                ),
                              ],
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                _refresh.fire();
                                await context
                                    .read<BugTrackerCounter>()
                                    .refresh();
                              },
                              child: ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  AppSpacing.sm,
                                  AppSpacing.lg,
                                  AppSpacing.xl +
                                      MediaQuery.paddingOf(context).bottom,
                                ),
                                itemCount: visible.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) => _ThreadCard(
                                  thread: visible[index],
                                  avatarFor: avatarFor,
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The report call-to-action above the list — links to the Discord channel
/// where new bugs are reported, since this screen is read-only by design.
class _DiscordReportButton extends StatelessWidget {
  const _DiscordReportButton();

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
        onTap: () async {
          final failed = l10n.moreLinkOpenFailed;
          try {
            final ok = await launchUrl(
              Uri.parse(_url),
              mode: LaunchMode.externalApplication,
            );
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(failed)));
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(failed)));
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.forum_outlined,
                size: 20,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.bugTrackerGoToDiscord,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_outlined,
                size: 18,
                color: colors.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain-text two-line preview of a markdown body.
///
/// [MarkdownBody] cannot truncate to N lines, and a half-rendered heading or
/// link inside a two-line preview reads as noise anyway — so the syntax is
/// stripped here and the result flows as ordinary text. Images vanish, link
/// labels survive, headings lose their `#`, emphasis markers come off.
String _bugPreview(String body) => body
    .replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (_) => '')
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!)
    .replaceAll(RegExp(r'```[a-zA-Z]*'), ' ')
    .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
    .replaceAll(RegExp(r'^\s*[-+*]\s+', multiLine: true), '• ')
    .replaceAll(RegExp(r'[*_~`]'), '')
    .replaceAll('\n', ' ')
    .trim();

/// One thread row — title, tag badges, body preview, author and reply count.
/// The dot between two facts in a card's meta row.
///
/// Its own widget so the padding either side stays symmetric wherever it is
/// used: a bare `Text('·')` inherits whatever `SizedBox` happens to sit next to
/// it, and the separator then sits visibly closer to one side than the other.
class _MetaDot extends StatelessWidget {
  const _MetaDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
    // l10n-ignore: punctuation, not display text
    child: Text(
      '·',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.thread, required this.avatarFor});

  final BugThread thread;
  final AvatarFetch avatarFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = DateFormat('yyyy/MM/dd').format(thread.createdAt.toLocal());
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.bugThread,
          pathParameters: {'id': '${thread.id}'},
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thread.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              if (thread.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in thread.tags) BugTagBadge(tag: tag),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                _bugPreview(thread.body),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  CircleAvatar(
                    radius: 9,
                    // 部分作者的 id 不在 users 目錄（已刪除帳號等）——解析出
                    // 空 URL，此時顯示人形佔位而非對空 URI 發請求。
                    backgroundImage: thread.authorAvatar.isEmpty
                        ? null
                        : BugAvatarImage(thread.authorAvatar, avatarFor),
                    onBackgroundImageError: thread.authorAvatar.isEmpty
                        ? null
                        : (_, _) {},
                    child: thread.authorAvatar.isEmpty
                        ? const Icon(Icons.person_outline, size: 10)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      thread.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.mode_comment_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${thread.messageCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  // The reply count and the date are two different facts about
                  // the thread, and spacing alone left them reading as one
                  // run-on figure. A middle dot is the separator, not a word —
                  // it needs no translation and carries none.
                  // l10n-ignore: punctuation, not display text
                  _MetaDot(color: colors.onSurfaceVariant),
                  Text(
                    date,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  // The row ends where the tap leads. The whole card is an
                  // InkWell, but nothing in it said so until now — every other
                  // list in the app puts a chevron at the end of a row that
                  // opens something.
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
