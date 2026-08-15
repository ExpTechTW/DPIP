/// The LoRa mesh (Meshtastic) page — a chat surface over the attached radio.
///
/// Laid out message-first, like any messaging screen: the log fills the page,
/// the composer is pinned to the bottom, and everything else (radio picker,
/// node list) opens in a sheet from the app bar. State lives in
/// [MeshChatController] in the provider tree, so leaving the page neither stops
/// reception nor drops the log.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/meshtastic/domain/dpip_mesh.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/platform/screen_wake.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:dpip/features/meshtastic/presentation/widgets/mesh_utilization_chart.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MeshtasticPage extends StatefulWidget {
  const MeshtasticPage({super.key});

  @override
  State<MeshtasticPage> createState() => _MeshtasticPageState();
}

class _MeshtasticPageState extends State<MeshtasticPage> {
  /// Which channel is being read and written, once the user has picked one.
  ///
  /// Deliberately **not** persisted and not remembered across visits: DPIP is
  /// the channel this app exists for, so every entry starts there and a
  /// detour to another channel lasts only as long as the visit.
  int? _channel;

  /// Held rather than looked up in [dispose]: by then the element is
  /// deactivated and reaching for an ancestor throws.
  MeshAlerts? _alerts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alerts = context.read<MeshAlerts>();
  }

  @override
  void dispose() {
    // Nothing on screen any more, so every channel is worth announcing again.
    _alerts?.setVisibleChannel(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MeshChatController>();
    final link = context.watch<MeshLink>();
    final service = context.read<MeshtasticService>();
    final status = link.status;

    // Channels come from two places, because either can be missing: the radio
    // knows the table but only while connected, and the stored log knows which
    // channels actually carry history. Their union is what the user can pick
    // from — so a disconnected app still offers every conversation it holds
    // instead of collapsing them into one list.
    final dpipIndex = link.lastKnownDpipChannel;
    final channels = _channelOptions(
      remembered: controller.channelNames,
      fromRadio: service.channels,
      fromLog: controller.messageCountsByChannel.keys,
    );
    // Falls back through: the user's pick → the DPIP channel → the first
    // option. Re-derived on every build, so a channel that disappears (a
    // different radio, a rewritten table) can't leave the page pointing at a
    // slot that no longer exists.
    final int selected;
    if (channels.any((c) => c.index == _channel)) {
      selected = _channel!;
    } else if (channels.any((c) => c.index == dpipIndex)) {
      selected = dpipIndex!;
    } else {
      selected = channels.isEmpty ? 0 : channels.first.index;
    }

    // A message arriving in the conversation the user is reading is not news;
    // anything else still is.
    context.read<MeshAlerts>().setVisibleChannel(selected);

    // The screen stays awake for as long as this page is up: a conversation you
    // are watching for a reply is exactly the case where the display timing out
    // costs you the thing you were waiting for. Released on dispose.
    return ScreenWakeScope(
      child: Scaffold(
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
            _OverflowMenu(
              controller: controller,
              link: link,
              alerts: context.watch<MeshAlerts>(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _ConnectionBanner(link: link),
              _RadioStrip(link: link),
              if (channels.length > 1)
                _ChannelPicker(
                  channels: channels,
                  selected: selected,
                  dpipIndex: dpipIndex,
                  counts: controller.messageCountsByChannel,
                  radio: service.radioInfo,
                  onSelected: (index) => setState(() => _channel = index),
                ),
              Expanded(
                child: _MessageLog(controller: controller, channel: selected),
              ),
              _Composer(controller: controller, channel: selected),
            ],
          ),
        ),
      ),
    );
  }

  /// Every channel worth offering, index-ordered: the radio's enabled slots,
  /// plus any channel the stored log holds messages for.
  ///
  /// A channel the radio has not reported takes the name it was last seen
  /// with ([remembered]); only a channel that has never been named falls back
  /// to its slot number. The live table still wins where it exists — a channel
  /// renamed on the radio must not keep showing its old name.
  List<MeshChannel> _channelOptions({
    required Map<int, String> remembered,
    required List<MeshChannel> fromRadio,
    required Iterable<int> fromLog,
  }) {
    final byIndex = <int, MeshChannel>{
      for (final channel in fromRadio)
        if (channel.enabled)
          channel.index: channel.name.isNotEmpty
              ? channel
              // Connected, but this slot has no name of its own: the remembered
              // one still beats a slot number.
              : MeshChannel(
                  index: channel.index,
                  name: remembered[channel.index] ?? '',
                  psk: channel.psk,
                  enabled: channel.enabled,
                ),
    };
    for (final index in fromLog) {
      byIndex.putIfAbsent(
        index,
        () => MeshChannel(
          index: index,
          name: remembered[index] ?? '',
          psk: const [],
          enabled: true,
        ),
      );
    }
    return byIndex.values.toList()..sort((a, b) => a.index.compareTo(b.index));
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
  const _OverflowMenu({
    required this.controller,
    required this.link,
    required this.alerts,
  });

  final MeshChatController controller;
  final MeshLink link;
  final MeshAlerts alerts;

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
        CheckedPopupMenuItem(
          checked: alerts.messagesEnabled,
          value: () => unawaited(
            alerts.setMessagesEnabled(enabled: !alerts.messagesEnabled),
          ),
          child: Text(l10n.meshtasticNotifyMessages),
        ),
        CheckedPopupMenuItem(
          checked: alerts.nodesEnabled,
          value: () =>
              unawaited(alerts.setNodesEnabled(enabled: !alerts.nodesEnabled)),
          child: Text(l10n.meshtasticNotifyNodes),
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
    _syncTicker();
  }

  @override
  void didUpdateWidget(_RadioStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  /// Runs the 1 Hz tick **only while there is a link**.
  ///
  /// The "last packet Ns ago" readout has to age on its own — without a tick it
  /// would freeze at whatever it said when the last packet arrived, which is
  /// exactly the reassurance-without-evidence this strip exists to avoid. But
  /// the strip renders nothing when disconnected, so ticking then would rebuild
  /// a hidden widget once a second forever (and never let a widget test settle).
  void _syncTicker() {
    final needed = widget.link.isConnected;
    if (needed == (_ticker != null)) return;
    if (needed) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
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
        : AppTime.utc.toLocal().difference(widget.lastRx!);
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
  // The same calibrated clock the stores stamped the sample with — see the
  // node sheet's _relative for why the wall clock is the wrong baseline here.
  return '${_durationLabel(AppTime.utc.toLocal().difference(at))} ago';
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

/// Which channel is being read and written, as a dropdown.
///
/// A dropdown rather than a row of tabs because the channels are a list the
/// user picks *one* of, and most radios carry several: tabs would either wrap
/// or scroll sideways, hiding the very choice they exist to present. It also
/// keeps a permanent, readable answer to "which channel am I in" on screen.
class _ChannelPicker extends StatelessWidget {
  const _ChannelPicker({
    required this.channels,
    required this.selected,
    required this.dpipIndex,
    required this.counts,
    required this.radio,
    required this.onSelected,
  });

  final List<MeshChannel> channels;
  final int selected;

  /// Which slot DPIP occupies, matched by index rather than by name: a
  /// channel restored from the log has no name, and a radio is free to carry
  /// DPIP under any index.
  final int? dpipIndex;
  final Map<int, int> counts;
  final MeshRadioInfo? radio;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // DPIP first: it is the channel this app is responsible for, the others
    // are the user's own and are simply passed through.
    final ordered = [...channels]
      ..sort((a, b) {
        final aDpip = a.index == dpipIndex;
        final bDpip = b.index == dpipIndex;
        if (aDpip != bDpip) return aDpip ? -1 : 1;
        return a.index.compareTo(b.index);
      });
    final current = ordered.firstWhere(
      (c) => c.index == selected,
      orElse: () => ordered.first,
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: PopupMenuButton<int>(
          initialValue: selected,
          onSelected: onSelected,
          borderRadius: AppRadius.medium,
          itemBuilder: (_) => [
            for (final channel in ordered)
              CheckedPopupMenuItem(
                value: channel.index,
                checked: channel.index == selected,
                child: Row(
                  children: [
                    if (channel.index == dpipIndex) ...[
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(_channelLabel(channel, radio)),
                    const SizedBox(width: AppSpacing.sm),
                    if ((counts[channel.index] ?? 0) > 0)
                      Text(
                        // l10n-ignore: message count
                        '${counts[channel.index]}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  current.index == dpipIndex
                      ? Icons.shield_outlined
                      : Icons.tag,
                  size: 18,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _channelLabel(current, radio),
                  style: theme.textTheme.titleSmall,
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What to call a channel: its name, or for an unnamed primary the modem
/// preset the firmware names it after, or the slot number.
// l10n-ignore: channel index fallback
String _channelLabel(MeshChannel channel, MeshRadioInfo? radio) {
  if (channel.name.isNotEmpty) return channel.name;
  final preset = radio?.modemPreset;
  if (channel.index == 0 && preset != null && preset.isNotEmpty) return preset;
  return 'CH${channel.index}';
}

/// The message log — newest at the bottom, grouped by day.
class _MessageLog extends StatelessWidget {
  const _MessageLog({required this.controller, required this.channel});

  final MeshChatController controller;

  /// Which channel to show. Always filtered, connected or not — channels are
  /// separate conversations, and interleaving them is wrong however little
  /// else is known about the radio.
  final int channel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final messages = [
      for (final message in controller.messages)
        if (message.channel == channel) message,
    ];
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
                    Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(message.timestamp),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
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
  const _Composer({required this.controller, required this.channel});

  final MeshChatController controller;

  /// The channel a message goes out on — whatever tab is open.
  final int channel;

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
    final failure = await widget.controller.send(text, channel: widget.channel);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _text,
                    focusNode: _focus,
                    enabled: enabled,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    // Byte-based, not character-based: the frame budget is in
                    // UTF-8 bytes, and `maxLength` counts characters — it
                    // would promise a CJK writer three times the room there is.
                    inputFormatters: composerInputFormatters,
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
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _text,
                    builder: (context, value, _) => _QuotaBar(text: value.text),
                  ),
                ],
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

/// What the composer feeds its `TextField`. Public so the cap can be tested
/// against a real field rather than by reaching into a private class.
const List<TextInputFormatter> composerInputFormatters = [
  _ByteLimitFormatter(MeshPorts.maxTextBytes),
];

/// Caps the field at [maxBytes] **UTF-8 bytes**.
///
/// A mesh frame's budget is bytes, and the alphabet decides the exchange rate:
/// one Latin letter costs 1, one Chinese character costs 3. Flutter's
/// `maxLength` counts characters, so it would let a Chinese message grow to
/// roughly three times what can actually be transmitted, and the send would
/// then fail at the radio with a message the user can't act on.
///
/// Over-long input is truncated rather than rejected, so pasting a long text
/// keeps as much as fits instead of dropping all of it — cut on grapheme
/// clusters so an emoji or a combining mark is never split in half.
class _ByteLimitFormatter extends TextInputFormatter {
  const _ByteLimitFormatter(this.maxBytes);

  final int maxBytes;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_utf8Length(newValue.text) <= maxBytes) return newValue;
    final buffer = StringBuffer();
    var used = 0;
    for (final cluster in newValue.text.characters) {
      final cost = _utf8Length(cluster);
      if (used + cost > maxBytes) break;
      buffer.write(cluster);
      used += cost;
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

int _utf8Length(String text) => utf8.encode(text).length;

/// How much of one mesh frame the draft already occupies.
///
/// Shown as a bar rather than a number alone because the limit is in bytes:
/// "148/221" means little on its own, but a bar that is two-thirds full is
/// immediately readable.
class _QuotaBar extends StatelessWidget {
  const _QuotaBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: AppSpacing.sm);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final used = _utf8Length(text);
    final ratio = (used / MeshPorts.maxTextBytes).clamp(0.0, 1.0);
    final full = used >= MeshPorts.maxTextBytes;
    final color = full
        ? colors.error
        : ratio > 0.8
        ? colors.tertiary
        : colors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 3,
                backgroundColor: colors.surfaceContainerHighest,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // l10n-ignore: byte budget readout
          Text(
            '$used/${MeshPorts.maxTextBytes}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: full ? colors.error : colors.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
          SectionHeader(l10n.meshtasticUtilization),
          FutureBuilder<List<MeshMetricSample>>(
            future: context.read<MeshChatController>().metricsHistory(),
            builder: (context, snapshot) =>
                MeshUtilizationChart(samples: snapshot.data ?? const []),
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
    // The age matters: the radio broadcasts telemetry every few minutes, so a
    // charge figure with no timestamp reads as live when it isn't.
    (l10n.meshtasticReadingAge, _sinceLabel(radio.metricsAt)),
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
    final controller = context.watch<MeshChatController>();
    final nodes = controller.nodes;

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
                // Derived from `lastHeard`, not the flag the node was stored
                // with: a node saved as online yesterday is not online now.
                controller.isOnline(node)
                    ? Icons.circle
                    : Icons.circle_outlined,
                size: 12,
                color: controller.isOnline(node)
                    ? colors.primary
                    : colors.outline,
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
