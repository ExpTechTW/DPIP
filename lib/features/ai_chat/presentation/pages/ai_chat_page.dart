/// The AI assistant, pushed over the shell from Home's region bar: the
/// explanation the first time, then the conversation. Leaving it keeps the
/// conversation, which lives in [AiChatController], not in this page.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/ai_chat/presentation/ai_chat_controller.dart';
import 'package:dpip/features/ai_chat/presentation/ai_setup.dart';
import 'package:dpip/features/ai_chat/presentation/widgets/ai_intro.dart';
import 'package:dpip/features/ai_chat/presentation/widgets/ai_message_view.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final setup = context.watch<AiSetup>();
    if (!setup.introSeen) return const _IntroPage();
    return const _ChatPage();
  }
}

void _openSettings(BuildContext context) =>
    context.pushNamed(AppRoutes.aiSettings);

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiChatTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const AiIntro(),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () async {
              final setup = context.read<AiSetup>();
              await setup.markIntroSeen();
              if (!setup.ready && context.mounted) _openSettings(context);
            },
            child: Text(l10n.aiIntroStart),
          ),
        ],
      ),
    );
  }
}

class _ChatPage extends StatefulWidget {
  const _ChatPage();

  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(String text) {
    final l10n = AppLocalizations.of(context);
    final chat = context.read<AiChatController>();
    if (text.trim().isEmpty || chat.busy) return;
    _input.clear();
    chat.send(
      text,
      language: l10n.languageName,
      localeTag: Localizations.localeOf(context).toLanguageTag(),
    );
  }

  void _retry(AnswerEntry answer) {
    final l10n = AppLocalizations.of(context);
    context.read<AiChatController>().retry(
      answer,
      language: l10n.languageName,
      localeTag: Localizations.localeOf(context).toLanguageTag(),
    );
  }

  Future<void> _showIntro() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheet) => FractionallySizedBox(
      heightFactor: 0.9,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(sheet).bottom,
        ),
        children: const [AiIntro()],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = context.select<AiSetup, bool>((s) => s.ready);
    final chat = context.watch<AiChatController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiChatTitle),
        actions: [
          IconButton(
            tooltip: l10n.aiChatNew,
            onPressed: chat.isEmpty ? null : chat.clear,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: l10n.aiChatAbout,
            onPressed: _showIntro,
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: l10n.aiSettingsTitle,
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: !ready
          ? const _SetupNeeded()
          : Column(
              children: [
                Expanded(
                  child: chat.isEmpty
                      ? _Suggestions(onPick: _send)
                      : _Conversation(
                          chat: chat,
                          onRetry: _retry,
                          onOpenSettings: () => _openSettings(context),
                        ),
                ),
                _Composer(
                  controller: _input,
                  busy: chat.busy,
                  onSend: () => _send(_input.text),
                  onStop: chat.stop,
                ),
              ],
            ),
    );
  }
}

class _Conversation extends StatelessWidget {
  const _Conversation({
    required this.chat,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final AiChatController chat;
  final void Function(AnswerEntry answer) onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final entries = chat.entries;
    // Reversed, so the newest entry sits at the bottom and a streaming
    // answer stays in view as it grows, with no scrolling to manage.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: switch (entry) {
            QuestionEntry(:final text) => QuestionBubble(text: text),
            final AnswerEntry answer => AnswerView(
              answer: answer,
              onRetry: () => onRetry(answer),
              onOpenSettings: onOpenSettings,
            ),
          },
        );
      },
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});

  final void Function(String text) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final suggestions = [
      l10n.aiChatSuggestionQuakes,
      l10n.aiChatSuggestionRain,
      l10n.aiChatSuggestionTyphoon,
      l10n.aiChatSuggestionAlerts,
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.auto_awesome_outlined,
          size: 40,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.aiChatEmptyTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final text in suggestions)
              ActionChip(label: Text(text), onPressed: () => onPick(text)),
          ],
        ),
      ],
    );
  }
}

class _SetupNeeded extends StatelessWidget {
  const _SetupNeeded();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.key_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.aiChatSetupTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.aiChatSetupBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _openSettings(context),
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.aiChatSetupAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      child: Padding(
        // Clears the system gesture area; with the keyboard up the Scaffold
        // has already resized for it and this inset is zero.
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l10n.aiChatInputHint,
                      filled: true,
                      fillColor: colors.surfaceContainerHigh,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.large,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                busy
                    ? IconButton.filledTonal(
                        tooltip: l10n.aiChatStop,
                        onPressed: onStop,
                        icon: const Icon(Icons.stop),
                      )
                    : ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => IconButton.filled(
                          tooltip: l10n.aiChatSend,
                          onPressed: controller.text.trim().isEmpty
                              ? null
                              : onSend,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.aiChatDisclaimer,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
