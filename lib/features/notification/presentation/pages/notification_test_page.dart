/// The test-notification page: fire one sample of each alert channel and see
/// what it actually does on this device.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_samples.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Lets the user hear and see each alert channel on their own device.
///
/// The question this page exists to answer is "will this actually wake me at
/// three in the morning" — and nothing else in the app can answer it, because
/// every part of the chain is invisible until an alert arrives: the OS grant,
/// the channel's sound, whether the phone's silent switch applies. So each row
/// states what the channel will do *before* it is tapped, and tapping fires the
/// real thing.
///
/// It lists the **OS notification channels**, not the nine [NotifyChannel]
/// filters on the settings page in front of it. Those are two different things
/// that both get called "notification settings": the filters decide whether the
/// backend sends anything, while these decide what the phone does when it
/// arrives. Sound lives here.
///
/// Reachable even when the settings page behind it has no push token, and
/// deliberately so: a device that cannot be reached by push is exactly the
/// device whose owner wants to know whether notifications work at all.
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  /// The legacy cooldown, kept: long enough that a double-tap cannot stack two
  /// alarms, short enough not to feel broken.
  static const _cooldown = Duration(seconds: 2);

  /// Whether the OS lets this app post at all — null until checked.
  bool? _allowed;

  /// Whether iOS granted the critical-alert entitlement. Null on Android, where
  /// the permission does not exist and the channel carries the override.
  bool? _criticalAllowed;

  /// The channel currently in its cooldown, if any.
  String? _cooling;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPermissions());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPermissions() async {
    final notifications = context.read<NotificationService>();
    final allowed = await notifications.isAllowed();
    final critical = notifications.criticalApplies
        ? await notifications.criticalAllowed()
        : null;
    if (!mounted) return;
    setState(() {
      _allowed = allowed;
      _criticalAllowed = critical;
    });
  }

  Future<void> _fire(String channelKey) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifications = context.read<NotificationService>();

    setState(() => _cooling = channelKey);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_cooldown, () {
      if (mounted) setState(() => _cooling = null);
    });

    final sent = await notifications.showTest(channelKey);
    if (sent || !mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.notifyTestFailed)));
  }

  Future<void> _openSettings() async {
    await context.read<NotificationService>().openSystemSettings();
    // The grant may have changed while the app was away; re-reading on return
    // is what stops the banner from outliving the problem it describes.
    await _refreshPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allowed = _allowed;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifyTestTitle)),
      body: allowed == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                // Exactly one notice, always. Each state has one thing most
                // worth saying, and stacking a standing explanation above a
                // live problem buries the problem.
                if (!allowed)
                  _Notice(
                    icon: Icons.notifications_off_outlined,
                    text: l10n.notifyTestPermissionOff,
                    tone: _NoticeTone.problem,
                    actionLabel: l10n.permissionOpenSettings,
                    onAction: _openSettings,
                  )
                // Only once notifications work at all: naming the missing
                // critical grant while nothing can be posted in the first place
                // describes the second problem and hides the first.
                else if (_criticalAllowed == false)
                  _Notice(
                    icon: Icons.volume_off_outlined,
                    text: l10n.notifyTestCriticalDenied,
                    tone: _NoticeTone.problem,
                    actionLabel: l10n.permissionOpenSettings,
                    onAction: _openSettings,
                  )
                else
                  _Notice(
                    icon: Icons.volume_up_outlined,
                    text: l10n.notifyTestIntro,
                  ),
                for (final section in _sections(l10n)) ...[
                  SectionHeader(section.title),
                  for (final channel in section.channels)
                    _ChannelRow(
                      channel: channel,
                      enabled: allowed,
                      cooling: _cooling == channel.channelKey,
                      criticalGranted: _criticalAllowed,
                      onFire: () => _fire(channel.channelKey!),
                    ),
                ],
              ],
            ),
    );
  }

  /// The testable channels, grouped in catalogue order.
  ///
  /// Testable means "has a sample" — which is the same set as "the backend
  /// pushes it". The mesh channels the app raises itself from the LoRa link and
  /// the silent `background` service channel are left out: there is no server
  /// message to reproduce for them, and a row that fired an invented alert
  /// would be demonstrating something the user will never actually receive.
  List<({String title, List<NotificationChannel> channels})> _sections(
    AppLocalizations l10n,
  ) {
    // The settings page one screen back labels its categories with these exact
    // strings. Two different labels for one grouping would read as two
    // different groupings.
    final order = <(String, String)>[
      ('group_eew', l10n.notifySectionEew),
      ('group_eq', l10n.notifySectionEarthquake),
      ('group_info', l10n.notifySectionWeather),
      ('group_tsunami', l10n.notifySectionTsunami),
      ('group_other', l10n.notifySectionOther),
    ];

    final grouped = <String, List<NotificationChannel>>{};
    for (final channel in NotificationChannels.channels) {
      final key = channel.channelKey;
      if (key == null || NotificationSamples.of(key) == null) continue;
      final group = channel.channelGroupKey;
      if (group == null) continue;
      grouped.putIfAbsent(group, () => []).add(channel);
    }

    return [
      for (final (group, title) in order)
        if (grouped[group] case final channels?)
          (title: title, channels: channels),
    ];
  }
}

