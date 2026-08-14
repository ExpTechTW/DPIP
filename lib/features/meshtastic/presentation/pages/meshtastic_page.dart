/// The LoRa mesh (Meshtastic) page — a chat surface over the attached radio.
///
/// Laid out message-first, like any messaging screen: the log fills the page,
/// the composer is pinned to the bottom, and everything else (radio picker,
/// node list) opens in a sheet from the app bar. State lives in
/// [MeshChatController] in the provider tree, so leaving the page neither stops
/// reception nor drops the log.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MeshtasticPage extends StatelessWidget {
  const MeshtasticPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MeshChatController>();
    final link = context.watch<MeshLink>();
    final status = link.status;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.meshtasticTitle),
            Text(
              _statusLabel(l10n, status),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.meshtasticNodes,
            onPressed: () => _showNodes(context),
            icon: Badge(
              isLabelVisible: controller.nodes.isNotEmpty,
              label: Text('${controller.nodes.length}'),
              child: const Icon(Icons.hub_outlined),
            ),
          ),
          _OverflowMenu(controller: controller, link: link),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ConnectionBanner(link: link),
            _RadioStrip(link: link),
            Expanded(child: _MessageLog(controller: controller)),
            _Composer(controller: controller),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, MeshConnectionStatus status) {
    final label = switch (status.state) {
      MeshConnectionState.disconnected => l10n.meshtasticStateDisconnected,
      MeshConnectionState.connecting => l10n.meshtasticStateConnecting,
      MeshConnectionState.configuring => l10n.meshtasticStateConfiguring,
      MeshConnectionState.connected => l10n.meshtasticStateConnected,
      MeshConnectionState.error => l10n.meshtasticStateError,
    };
    final name = status.deviceName;
    return name == null || name.isEmpty ? label : '$label · $name';
  }
}

/// Opens the radio picker, scanning while it is on screen.
Future<void> _showDevices(BuildContext context) async {
  final controller = context.read<MeshChatController>();
  unawaited(controller.startScan());
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _DeviceSheet(),
  );
  await controller.stopScan();
}

Future<void> _showNodes(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _NodeSheet(),
);

Future<void> _showRadio(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _RadioSheet(),
);

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// App-bar overflow: connect/disconnect and log housekeeping.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.controller, required this.link});

  final MeshChatController controller;
  final MeshLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<VoidCallback>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => action(),
      // The item builder's context belongs to the menu route, which is already
      // gone by the time `onSelected` runs — every action closes over this
      // widget's context instead.
      itemBuilder: (_) => [
        PopupMenuItem(
          value: () => unawaited(_showDevices(context)),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bluetooth_searching_outlined),
            title: Text(l10n.meshtasticSelectDevice),
          ),
        ),
        PopupMenuItem(
          enabled: link.savedRadioId != null,
          value: () async {
            final failure = await controller.disconnect();
            if (failure != null && context.mounted) _toast(context, failure);
          },
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bluetooth_disabled_outlined),
            title: Text(l10n.meshtasticDisconnect),
          ),
        ),
        PopupMenuItem(
          enabled: controller.messages.isNotEmpty,
          value: controller.clearMessages,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_sweep_outlined),
            title: Text(l10n.meshtasticClearMessages),
          ),
        ),
      ],
    );
  }
}

