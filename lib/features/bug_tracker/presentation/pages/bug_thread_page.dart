/// One reported bug, read-only — the opening post plus the replies, laid out
/// like a Discord thread: header card first, then chat-style messages, and
/// where a chat's input would sit, a button handing discussion back to
/// Discord (this screen is read-only by design).
///
/// Staff authors ([bugTrackerAdminIds]) carry a developer badge so official
/// replies are visually distinct from user chatter. A reply whose text is
/// null (deleted, or attachments/embeds only) shows a view-on-Discord
/// placeholder instead of an empty bubble. Bodies render as markdown — the
/// tracker mirrors Discord text, which is written in it.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/bug_tracker/domain/bug_repository.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:dpip/features/bug_tracker/presentation/widgets/bug_avatar_image.dart';
import 'package:dpip/features/bug_tracker/presentation/widgets/bug_tag_badge.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fetches one avatar through the shared ETag/gzip Dio stack.
typedef AvatarFetch = Future<Uint8List?> Function(String url);

/// Compact markdown sheet shared by the opening post and every reply — one
/// definition so the two never drift apart visually.
MarkdownStyleSheet _markdownSheet(BuildContext context) {
  final theme = Theme.of(context);
  return MarkdownStyleSheet(
    p: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      height: 1.5,
    ),
    strong: theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    ),
    em: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
    code: theme.textTheme.bodySmall?.copyWith(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    ),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: AppRadius.small,
    ),
    listIndent: AppSpacing.sm,
  );
}

class BugThreadPage extends StatelessWidget {
  const BugThreadPage({super.key, required this.id, this.repository});

  /// The tracker thread id from the route.
  final int id;

  /// Injectable for tests; defaults to the provider-registered implementation.
  final BugRepository? repository;

  static const String _discordUrl = 'https://exptech.com.tw/dc';

  Future<void> _openDiscord(BuildContext context) async {
    final failed = AppLocalizations.of(context).moreLinkOpenFailed;
    try {
      final ok = await launchUrl(
        Uri.parse(_discordUrl),
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = repository ?? context.read<BugRepository>();
    Future<Uint8List?> avatarFor(String url) =>
        repo.avatar(url).then((result) => result.valueOrNull);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreBugReports)),
      body: AsyncView<BugThreadDetail>(
        future: () => repo.thread(id),
        builder: (context, detail) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  children: [
                    _OpeningPost(detail: detail, avatarFor: avatarFor),
                    const SizedBox(height: AppSpacing.lg),
                    if (detail.messages.isNotEmpty) ...[
                      Text(
                        l10n.bugTrackerReplies,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final message in detail.messages) ...[
                        _ChatReply(message: message, avatarFor: avatarFor),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ],
                ),
              ),
              // Pinned: where a chat's input would sit, the hand-off back to
              // Discord stays put while the thread scrolls above it.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.xs,
                ),
                child: _JoinDiscussionButton(
                  onOpen: () => _openDiscord(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The opening post: title, tag badges, author row, body as markdown.
class _OpeningPost extends StatelessWidget {
  const _OpeningPost({required this.detail, required this.avatarFor});

  final BugThreadDetail detail;
  final AvatarFetch avatarFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final thread = detail.thread;
    final created = DateFormat('yyyy/MM/dd HH:mm')
        .format(thread.createdAt.toLocal());
    // OP author id lives on the model; see bug_thread.dart.
    final staff = isBugTrackerStaff(thread.author);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  thread.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (thread.locked)
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
          if (thread.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [for (final tag in thread.tags) BugTagBadge(tag: tag)],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: thread.authorAvatar.isEmpty
                    ? null
                    : BugAvatarImage(thread.authorAvatar, avatarFor),
                onBackgroundImageError: thread.authorAvatar.isEmpty
                    ? null
                    : (_, _) {},
                child: thread.authorAvatar.isEmpty
                    ? const Icon(Icons.person_outline, size: 18)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            thread.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: staff ? colors.primary : null,
                            ),
                          ),
                        ),
                        if (staff) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const _DeveloperBadge(),
                        ],
                      ],
                    ),
                    Text(
                      created,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (thread.body.isNotEmpty)
            MarkdownBody(
              data: thread.body,
              selectable: true,
              styleSheet: _markdownSheet(context),
            ),
        ],
      ),
    );
  }
}

/// One reply, chat-style — avatar left, name/time/body right, no card chrome.
class _ChatReply extends StatelessWidget {
  const _ChatReply({required this.message, required this.avatarFor});

  final BugMessage message;
  final AvatarFetch avatarFor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final staff = isBugTrackerStaff(message.author);
    final time = DateFormat('yyyy/MM/dd HH:mm').format(message.time.toLocal());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundImage: message.authorAvatar.isEmpty
              ? null
              : BugAvatarImage(message.authorAvatar, avatarFor),
          onBackgroundImageError: message.authorAvatar.isEmpty
              ? null
              : (_, _) {},
          child: message.authorAvatar.isEmpty
              ? const Icon(Icons.person_outline, size: 16)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      message.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: staff ? colors.primary : null,
                      ),
                    ),
                  ),
                  if (staff) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const _DeveloperBadge(),
                  ],
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Null text = deleted / attachments-only on Discord; point at
              // the source instead of rendering an empty bubble.
              message.body == null
                  ? const _CannotDisplay()
                  : MarkdownBody(
                      data: message.body!,
                      selectable: true,
                      softLineBreak: true,
                      styleSheet: _markdownSheet(context),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The view-on-Discord placeholder for messages without renderable text.
class _CannotDisplay extends StatelessWidget {
  const _CannotDisplay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse('https://exptech.com.tw/dc'),
        mode: LaunchMode.externalApplication,
      ),
      borderRadius: AppRadius.small,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.bugTrackerCannotDisplay,
              style: theme.textTheme.bodySmall,
            ),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// The small「開發人員」tag beside staff names.
class _DeveloperBadge extends StatelessWidget {
  const _DeveloperBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        AppLocalizations.of(context).bugTrackerDeveloper,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Where a chat's composer would sit — a quiet hand-off to Discord instead.
class _JoinDiscussionButton extends StatelessWidget {
  const _JoinDiscussionButton({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).bugTrackerJoinDiscussion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