/// One channel: its name, what it will do, and a tap that does it.
///
/// The subtitle is the point of the row. The catalogue holds nine fields per
/// channel and all nine were candidates here, but only the ones that change the
/// answer earn a line: sound file, LED colour, and vibration pattern do not
/// change whether you wake up, and listing them would bury the one that does.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.enabled,
    required this.cooling,
    required this.criticalGranted,
    required this.onFire,
  });

  final NotificationChannel channel;
  final bool enabled;
  final bool cooling;

  /// iOS's critical-alert grant; null where the concept does not apply.
  final bool? criticalGranted;

  final VoidCallback onFire;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    var behaviour = NotificationChannels.behaviourOf(channel);

    // A channel that claims to override silent mode only does so on iOS if the
    // user granted the critical alert. Saying otherwise on a device that
    // refused it would be the page's single worst failure — it is the exact
    // claim someone checks this screen to confirm.
    if (behaviour == NotificationBehaviour.overrides &&
        criticalGranted == false) {
      behaviour = NotificationBehaviour.alerts;
    }

    return ListTile(
      leading: Icon(_icon(behaviour)),
      title: Text(channel.channelName ?? ''),
      subtitle: Text(_label(behaviour, l10n)),
      trailing: cooling
          ? const InlineLoading(size: 20)
          : Icon(
              Icons.play_circle_outline,
              color: enabled ? theme.colorScheme.primary : null,
            ),
      enabled: enabled && !cooling,
      onTap: onFire,
    );
  }

  /// The same "how much will this interrupt me" vocabulary the settings page's
  /// option sheet uses, so the two screens read as one idea.
  static IconData _icon(NotificationBehaviour behaviour) => switch (behaviour) {
    NotificationBehaviour.overrides => Icons.notification_important_outlined,
    NotificationBehaviour.alerts => Icons.notifications_active_outlined,
    NotificationBehaviour.sounds => Icons.notifications_outlined,
    NotificationBehaviour.silent => Icons.notifications_off_outlined,
  };

  static String _label(
    NotificationBehaviour behaviour,
    AppLocalizations l10n,
  ) => switch (behaviour) {
    NotificationBehaviour.overrides => l10n.notifyTestBehaviourOverrides,
    NotificationBehaviour.alerts => l10n.notifyTestBehaviourAlerts,
    NotificationBehaviour.sounds => l10n.notifyTestBehaviourSounds,
    NotificationBehaviour.silent => l10n.notifyTestBehaviourSilent,
  };
}

enum _NoticeTone { info, problem }

/// A calm inline note above the list.
///
/// Not a `SnackBar` and not a dialog: both of those interrupt, and everything
/// this page has to say is something you want to read *before* choosing a row,
/// not something that arrives after you have already tapped one.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    this.tone = _NoticeTone.info,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final _NoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = switch (tone) {
      _NoticeTone.info => (
        theme.colorScheme.surfaceContainerHigh,
        theme.colorScheme.onSurfaceVariant,
      ),
      _NoticeTone.problem => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.medium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                          // Visually tight, but the 48dp minimum tap target
                          // that comes with the default `tapTargetSize` stays.
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
