/// The notification-settings page: a preset picker, then the per-channel push
/// filters grouped by domain.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/features/notification/domain/notify_preset.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/notification/presentation/notify_controller.dart';
import 'package:dpip/features/notification/presentation/notify_labels.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Lets the user tune each push channel's filter. Settings live server-side
/// (keyed by the device push token); every change round-trips through
/// [NotifyController] so the UI mirrors the backend. Without a token yet, or on
/// a load failure, the shared async-state views take over.
class NotifyPage extends StatelessWidget {
  const NotifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotifyController>(
      create: (context) => NotifyController(
        context.read<NotifyRepository>(),
        context.read<NotificationService>().token,
      )..load(),
      child: const _NotifyView(),
    );
  }
}

class _NotifyView extends StatelessWidget {
  const _NotifyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<NotifyController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifyTitle),
        actions: [
          // Outside the status switch below on purpose. The settings on this
          // page need a push token; hearing whether this phone rings at all
          // does not — and a device with no token is precisely the one whose
          // owner wants to check.
          IconButton(
            tooltip: l10n.notifyTestTitle,
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => context.pushNamed(AppRoutes.notifyTest),
          ),
        ],
      ),
      body: switch (controller.status) {
        NotifyLoadStatus.noToken => EmptyView(
          icon: Icons.notifications_off_outlined,
          message: l10n.notifyUnavailable,
        ),
        NotifyLoadStatus.loading => const LoadingView(),
        NotifyLoadStatus.error => ErrorView(
          detail: controller.failure?.message,
          onRetry: controller.load,
        ),
        NotifyLoadStatus.ready => _NotifyList(controller: controller),
      },
    );
  }
}

/// The preset picker, then the grouped list of channels, one section per
/// domain.
class _NotifyList extends StatelessWidget {
  const _NotifyList({required this.controller});

  final NotifyController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = <({String title, List<NotifyChannel> channels})>[
      (title: l10n.notifySectionEew, channels: const [NotifyChannel.eew]),
      (
        title: l10n.notifySectionEarthquake,
        channels: const [
          NotifyChannel.monitor,
          NotifyChannel.report,
          NotifyChannel.intensity,
        ],
      ),
      (
        title: l10n.notifySectionWeather,
        channels: const [
          NotifyChannel.thunderstorm,
          NotifyChannel.weatherAdvisory,
          NotifyChannel.evacuation,
        ],
      ),
      (
        title: l10n.notifySectionTsunami,
        channels: const [NotifyChannel.tsunami],
      ),
      (
        title: l10n.notifySectionOther,
        channels: const [NotifyChannel.announcement],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        SectionHeader(l10n.notifyPresetSection),
        _PresetSection(controller: controller),
        for (final section in sections) ...[
          // Between categories — the preset picker above counts as one.
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
          SectionHeader(section.title),
          for (final channel in section.channels)
            _ChannelTile(controller: controller, channel: channel),
        ],
      ],
    );
  }
}

/// The presets as one radio group: the preset the settings currently are is
/// checked — 自訂 when they are none of them — and choosing another applies it
/// through [NotifyController.applyPreset].
///
/// While one is being applied it is the checked one, with a spinner in place
/// of its icon, and the rows below fill in as the server accepts each channel;
/// if it fails part-way, the check falls back to whatever the server ended up
/// holding (usually 自訂) and the same snackbar as a failed channel save says
/// so. Choosing it again resumes.
///
/// 自訂 is a state, not an action — there is nothing to apply — so it is only
/// enabled while it is the checked one; otherwise a screen reader would offer
/// a radio button that does nothing. It is reached by changing a channel.
class _PresetSection extends StatelessWidget {
  const _PresetSection({required this.controller});

  final NotifyController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checked = controller.applying ?? controller.preset;

