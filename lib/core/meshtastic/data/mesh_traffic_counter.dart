/// The packet counters behind [MeshtasticService.traffic].
///
/// Its own class so the accounting can be tested without a radio, and so the
/// transport has exactly one place that decides what counts as traffic.
library;

import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/realtime/app_time.dart';

class MeshTrafficCounter {
  MeshTrafficCounter({DateTime Function()? now})
    : _now = now ?? (() => AppTime.utc.toLocal());

  final DateTime Function() _now;

  int _rxPackets = 0;
  int _txPackets = 0;
  int _rxBytes = 0;
  int _txBytes = 0;
  int _rxUndecoded = 0;
  final Map<int, int> _rxByPort = {};
  DateTime? _lastRx;
  DateTime? _lastTx;

  /// Records an inbound packet. [portnum] is null when the radio could not
  /// decrypt it — those still count, because they are still proof the link is
  /// delivering.
  void recordRx({required int? portnum, required int bytes}) {
    _rxPackets++;
    _rxBytes += bytes;
    _lastRx = _now();
    if (portnum == null) {
      _rxUndecoded++;
      return;
    }
    _rxByPort[portnum] = (_rxByPort[portnum] ?? 0) + 1;
  }

  void recordTx({required int bytes}) {
    _txPackets++;
    _txBytes += bytes;
    _lastTx = _now();
  }

  /// An immutable view for the UI. Counters are **session** totals — they
  /// deliberately survive a reconnect, so a link that keeps dropping doesn't
  /// keep resetting the evidence of it.
  MeshTraffic get snapshot => MeshTraffic(
    rxPackets: _rxPackets,
    txPackets: _txPackets,
    rxBytes: _rxBytes,
    txBytes: _txBytes,
    rxUndecoded: _rxUndecoded,
    rxByPort: Map.unmodifiable(_rxByPort),
    lastRx: _lastRx,
    lastTx: _lastTx,
  );
}
