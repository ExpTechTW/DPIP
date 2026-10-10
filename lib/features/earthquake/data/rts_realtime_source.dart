import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/sse_realtime_source.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';

/// The live RTS feed: the `trem.rts.v1` topic of the TREM stream.
///
/// Runs at whichever speed [RtsLiveDemand] asks for. **Live**, every frame
/// arrives (~2 Hz) and liveness is event recency — silence on a feed that
/// should be talking means trouble, and the channel ages it to stale. Asleep,
/// the server sends a frame only while a station is alerting, so silence is
/// the normal, calm answer: the source reports an empty frame (nothing
/// alerting) for as long as the connection is open, instead of a failure.
///
/// A change of speed swaps the connection without a gap (see
/// [SseRealtimeSource.renew]). Waking is immediate — the monitor has just
/// opened and wants the frames now — while falling asleep waits
/// [sleepDelay], so flicking between tabs does not reconnect each time.
class RtsRealtimeSource extends SseRealtimeSource<Rts> {
  /// [connect] opens one TREM stream connection at the given speed — in
  /// production `EarthquakeApi.openTremSse`; the source calls it again for
  /// each reconnect and each change of speed.
  RtsRealtimeSource(
    Stream<SseEvent> Function({required bool live}) connect, {
    required RtsLiveDemand demand,
    this.sleepDelay = const Duration(seconds: 3),
    super.elapsed,
    super.delay,
  }) : _demand = demand,
       _live = demand.live,
       super(
         connect: () => connect(live: demand.live),
         liveness: const SseLiveness.eventRecency(Duration(seconds: 3)),
         label: 'rts',
         payloadEvent: EarthquakeApi.rtsTopic,
       ) {
    demand.addListener(_onDemand);
  }

  final RtsLiveDemand _demand;

  /// How long the demand has to stay released before the feed sleeps.
  final Duration sleepDelay;

  /// The speed the connection was last asked to run at.
  bool _live;
  Timer? _sleepTimer;

  void _onDemand() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (_demand.live) {
      _switchTo(live: true);
    } else {
      _sleepTimer = Timer(sleepDelay, () => _switchTo(live: false));
    }
  }

  void _switchTo({required bool live}) {
    if (live == _live) return;
    _live = live;
    renew();
  }

  /// Asleep, a connection with nothing to say is reporting calm.
  @override
  Rts? get quiet => _live ? null : const Rts();

  @override
  Rts decode(String data) =>
      Rts.fromJson(jsonDecode(data) as Map<String, dynamic>);

  /// The live path. Parses the inflated UTF-8 directly — the fused decoder
  /// is the pair `jsonDecode` itself uses on a byte input, so the map handed
  /// to [Rts.fromJson] is shape-for-shape what [decode] builds from a string;
  /// it just never builds the string. See [SseRealtimeSource.decodeBytes].
  @override
  Rts decodeBytes(Uint8List utf8Json) =>
      Rts.fromJson(_utf8Json.convert(utf8Json) as Map<String, dynamic>);

  /// Fused once; `fuse` builds a new converter object per call.
  static final Converter<List<int>, Object?> _utf8Json = const Utf8Decoder()
      .fuse(const JsonDecoder());

  /// Null: freshness is event-recency (above), not payload age — so clock skew
  /// on the frame's `ts` can't reclassify a live feed.
  @override
  DateTime? timestampOf(Rts value) => null;

  @override
  bool sameData(Rts? a, Rts? b) => sameRtsFrame(a, b);

  @override
  void dispose() {
    _demand.removeListener(_onDemand);
    _sleepTimer?.cancel();
    _sleepTimer = null;
    super.dispose();
  }
}
