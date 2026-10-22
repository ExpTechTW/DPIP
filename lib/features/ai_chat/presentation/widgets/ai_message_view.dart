/// The conversation's entries: questions as bubbles, answers full width.
///
/// An answer is not in a bubble: it is Markdown that may hold a list or a
/// short table, and a bubble's width would wrap it into a column of words.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/ai_chat/presentation/ai_chat_controller.dart';
import 'package:dpip/features/ai_chat/presentation/ai_texts.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionBubble extends StatelessWidget {
  const QuestionBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Material(
          color: colors.primaryContainer,
          borderRadius: AppRadius.medium,
          child: InkWell(
            borderRadius: AppRadius.medium,
            onLongPress: () => copyWithToast(context, text),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnswerView extends StatelessWidget {
  const AnswerView({
    super.key,
    required this.answer,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final AnswerEntry answer;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = answer.text;
    final failure = answer.failure;
    final waiting = !answer.done && text.isEmpty;
    final hasRunningTool = answer.tools.any(
      (t) => t.state == ToolState.running,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (subject, state) in _toolLines(l10n))
          _ToolLine(subject: subject, state: state),
        if (waiting && !hasRunningTool)
          _Pending(
            label: answer.thinking ? l10n.aiChatThinking : l10n.aiChatWaiting,
          ),
        if (text.isNotEmpty)
          GestureDetector(
            onLongPress: answer.done
                ? () => copyWithToast(context, text)
                : null,
            child: MarkdownBody(
              data: text,
              selectable: answer.done,
              softLineBreak: true,
              imageBuilder: _imageText,
              onTapLink: (_, href, _) => _open(href),
              styleSheet: _sheet(theme),
            ),
          ),
        if (answer.stopped)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.aiChatStopped,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        if (failure != null)
          _FailureBox(
            message: aiFailureText(l10n, failure),
            detail: failure.detail,
            status: failure.status,
            onRetry: onRetry,
            onOpenSettings: aiFailureNeedsSettings(failure)
                ? onOpenSettings
                : null,
          ),
      ],
    );
  }

  /// One line per kind of data looked up, in first-seen order: four calls
  /// for weather read as one "looked up weather", not four.
  List<(String, ToolState)> _toolLines(AppLocalizations l10n) {
    final lines = <String, ToolState>{};
    for (final tool in answer.tools) {
      final subject = toolSubject(l10n, tool.name);
      final seen = lines[subject];
      lines[subject] = switch ((seen, tool.state)) {
        (ToolState.running, _) || (_, ToolState.running) => ToolState.running,
        (ToolState.ok, _) || (_, ToolState.ok) => ToolState.ok,
        _ => ToolState.failed,
      };
    }
    return [for (final MapEntry(:key, :value) in lines.entries) (key, value)];
  }

  /// The markdown styles an answer renders with.
  ///
  /// Built explicitly rather than through `MarkdownStyleSheet.fromTheme`:
  /// that factory takes Flutter's legacy Material theme, which is a different
  /// type from the one this app themes with, and the markdown package is the
  /// one widget still on the old API. Every field the builder asserts on is
  /// set here, so an answer with a heading, a table or a task list cannot
  /// crash the page.
  static MarkdownStyleSheet _sheet(ThemeData theme) {
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final body = text.bodyMedium?.copyWith(
      color: colors.onSurface,
      height: 1.5,
    );
    const cells = EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    );
    return MarkdownStyleSheet(
      p: body,
      pPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
      a: body?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
      strong: body?.copyWith(fontWeight: FontWeight.w700),
      em: body?.copyWith(fontStyle: FontStyle.italic),
      del: body?.copyWith(decoration: TextDecoration.lineThrough),
      h1: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      h1Padding: const EdgeInsets.only(top: AppSpacing.sm),
      h2: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      h2Padding: const EdgeInsets.only(top: AppSpacing.sm),
      h3: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      h3Padding: const EdgeInsets.only(top: AppSpacing.xs),
      h4: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      h4Padding: const EdgeInsets.only(top: AppSpacing.xs),
      h5: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      h5Padding: EdgeInsets.zero,
      h6: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      h6Padding: EdgeInsets.zero,
      blockSpacing: AppSpacing.xs,
      listIndent: AppSpacing.lg,
      listBullet: body,
      listBulletPadding: const EdgeInsets.only(right: AppSpacing.xs),
      code: text.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: colors.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.small,
      ),
      codeblockPadding: const EdgeInsets.all(AppSpacing.sm),
      blockquote: body?.copyWith(color: colors.onSurfaceVariant),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.outlineVariant, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      // The prompt discourages tables, but a model still sends them.
      tableHead: text.labelLarge,
      tableBody: text.bodySmall,
      tableBorder: TableBorder.all(color: colors.outlineVariant),
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableCellsPadding: cells,
      tableHeadCellsPadding: cells,
      checkbox: body,
      superscriptFontFeatureTag: 'sups',
    );
  }

  static Future<void> _open(String? href) async {
    final uri = href == null ? null : Uri.tryParse(href);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'ai chat: opening a link');
    }
  }

  /// Model output never fetches an image: whatever it names is shown as its
  /// own alt text. The package's default builder would load every http(s)
  /// image the reply mentions, which lets a response make the phone call a
  /// host the user never configured, before anyone taps anything.
  static Widget _imageText(Uri uri, String? title, String? alt) =>
      Text(alt ?? '');
}

class _ToolLine extends StatelessWidget {
  const _ToolLine({required this.subject, required this.state});

  final String subject;
  final ToolState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: state == ToolState.failed ? colors.error : colors.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: switch (state) {
              ToolState.running => const CircularProgressIndicator(
                strokeWidth: 2,
              ),
              ToolState.ok => Icon(
                Icons.check_circle_outline,
                size: 16,
                color: colors.primary,
              ),
              ToolState.failed => Icon(
                Icons.error_outline,
                size: 16,
                color: colors.error,
              ),
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(switch (state) {
              ToolState.running => l10n.aiToolRunning(subject),
              ToolState.ok => l10n.aiToolDone(subject),
              ToolState.failed => l10n.aiToolFailed(subject),
            }, style: style),
          ),
        ],
      ),
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureBox extends StatelessWidget {
  const _FailureBox({
    required this.message,
    required this.detail,
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final String message;
  final String? detail;
  final int? status;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // The service's own words, untranslated, with the status beside them.
    final said = [if (status != null) 'HTTP $status', ?detail].join(' · ');
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onErrorContainer,
            ),
          ),
          if (said.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              l10n.aiErrorServiceSaid(said),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onErrorContainer,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
              if (onOpenSettings != null)
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.aiChatOpenSettings),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> copyWithToast(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).aiChatCopied)),
    );
}