/// A slim strip above the log carrying whatever the connection needs from the
/// user right now. Nothing is shown once the radio is connected — the app bar
/// already names it.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.link});

  final MeshLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final status = link.status;
    if (status.state == MeshConnectionState.connected) {
      return const SizedBox.shrink();
    }

    // A pending reconnect is "busy" too: the link is coming back on its own,
    // so the user is told to wait rather than offered a scan they don't need.
    final busy =
        status.state == MeshConnectionState.connecting ||
        status.state == MeshConnectionState.configuring ||
        link.reconnecting;
    final failed = status.state == MeshConnectionState.error;
    final background = failed
        ? colors.errorContainer
        : busy
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final foreground = failed
        ? colors.onErrorContainer
        : busy
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    final message = failed
        ? (status.errorMessage ?? l10n.meshtasticStateError)
        : busy
        ? switch (status.state) {
            MeshConnectionState.configuring => l10n.meshtasticStateConfiguring,
            MeshConnectionState.connecting => l10n.meshtasticStateConnecting,
            _ => l10n.meshtasticReconnecting,
          }
        : l10n.meshtasticNotConnected;

    return Material(
      color: background,
      child: Column(
        children: [
          if (busy) LinearProgressIndicator(color: colors.primary),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  failed
                      ? Icons.error_outline
                      : busy
                      ? Icons.bluetooth_searching_outlined
                      : Icons.bluetooth_disabled_outlined,
                  size: 18,
                  color: foreground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: foreground),
                  ),
                ),
                if (!busy)
                  TextButton(
                    onPressed: () => unawaited(_showDevices(context)),
                    child: Text(l10n.meshtasticScan),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What DPIP itself needs from the attached radio: the private channel its
/// The strip under the app bar: proof the link is alive, plus what DPIP needs
/// from the radio. Tapping it opens the full radio panel.
///
/// A working mesh link is mostly silent — between events nothing on screen
/// separates "connected and listening" from "died ten minutes ago". So the top
/// row is deliberately *live*: a pulse on every received packet, running
/// counters, and how long ago the last packet arrived.
class _RadioStrip extends StatefulWidget {
  const _RadioStrip({required this.link});

  final MeshLink link;

  @override
  State<_RadioStrip> createState() => _RadioStripState();
}

class _RadioStripState extends State<_RadioStrip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // The "last packet Ns ago" readout has to age on its own; without a tick
    // it would freeze at whatever it said when the last packet arrived, which
    // is exactly the reassurance-without-evidence this strip exists to avoid.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    if (!link.isConnected) return const SizedBox.shrink();
    final service = context.read<MeshtasticService>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      child: InkWell(
        onTap: () => _showRadio(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<MeshTraffic>(
                initialData: service.traffic,
                stream: service.trafficStream,
                builder: (context, snapshot) => _VitalsRow(
                  traffic: snapshot.data ?? const MeshTraffic(),
                  radio: service.radioInfo,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _DpipRow(link: link),
            ],
          ),
        ),
      ),
    );
  }
}

/// Heartbeat, packet counters and battery — the always-on vitals.
class _VitalsRow extends StatelessWidget {
  const _VitalsRow({required this.traffic, required this.radio});

  final MeshTraffic traffic;
  final MeshRadioInfo? radio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final battery = radio?.batteryPercent;

    return Row(
      children: [
        _Heartbeat(lastRx: traffic.lastRx),
        const SizedBox(width: AppSpacing.sm),
        // l10n-ignore: counters and units, not prose
        Text('↓ ${traffic.rxPackets}', style: style),
        const SizedBox(width: AppSpacing.md),
        // l10n-ignore: counters and units, not prose
        Text('↑ ${traffic.txPackets}', style: style),
        const SizedBox(width: AppSpacing.md),
        Text(_sinceLabel(traffic.lastRx), style: style),
        const Spacer(),
        if (battery != null) ...[
          Icon(
            radio!.isPluggedIn ? Icons.power_outlined : _batteryIcon(battery),
            size: 16,
            color: !radio!.isPluggedIn && battery <= 20
                ? colors.error
                : colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          // l10n-ignore: percentage readout, not prose
          Text(radio!.isPluggedIn ? 'DC' : '$battery%', style: style),
          const SizedBox(width: AppSpacing.sm),
        ],
        Icon(Icons.chevron_right, size: 18, color: colors.onSurfaceVariant),
      ],
    );
  }

  IconData _batteryIcon(int percent) => switch (percent) {
    >= 80 => Icons.battery_full_outlined,
    >= 50 => Icons.battery_5_bar_outlined,
    >= 20 => Icons.battery_3_bar_outlined,
    _ => Icons.battery_1_bar_outlined,
  };
}

