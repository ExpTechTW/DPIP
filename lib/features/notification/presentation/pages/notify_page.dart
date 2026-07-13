/// The notification-settings page: per-channel push filters, grouped by domain.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:dpip/features/notification/presentation/notify_controller.dart';
import 'package:dpip/features/notification/presentation/notify_labels.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(title: Text(l10n.notifyTitle)),
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

/// The grouped list of channels, one section per domain.
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
        for (final section in sections) ...[
          SectionHeader(section.title),
          for (final channel in section.channels)
            _ChannelTile(controller: controller, channel: channel),
        ],
      ],
    );
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
    final busy = controller.saving != null;

    return ListTile(
      leading: Icon(notifyChannelIcon(channel)),
      title: Text(notifyChannelTitle(channel, l10n)),
      subtitle: Text(notifyOptionLabel(settings.kindOf(channel), l10n)),
      trailing: saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
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
/// index (mirroring the selection style used elsewhere: a leading title with a
/// trailing check on the active row).
class _OptionSheet extends StatelessWidget {
  const _OptionSheet({required this.channel, required this.current});

  final NotifyChannel channel;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = optionsFor(channel);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(notifyChannelIcon(channel)),
                const SizedBox(width: AppSpacing.md),
                Text(
                  notifyChannelTitle(channel, l10n),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          for (final (index, kind) in options.indexed)
            ListTile(
              title: Text(notifyOptionLabel(kind, l10n)),
              trailing: index == current
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, index),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
