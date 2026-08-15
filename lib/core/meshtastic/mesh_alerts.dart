/// Raises **local** notifications for mesh traffic — no server, no push.
///
/// Everything here is posted by the app itself from the BLE link, which is the
/// point: the mesh exists for when there is no internet, so an alert that
/// depended on FCM/APNs would be silent exactly when it mattered. The cost is
/// that the app must be running to raise one (see the platform note below).
///
/// Two rules keep this from becoming noise, and both matter more than the
/// feature itself:
///
/// - **Never announce what the user is already reading.** A message arriving in
///   the conversation on screen is not news.
/// - **Never announce the node-DB dump.** Connecting to a busy mesh delivers
///   twenty-odd nodes in two seconds; none of them are "new", they are just
///   being introduced. Only nodes first heard well after the link settled count.
///
/// **Platform reality**: Android keeps the process (and so the BLE link) alive
/// in the background for a long while, so these arrive there. iOS suspends the
/// app without the `bluetooth-central` background mode, and a suspended app
/// receives no BLE events — so on iOS today these are foreground-only.
library;

import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/widgets.dart';

/// One notification this class decided to raise.
@immutable
class MeshAlert {
  const MeshAlert({
    required this.channelKey,
    required this.id,
    required this.title,
    required this.body,
  });

  final String channelKey;
  final int id;
  final String title;
  final String body;
}

class MeshAlerts extends ChangeNotifier {
  /// [post] and [now] are injectable so the suppression rules — which are the
  /// whole value here — can be tested without an OS notification channel or a
  /// twenty-second wait.
  MeshAlerts(
    this._service,
    this._settings, {
    Future<void> Function(MeshAlert alert)? post,
    DateTime Function()? now,
  }) : _post = post ?? _postToOs,
       _now = now ?? (() => AppTime.utc.toLocal());

  /// How long after the link comes up before a node counts as newly *heard*
  /// rather than newly *introduced*. The config download hands over the whole
  /// node DB in the first seconds of a connection.
  static const Duration _nodeSettleDelay = Duration(seconds: 20);

  /// Notification titles are prefixed with this so a mesh alert is
  /// recognisable at a glance in a crowded shade. A product name, not prose —
  /// it reads the same in every language.
  static const String _appName = 'Meshtastic';

  /// Ceiling on node notifications per minute — a mesh that suddenly hears a
  /// dozen neighbours must not produce a dozen notifications.
  static const int _nodeBurstLimit = 3;

  final MeshtasticService _service;
  final SettingsStore _settings;
  final Future<void> Function(MeshAlert alert) _post;
  final DateTime Function() _now;

  StreamSubscription<MeshMessage>? _messageSub;
  StreamSubscription<MeshNode>? _nodeSub;
  StreamSubscription<MeshConnectionStatus>? _statusSub;
  AppLifecycleListener? _lifecycle;

  final Set<int> _knownNodes = {};

  /// Node number → display name, accumulated from the node stream so a
  /// notification can name a sender instead of showing a hex id.
  final Map<int, String> _nodeNames = {};
  DateTime? _linkReadyAt;
  final List<DateTime> _recentNodeAlerts = [];

  bool _messagesEnabled = true;
  bool _nodesEnabled = false;

  /// Which conversation is on screen right now, set by the mesh page. Null
  /// when the page isn't showing.
  int? _visibleChannel;
  bool _appInForeground = true;

  /// Whether an incoming mesh message raises a notification.
  bool get messagesEnabled => _messagesEnabled;

  /// Whether a newly heard node raises one. Off by default: on a busy mesh
  /// new neighbours appear all day and almost none of them are worth an alert.
  bool get nodesEnabled => _nodesEnabled;

  void start() {
    _messagesEnabled =
        _settings.getBool(SettingKeys.meshNotifyMessages) ?? true;
    _nodesEnabled = _settings.getBool(SettingKeys.meshNotifyNodes) ?? false;
    _messageSub ??= _service.messageStream.listen(_onMessage);
    _nodeSub ??= _service.nodeStream.listen(_onNode);
    _statusSub ??= _service.connectionStream.listen(_onStatus);
    // Backgrounded, the page may still be "showing" a channel it can no longer
    // show anyone — so foreground is part of the suppression rule, not the
    // visible channel alone.
    _lifecycle ??= AppLifecycleListener(
      onResume: () => setForeground(foreground: true),
      onHide: () => setForeground(foreground: false),
      onPause: () => setForeground(foreground: false),
    );
  }

  Future<void> setMessagesEnabled({required bool enabled}) async {
    _messagesEnabled = enabled;
    notifyListeners();
    await _settings.setBool(SettingKeys.meshNotifyMessages, enabled);
  }