/// A dot that pulses once per received packet and fades as the link goes quiet.
///
/// The colour is the honest part: it is driven by how long ago the last packet
/// arrived, so a link that stopped delivering goes grey by itself instead of
/// sitting there looking connected.
class _Heartbeat extends StatefulWidget {
  const _Heartbeat({required this.lastRx});

  final DateTime? lastRx;

  @override
  State<_Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<_Heartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  @override
  void didUpdateWidget(_Heartbeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastRx != oldWidget.lastRx) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final age = widget.lastRx == null
        ? null
        : DateTime.now().difference(widget.lastRx!);
    final color = switch (age) {
      null => colors.outline,
      final a when a < const Duration(minutes: 2) => colors.primary,
      final a when a < const Duration(minutes: 15) => colors.tertiary,
      _ => colors.outline,
    };
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        // One outward ring per packet, over a dot that stays put.
        final t = _pulse.value;
        return SizedBox.square(
          dimension: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_pulse.isAnimating)
                Container(
                  width: 6 + 10 * t,
                  height: 6 + 10 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: (1 - t) * 0.4),
                  ),
                ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// How long ago something happened, compact and unit-suffixed.
// l10n-ignore: numeric age readout used in diagnostics rows
String _sinceLabel(DateTime? at) {
  if (at == null) return '—';
  return '${_durationLabel(DateTime.now().difference(at))} ago';
}

// l10n-ignore: numeric duration readout used in diagnostics rows
String _durationLabel(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}s';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inDays}d ${d.inHours % 24}h';
}

/// What DPIP needs from the radio: the private channel its disaster payloads
/// travel on, and the LoRa region that decides who can hear them.
class _DpipRow extends StatelessWidget {
  const _DpipRow({required this.link});

  final MeshLink link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (IconData icon, String label, bool warn) = switch (link.provision) {
      MeshProvisionState.working => (
        Icons.hourglass_empty,
        l10n.meshtasticChannelWorking,
        false,
      ),
      MeshProvisionState.ready => (
        Icons.verified_outlined,
        // l10n-ignore: channel name and index, not prose
        '${l10n.meshtasticChannelReady} · ${DpipMeshChannel.name} '
            'CH${link.dpipChannel}',
        false,
      ),
      MeshProvisionState.noFreeSlot => (
        Icons.warning_amber_outlined,
        l10n.meshtasticChannelNoSlot,
        true,
      ),
      MeshProvisionState.conflict => (
        Icons.warning_amber_outlined,
        link.provisionError ?? l10n.meshtasticChannelFailed,
        true,
      ),
      MeshProvisionState.failed => (
        Icons.error_outline,
        link.provisionError ?? l10n.meshtasticChannelFailed,
        true,
      ),
      MeshProvisionState.idle => (
        Icons.hourglass_empty,
        l10n.meshtasticChannelWorking,
        false,
      ),
    };
    final mismatch = link.regionState == MeshRegionState.mismatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: warn ? colors.error : colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: warn ? colors.error : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (mismatch)
          Row(
            children: [
              Icon(Icons.public_outlined, size: 16, color: colors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.meshtasticRegionMismatch(link.region ?? ''),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(_confirmRegion(context, link)),
                child: Text(l10n.meshtasticRegionSwitch),
              ),
            ],
          ),
      ],
    );
  }

  /// The region change reboots the radio and moves *all* of its traffic, so it
  /// never happens without a yes.
  Future<void> _confirmRegion(BuildContext context, MeshLink link) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.public_outlined),
        title: Text(l10n.meshtasticRegionSwitch),
        content: Text(l10n.meshtasticRegionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.meshtasticRegionSwitch),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await link.applyRegion();
    if (failure != null && context.mounted) _toast(context, failure);
  }
}

