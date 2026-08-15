/// Which mesh conversations hold messages the user has not seen.
///
/// In `core/` rather than the chat controller because two features read it:
/// the chat page (per-channel pills, the Discord divider) and the More tab's
/// Meshtastic row (one red dot). A feature may not import another feature's
/// presentation, so state both need lives below both — the same reason
/// [MeshAlerts] sits here.
///
/// The chat controller stays the *writer*: it is the one place that knows
/// whether an arriving packet was genuinely new (the store's unique index
/// answers that, deduplicating reconnect replays), so it reports here rather
/// than this class listening to the raw stream and counting duplicates.
library;

import 'dart:async';

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:flutter/foundation.dart';

class MeshUnread extends ChangeNotifier {
  MeshUnread(this._store) {
    unawaited(restore());
  }

  /// Null when the database would not open — unread then lives for the
  /// session only, like the message log itself.
  final MeshStore? _store;

  final Map<int, int> _unread = {};
  final Map<int, int> _lastReads = {};

  /// Newest received-message timestamp per channel — what a read position
  /// advances to.
  final Map<int, int> _newest = {};

  int? _visibleChannel;
  int? _dividerChannel;
  int? _dividerTs;

  /// Received messages newer than each channel's read position.
  Map<int, int> get byChannel => Map.unmodifiable(_unread);

  /// Whether anything, anywhere, is unread — the More tab's dot.
  bool get hasUnread => _unread.values.any((count) => count > 0);

  /// Where the unread divider sits in the open conversation, or null when
  /// there is nothing new there.
  ///
  /// Snapshotted the moment the conversation is opened — *before* the read
  /// position advances — because opening is also what marks everything read:
  /// derived live from `last_read` the line would vanish in the same frame it
  /// appeared. It holds for the visit (the Discord behaviour) and clears on
  /// switching away.
  int? unreadDividerTs(int channel) =>
      channel == _dividerChannel ? _dividerTs : null;

  /// Tells the tracker which conversation is on screen (null = none).
  ///
  /// Selecting a conversation reads it: its count clears and its read
  /// position advances to its newest message.
  void markVisible(int? channel) {
    if (channel == _visibleChannel) return;
    _visibleChannel = channel;
    if (channel == null) {
      _dividerChannel = null;
      _dividerTs = null;
      return;
    }
    final hadUnread = (_unread.remove(channel) ?? 0) > 0;
    _dividerChannel = hadUnread ? channel : null;
    _dividerTs = hadUnread ? (_lastReads[channel] ?? 0) : null;
    _advanceRead(channel);
    if (hadUnread) notifyListeners();
  }

  /// Records a genuinely new received message.
  ///
  /// In the open conversation it is read on arrival (the position advances
  /// with it); anywhere else it accrues.
  void recordIncoming(int channel, int tsMs) {
    if (tsMs > (_newest[channel] ?? 0)) _newest[channel] = tsMs;
    if (channel == _visibleChannel) {
      _advanceRead(channel);
    } else {
      _unread[channel] = (_unread[channel] ?? 0) + 1;
      notifyListeners();
    }
  }

  /// Reloads read positions and counts from the store.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;
    _lastReads
      ..clear()
      ..addAll(await store.readLastReads());
    _unread
      ..clear()
      ..addAll(await store.unreadCounts());
    _newest
      ..clear()
      ..addAll(await store.newestIncomingTsByChannel());
    // The conversation already on screen is read by definition.
    final visible = _visibleChannel;
    if (visible != null && _unread.remove(visible) != null) {
      _advanceRead(visible);
    }
    notifyListeners();
  }

  /// Forgets everything — the log was cleared.
  void reset() {
    if (_unread.isEmpty && _dividerChannel == null) return;
    _unread.clear();
    _dividerChannel = null;
    _dividerTs = null;
    notifyListeners();
  }

  void _advanceRead(int channel) {
    final newest = _newest[channel] ?? 0;
    // Only on change: re-opening a read conversation must not rewrite the
    // same position on every page build.
    if (newest == 0 || newest == (_lastReads[channel] ?? 0)) return;
    _lastReads[channel] = newest;
    unawaited(_store?.writeLastRead(channel, newest));
  }
}