  Future<void> setNodesEnabled({required bool enabled}) async {
    _nodesEnabled = enabled;
    notifyListeners();
    await _settings.setBool(SettingKeys.meshNotifyNodes, enabled);
  }

  /// Called by the mesh page: [channel] while it is showing that conversation,
  /// null when it goes away.
  void setVisibleChannel(int? channel) => _visibleChannel = channel;

  /// Called by the app shell so a backgrounded app still notifies for the
  /// conversation that was last on screen.
  void setForeground({required bool foreground}) =>
      _appInForeground = foreground;

  void _onStatus(MeshConnectionStatus status) {
    if (status.state == MeshConnectionState.connected) {
      _linkReadyAt ??= _now();
      return;
    }
    if (status.state == MeshConnectionState.disconnected ||
        status.state == MeshConnectionState.error) {
      // The next connection dumps the node DB again; start the clock over.
      _linkReadyAt = null;
    }
  }

  void _onMessage(MeshMessage message) {
    if (!_messagesEnabled) return;
    if (message.text.isEmpty) return;
    // Already on screen, in that channel, with the app in front: not news.
    if (_appInForeground && _visibleChannel == message.channel) return;
    unawaited(
      _post(
        MeshAlert(
          channelKey: 'mesh_message',
          // Notification ids must fit a 32-bit int; the timestamp keeps
          // consecutive messages from collapsing onto one another.
          id: message.timestamp.millisecondsSinceEpoch & 0x7FFFFFFF,
          title: '$_appName - ${_channelLabel(message.channel)}',
          body:
              '${_senderName(message.from)} - ${_clockLabel(message.timestamp)}'
              '\n${message.text}',
        ),
      ),
    );
  }

  /// What to call a channel in a notification.
  ///
  /// Channel *names* only exist while a radio is attached — they come from its
  /// channel table. With no link (or for a slot the table never described)
  /// the index is all that is known, so the label degrades to `CH0`, `CH1`…
  /// rather than inventing a name or leaving the title half-empty.
  String _channelLabel(int index) {
    for (final channel in _service.channels) {
      if (channel.index == index && channel.name.isNotEmpty) {
        return channel.name;
      }
    }
    return 'CH$index';
  }

  /// `HH:mm:ss`, built by hand rather than through `intl`: this runs in
  /// `core/` with no `BuildContext`, and a mesh timestamp is a clock reading,
  /// not a localised date.
  String _clockLabel(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)}:${two(at.second)}';
  }

  /// The sender's name once the mesh has introduced it, else its id.
  String _senderName(int from) {
    final name = _nodeNames[from];
    return (name != null && name.isNotEmpty)
        ? name
        : '0x${from.toRadixString(16)}';
  }

  void _onNode(MeshNode node) {
    // Recorded before any early return: a node the user doesn't want announced
    // is still a node whose name a *message* notification will want.
    if (node.displayName.isNotEmpty) _nodeNames[node.num] = node.displayName;
    final firstTime = _knownNodes.add(node.num);
    if (!firstTime || !_nodesEnabled) return;
    final readyAt = _linkReadyAt;
    if (readyAt == null) return; // still downloading the node DB
    if (_now().difference(readyAt) < _nodeSettleDelay) return;
    if (!_allowNodeAlert()) return;
    unawaited(
      _post(
        MeshAlert(
          channelKey: 'mesh_node',
          id: node.num & 0x7FFFFFFF,
          title: _appName,
          body: _senderName(node.num),
        ),
      ),
    );
  }

  bool _allowNodeAlert() {
    final now = _now();
    _recentNodeAlerts.removeWhere(
      (at) => now.difference(at) > const Duration(minutes: 1),
    );
    if (_recentNodeAlerts.length >= _nodeBurstLimit) return false;
    _recentNodeAlerts.add(now);
    return true;
  }

  static Future<void> _postToOs(MeshAlert alert) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: alert.id,
          channelKey: alert.channelKey,
          title: alert.title,
          body: alert.body,
          icon: NotificationChannels.icon,
          // Grouped so a burst of mesh traffic collapses into one stack
          // rather than a column of separate notifications.
          groupKey: alert.channelKey,
          payload: {'channel': alert.channelKey},
          // The two platforms disagree about multi-line bodies. iOS renders a
          // `\n` as-is; Android collapses a notification to a single line
          // unless it is told the body is long-form, so without `BigText` the
          // second line would simply never be seen. Setting both keeps one
          // string rendering the same way on each.
          notificationLayout: NotificationLayout.BigText,
          wakeUpScreen: false,
        ),
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh notification');
    }
  }

  @override
  void dispose() {
    unawaited(_messageSub?.cancel());
    unawaited(_nodeSub?.cancel());
    unawaited(_statusSub?.cancel());
    _lifecycle?.dispose();
    super.dispose();
  }
}