/// The message log — newest at the bottom, grouped by day.
class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.controller});

  final MeshChatController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = controller.messages;
    if (messages.isEmpty) {
      return EmptyView(
        icon: controller.isConnected
            ? Icons.forum_outlined
            : Icons.bluetooth_disabled_outlined,
        message: controller.isConnected
            ? l10n.meshtasticNoMessages
            : l10n.meshtasticNotConnected,
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        // Reversed: the next index is the *older* message, so the day label
        // belongs to the oldest message of each day.
        final older = index + 1 < messages.length ? messages[index + 1] : null;
        final startsDay =
            older == null || !_sameDay(older.timestamp, message.timestamp);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (startsDay) _DayLabel(date: message.timestamp),
            _Bubble(message: message, controller: controller),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppRadius.small,
          ),
          child: Text(
            MaterialLocalizations.of(context).formatMediumDate(date),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// One message. Received messages sit left with their sender; sent ones sit
/// right in the primary tint.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.controller});

  final MeshChatMessage message;
  final MeshChatController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final outgoing = message.outgoing;
    final empty = message.text.isEmpty;
    final background = outgoing
        ? colors.primaryContainer
        : colors.surfaceContainerHigh;
    final foreground = outgoing ? colors.onPrimaryContainer : colors.onSurface;
    final muted = foreground.withValues(alpha: 0.7);

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Material(
            color: background,
            borderRadius: AppRadius.medium,
            child: InkWell(
              borderRadius: AppRadius.medium,
              onLongPress: empty
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: message.text),
                      );
                      if (context.mounted) {
                        _toast(context, l10n.meshtasticCopied);
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!outgoing)
                      Text(
                        controller.senderLabel(message.from),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      empty ? l10n.meshtasticEmptyMessage : message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: empty ? muted : foreground,
                        fontStyle: empty ? FontStyle.italic : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.channel != 0) ...[
                          // l10n-ignore: channel index, not prose
                          Text(
                            'CH${message.channel}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay.fromDateTime(message.timestamp),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The pinned composer. Disabled until the radio is connected *and* configured
/// — sending earlier is rejected by the transport anyway.
class _Composer extends StatefulWidget {
  const _Composer({required this.controller});

  final MeshChatController controller;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final failure = await widget.controller.send(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure != null) {
      _toast(context, failure);
      return;
    }
    _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final enabled = widget.controller.isConnected && !_sending;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => unawaited(_send()),
                decoration: InputDecoration(
                  hintText: l10n.meshtasticSendHint,
                  filled: true,
                  isDense: true,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.large,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Rebuilds with the field so the button lights up only once
            // there's something to send.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _text,
              builder: (context, value, _) => IconButton.filled(
                tooltip: l10n.meshtasticSend,
                onPressed: enabled && value.text.trim().isNotEmpty
                    ? () => unawaited(_send())
                    : null,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio picker — scans while open, connects on tap.
class _DeviceSheet extends StatelessWidget {
  const _DeviceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<MeshChatController>();
    final devices = controller.devices;
    final error = controller.scanError;

    return _SheetFrame(
      title: l10n.meshtasticSelectDevice,
      trailing: IconButton(
        tooltip: l10n.meshtasticScan,
        onPressed: controller.scanning
            ? null
            : () => unawaited(controller.startScan()),
        icon: const Icon(Icons.refresh),
      ),
      children: [
        if (controller.scanning) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          )
        else if (devices.isEmpty)
          EmptyView(
            icon: Icons.bluetooth_searching_outlined,
            message: controller.scanning
                ? l10n.meshtasticScanning
                : l10n.meshtasticNoDevices,
          )
        else
          for (final device in devices)
            ListTile(
              leading: const Icon(Icons.router_outlined),
              title: Text(device.name.isEmpty ? device.id : device.name),
              subtitle: Text(
                device.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: controller.connectingId == device.id
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: controller.connectingId != null
                  ? null
                  : () => unawaited(_pick(context, controller, device)),
            ),
      ],
    );
  }
}

/// Connects to [device], asking first when another app already holds it.
///
/// Neither iOS nor Android can evict another app's GATT link — the radio would
/// then be answering two clients that consume each other's packets, so the
/// honest move is to say so and let the user decide.
Future<void> _pick(
  BuildContext context,
  MeshChatController controller,
  MeshDevice device,
) async {
  final l10n = AppLocalizations.of(context);
  final navigator = Navigator.of(context);
  // Stop scanning before connecting. The picker's scan would otherwise run for
  // the rest of its timeout *through* the connect, and issuing a GATT connect
  // while a scan is active is a classic source of Android's status-133
  // failures.
  await controller.stopScan();
  var failure = await controller.connect(device);

  if (failure == MeshLink.busySentinel) {
    if (!context.mounted) return;
    final force = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.phonelink_off_outlined),
        title: Text(l10n.meshtasticBusyTitle),
        content: Text(l10n.meshtasticBusyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.meshtasticConnectAnyway),
          ),
        ],
      ),
    );
    if (force != true) return;
    failure = await controller.connect(device, force: true);
  }

  if (!context.mounted) return;
  if (failure != null) {
    _toast(context, failure);
    return;
  }
  navigator.pop();
}

/// Everything the attached radio knows about itself, in one place: identity,
/// firmware, power, radio settings, channel table and session traffic.
///
/// Diagnostics, so the values are shown raw — a wrong-looking number here is
/// the point.
class _RadioSheet extends StatelessWidget {
  const _RadioSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = context.read<MeshtasticService>();
    final link = context.watch<MeshLink>();
    final radio = service.radioInfo;

    return _SheetFrame(
      title: l10n.meshtasticRadio,
      children: [
        if (radio == null)
          EmptyView(
            icon: Icons.settings_input_antenna_outlined,
            message: l10n.meshtasticNotConnected,
          )
        else ...[
          _InfoSection(
            title: l10n.meshtasticDevice,
            rows: _device(l10n, radio),
          ),
          _InfoSection(title: l10n.meshtasticPower, rows: _power(l10n, radio)),
          _InfoSection(
            title: l10n.meshtasticRadioSettings,
            rows: _lora(l10n, radio, link),
          ),
          StreamBuilder<MeshTraffic>(
            initialData: service.traffic,
            stream: service.trafficStream,
            builder: (context, snapshot) => _InfoSection(
              title: l10n.meshtasticTraffic,
              rows: _traffic(l10n, snapshot.data ?? const MeshTraffic()),
            ),
          ),
          _InfoSection(
            title: l10n.meshtasticChannels,
            rows: [
              for (final channel in service.channels)
                if (channel.enabled)
                  (
                    // l10n-ignore: channel index label
                    'CH${channel.index}',
                    channel.name.isEmpty
                        // l10n-ignore: firmware's own name for an unnamed channel
                        ? '(default)'
                        : channel.name,
                  ),
            ],
          ),
        ],
      ],
    );
  }

  List<(String, String)> _device(
    AppLocalizations l10n,
    MeshRadioInfo radio,
  ) => [
    (l10n.meshtasticName, radio.longName ?? '—'),
    // l10n-ignore: node id in the hex form the mesh uses
    (l10n.meshtasticNodeId, '!${radio.nodeNum.toRadixString(16)}'),
    if (radio.shortName != null) (l10n.meshtasticShortName, radio.shortName!),
    (l10n.meshtasticHardware, radio.hardware ?? '—'),
    (l10n.meshtasticFirmware, radio.firmware ?? '—'),
    (l10n.meshtasticRole, radio.role ?? '—'),
  ];

  List<(String, String)> _power(AppLocalizations l10n, MeshRadioInfo radio) => [
    (
      l10n.meshtasticBattery,
      radio.isPluggedIn
          ? l10n.meshtasticExternalPower
          : radio.batteryPercent == null
          ? '—'
          // l10n-ignore: percentage readout
          : '${radio.batteryPercent}%',
    ),
    if (radio.voltage != null)
      // l10n-ignore: volts
      (l10n.meshtasticVoltage, '${radio.voltage!.toStringAsFixed(2)} V'),
    if (radio.uptime != null)
      (l10n.meshtasticUptime, _durationLabel(radio.uptime!)),
  ];

  List<(String, String)> _lora(
    AppLocalizations l10n,
    MeshRadioInfo radio,
    MeshLink link,
  ) => [
    (l10n.meshtasticRegionLabel, radio.region ?? '—'),
    (l10n.meshtasticPreset, radio.modemPreset ?? '—'),
    if (radio.hopLimit != null) (l10n.meshtasticHopLimit, '${radio.hopLimit}'),
    if (radio.txPower != null)
      // l10n-ignore: dBm
      (l10n.meshtasticTxPower, '${radio.txPower} dBm'),
    if (radio.channelUtilization != null)
      (
        l10n.meshtasticChannelUse,
        // l10n-ignore: percentage readout
        '${radio.channelUtilization!.toStringAsFixed(1)}%',
      ),
    if (radio.airUtilTx != null)
      // l10n-ignore: percentage readout
      (l10n.meshtasticAirtime, '${radio.airUtilTx!.toStringAsFixed(1)}%'),
    (
      l10n.meshtasticDpipChannel,
      link.dpipChannel == null
          ? '—'
          // l10n-ignore: channel index label
          : '${DpipMeshChannel.name} CH${link.dpipChannel}',
    ),
  ];

  List<(String, String)> _traffic(AppLocalizations l10n, MeshTraffic traffic) =>
      [
        (
          l10n.meshtasticReceived,
          // l10n-ignore: packet/byte counters
          '${traffic.rxPackets} · ${_bytesLabel(traffic.rxBytes)}',
        ),
        (
          l10n.meshtasticSent,
          // l10n-ignore: packet/byte counters
          '${traffic.txPackets} · ${_bytesLabel(traffic.txBytes)}',
        ),
        if (traffic.rxUndecoded > 0)
          (l10n.meshtasticUndecoded, '${traffic.rxUndecoded}'),
        (l10n.meshtasticLastReceived, _sinceLabel(traffic.lastRx)),
        (l10n.meshtasticLastSent, _sinceLabel(traffic.lastTx)),
        for (final entry in traffic.rxByPort.entries)
          (_portLabel(entry.key), '${entry.value}'),
      ];
}