    return RadioGroup<NotifyPreset>(
      groupValue: checked,
      onChanged: (preset) {
        if (preset != null && preset != checked) _choose(context, preset);
      },
      child: Column(
        children: [
          for (final preset in NotifyPreset.values)
            RadioListTile<NotifyPreset>(
              value: preset,
              enabled:
                  !controller.busy &&
                  (preset != NotifyPreset.custom || checked == preset),
              controlAffinity: ListTileControlAffinity.trailing,
              secondary: controller.applying == preset
                  ? Semantics(
                      label: l10n.notifyPresetApplying,
                      child: const InlineLoading(),
                    )
                  : Icon(notifyPresetIcon(preset)),
              title: Text(notifyPresetLabel(preset, l10n)),
              subtitle: Text(notifyPresetDescription(preset, l10n)),
            ),
        ],
      ),
    );
  }

  /// Applies [preset] — after a confirmation when it would replace a
  /// hand-tuned combination, since that one cannot be brought back by tapping
  /// another preset.
  Future<void> _choose(BuildContext context, NotifyPreset preset) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (controller.preset == NotifyPreset.custom) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.notifyPresetConfirmTitle(notifyPresetLabel(preset, l10n)),
          ),
          content: Text(l10n.notifyPresetConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.notifyPresetApply),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await controller.applyPreset(preset);
    if (!ok && context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.notifySetFailed)));
    }
  }
}

/// One channel row — its title, current selection, and (while a save is in
/// flight) a spinner. Tapping opens the option sheet.
class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.controller, required this.channel});

  final NotifyController controller;
  final NotifyChannel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = controller.settings!;
    final saving = controller.saving == channel;
    // Locked during a preset too: its writes share this token's rate limit,
    // and a row changed mid-preset would be overwritten a moment later.
    final busy = controller.busy;

    return ListTile(
      leading: Icon(notifyChannelIcon(channel)),
      title: Text(notifyChannelTitle(channel, l10n)),
      subtitle: Text(notifyOptionLabel(settings.kindOf(channel), l10n)),
      trailing: saving
          ? const InlineLoading(size: 20)
          : const Icon(Icons.chevron_right),
      enabled: !busy,
      onTap: () => _edit(context),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final current = controller.settings!.optionOf(channel);

    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => _OptionSheet(channel: channel, current: current),
    );
    if (chosen == null) return;

    final ok = await controller.setChannel(channel, chosen);
    if (!ok && context.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.notifySetFailed)));
    }
  }
}

/// The bottom sheet listing a channel's options; tapping one pops its wire
/// index (mirroring the selection style used elsewhere: a leading icon +
/// title with a trailing check on the active row — see
/// `DefaultMapLayerPage`). The **only** colour in the list is that trailing
/// check — every icon stays neutral, so the selection stays the one thing
/// your eye is drawn to.
///
/// [optionsFor] is wire order (its index *is* the value sent to the server,
/// so that order can't change), broadest-first from the user's point of view
/// — "off" sits at index 0 for every channel that has it. Every hand-built
/// list in this app reads top-to-bottom as "receive the most → receive
/// nothing", so display order is wire order **reversed**; each row keeps its
/// own original index for the check mark and the popped value.
///
/// Hierarchy comes from structure, not colour: a channel that has an "off"
/// option gets a divider right above it and its row dimmed, so the list reads
/// as two tiers — degrees of "on", then a clearly separate "off" — instead of
/// options flattened together with no sense of which is more.
///
/// The title is a plain left-aligned, bold, large heading — no icon, no
/// [ListTile] shape — so it can't be mistaken for another tappable row
/// (mirrors `ReportFilterSheet`'s own sheet title). It's tinted
/// [ColorScheme.primary], the same role [SectionHeader] uses for this page's
/// own category labels, so the sheet's title reads as the same kind of
/// heading rather than a differently-styled one-off.
class _OptionSheet extends StatelessWidget {
  const _OptionSheet({required this.channel, required this.current});

  final NotifyChannel channel;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = notifyOptionsForDisplay(channel);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              notifyChannelTitle(channel, l10n),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          for (final (wireIndex, kind) in options) ...[
            if (kind == NotifyOptionKind.off)
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
            ListTile(
              iconColor: kind == NotifyOptionKind.off
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
              textColor: kind == NotifyOptionKind.off
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
              leading: Icon(notifyOptionIcon(kind)),
              title: Text(notifyOptionLabel(kind, l10n)),
              trailing: wireIndex == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, wireIndex),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