/// A titled block of label/value rows.
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Meshtastic app ports, named where the name helps and numbered otherwise.
// l10n-ignore: protocol port names
String _portLabel(int portnum) => switch (portnum) {
  1 => 'Text',
  3 => 'Position',
  4 => 'Node info',
  5 => 'Routing',
  6 => 'Admin',
  8 => 'Waypoint',
  10 => 'Detection',
  67 => 'Telemetry',
  70 => 'Traceroute',
  71 => 'Neighbour info',
  MeshPorts.private => 'DPIP',
  _ => 'Port $portnum',
};

// l10n-ignore: byte counter
String _bytesLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} kB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Everything the radio has heard, online first.
class _NodeSheet extends StatelessWidget {
  const _NodeSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final nodes = context.watch<MeshChatController>().nodes;

    return _SheetFrame(
      title: l10n.meshtasticNodes,
      trailing: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Text(
          '${nodes.length}',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
      children: [
        if (nodes.isEmpty)
          EmptyView(icon: Icons.hub_outlined, message: l10n.meshtasticNoNodes)
        else
          for (final node in nodes)
            ListTile(
              leading: Icon(
                node.isOnline ? Icons.circle : Icons.circle_outlined,
                size: 12,
                color: node.isOnline ? colors.primary : colors.outline,
              ),
              title: Text(node.displayName),
              subtitle: Text(_nodeDetail(node)),
            ),
      ],
    );
  }

  // l10n-ignore: node id / battery / SNR readouts, not prose
  String _nodeDetail(MeshNode node) => [
    '0x${node.num.toRadixString(16)}',
    if (node.batteryLevel != null) '${node.batteryLevel}%',
    if (node.snr != 0) 'SNR ${node.snr.toStringAsFixed(1)}',
  ].join(' · ');
}

/// Shared chrome for the two sheets: a title row over a scrollable body that
/// never grows past two thirds of the screen.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Flexible(child: ListView(shrinkWrap: true, children: children)),
          ],
        ),
      ),
    );
  }
}
