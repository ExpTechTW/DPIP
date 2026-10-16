/// 強震監視器 (RTS) — the station layer built off the UI isolate.
///
/// With an encoder, the layer hands the frame it is showing to the encoder and
/// writes the string it answers; without an answer it builds the layer itself,
/// as it always did. Either way it is the same layer: a real worker's string
/// is checked against the old builder's output. And because one write may now
/// wait on the worker while the next does not, a write overtaken by a newer
/// one — or by the feed going offline — must never land after it.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/data/rts_worker_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/rts_station_encoder.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:dpip/shared/map/monitor_map_stack.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

const String _stationSource = 'rts-src';

/// Records every write to the station source, in the order the map got them.
class _Map extends RecordingMapController {
  final writes = <({bool encoded, Object data})>[];

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {
    if (sourceId == _stationSource) {
      writes.add((encoded: false, data: geojson));
    }
    await super.setGeoJsonSource(sourceId, geojson);
  }

  @override
  Future<void> setGeoJsonSourceEncoded(String sourceId, String geojson) async {
    if (sourceId == _stationSource) writes.add((encoded: true, data: geojson));
  }

  /// The last write as the JSON the map ended up with.
  String get lastJson {
    final last = writes.last;
    return last.encoded ? last.data as String : jsonEncode(last.data);
  }
}

/// An encoder that answers with [answer] at once, or — while [answer] is
/// null — holds every request for the test to answer by hand.
class _Encoder implements RtsStationEncoder {
  _Encoder([this.answer]);

  String? Function(Rts frame)? answer;

  final asked =
      <
        ({
          Rts frame,
          bool eventLit,
          bool eewActive,
          List<String> badgeIcons,
          Completer<String?> answer,
        })
      >[];
  Map<String, SeismicStation>? placed;

  @override
  void placeStations(Map<String, SeismicStation> stations) => placed = stations;

  @override
  Future<String?> encode(
    Rts frame, {
    required bool eventLit,
    required bool eewActive,
    required List<String> badgeIcons,
  }) {
    final reply = Completer<String?>();
    asked.add((
      frame: frame,
      eventLit: eventLit,
      eewActive: eewActive,
      badgeIcons: badgeIcons,
      answer: reply,
    ));
    final answer = this.answer;
    if (answer != null) reply.complete(answer(frame));
    return reply.future;
  }
}

class _Clock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 8, 12, 12);
}

class _Elapsed implements Elapsed {
  Duration value = Duration.zero;
  @override
  Duration get elapsed => value;
}

class _Ticker implements Ticker {
  @override
  TickerHandle start(Duration interval, void Function() onTick) => _Handle();
}

class _Handle implements TickerHandle {
  @override
  void cancel() {}
}

class _Static<T> extends RealtimeSource<T> {
  _Static(this.data);
  T data;
  @override
  Future<Result<T>> fetch() async => Ok(data);
  @override
  DateTime? timestampOf(T value) => null;
  @override
  bool sameData(T? a, T? b) => identical(a, b);
}

const _directory = {
  'A1': SeismicStation(id: 'A1', latitude: 23.5, longitude: 121.5),
  'B2': SeismicStation(id: 'B2', latitude: 23.8, longitude: 121.0),
  'C3': SeismicStation(id: 'C3', latitude: 24.5, longitude: 121.3),
};

class _Stations implements TremStationRepository {
  @override
  Future<Map<String, SeismicStation>?> saved() async => _directory;

  @override
  Future<Result<Map<String, SeismicStation>>> refresh() async =>
      const Ok(_directory);
}

Rts _frame(int time, {double shake = 1.2}) => Rts(
  time: time,
  stations: {
    'A1': RtsStation(intensity: shake, pga: 3),
    'B2': const RtsStation(intensity: -0.4),
    'C3': const RtsStation(intensity: 2.7, alert: true),
    'Z9': const RtsStation(intensity: 4.0), // not in the directory
  },
);

/// The light-artwork icon table, as the layer builds it.
final _lightIcons = [
  for (var level = 0; level < 10; level++) monitorBadgeIcon(level, dark: false),
];

String _builtHere(Rts frame) => jsonEncode(
  rtsStationGeoJson(
    frame.stations,
    _directory,
    eventLit: false,
    eewActive: false,
    badgeIcons: _lightIcons,
  ),
);

typedef _Rig = ({
  RtsMapLayer layer,
  _Static<Rts> source,
  RealtimeChannel<Rts> channel,
  _Elapsed elapsed,
});

Future<_Rig> _rig(Rts first, {RtsStationEncoder? encoder}) async {
  final elapsed = _Elapsed();
  final source = _Static<Rts>(first);
  final channel = RealtimeChannel<Rts>(
    source: source,
    clock: _Clock(),
    elapsed: elapsed,
    ticker: _Ticker(),
    config: RealtimeConfig.rts,
    label: 'test-rts',
  );
  await channel.refreshNow();
  final eewChannel = RealtimeChannel<List<Eew>>(
    source: _Static<List<Eew>>(const []),
    clock: _Clock(),
    elapsed: _Elapsed(),
    ticker: _Ticker(),
    config: RealtimeConfig.eew,
    label: 'test-eew',
  );
  await eewChannel.refreshNow();
  return (
    layer: RtsMapLayer(
      RealtimeNotifier<Rts>(channel),
      _Stations(),
      eew: RealtimeNotifier<List<Eew>>(eewChannel),
      travelTimeTable: Future.value(const SeismicTravelTimeTable({})),
      boxGrid: Future.value(const RtsBoxGrid(<int, List<List<double>>>{})),
      townDirectory: const TownDirectory({}),
      stationEncoder: encoder,
    ),
    source: source,
    channel: channel,
    elapsed: elapsed,
  );
}

/// Publishes [frame] as the feed's next snapshot.
Future<void> _publish(_Rig rig, Rts frame) async {
  rig.source.data = frame;
  await rig.channel.refreshNow();
  await pumpEventQueue();
}

void main() {
  test('writes the encoder\'s string for the frame on screen', () async {
    final encoder = _Encoder((frame) => 'encoded-${frame.time}');
    final rig = await _rig(_frame(1), encoder: encoder);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();

    expect(encoder.placed, same(_directory));
    final ask = encoder.asked.last;
    expect(ask.frame, same(rig.source.data), reason: 'the frame itself');
    expect(ask.eventLit, isFalse);
    expect(ask.eewActive, isFalse);
    expect(ask.badgeIcons, _lightIcons);
    expect(map.writes.last, (encoded: true, data: 'encoded-1'));
  });

  test('builds the layer itself when the encoder has no answer', () async {
    final encoder = _Encoder((_) => null);
    final rig = await _rig(_frame(1), encoder: encoder);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();

    expect(map.writes.last.encoded, isFalse);
    expect(map.lastJson, _builtHere(rig.source.data));
  });

  test('a write overtaken while it waits never lands', () async {
    final encoder = _Encoder((frame) => 'encoded-${frame.time}');
    final rig = await _rig(_frame(1), encoder: encoder);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();
    encoder.answer = null;
    map.writes.clear();

    await _publish(rig, _frame(2));
    final slow = encoder.asked.last;
    await _publish(rig, _frame(3));
    final fast = encoder.asked.last;
    expect(fast.frame.time, 3);

    fast.answer.complete('encoded-3');
    await pumpEventQueue();
    slow.answer.complete('encoded-2');
    await pumpEventQueue();
    expect(map.writes, [(encoded: true, data: 'encoded-3')]);
  });

  test('nor after a newer frame the encoder does not hold', () async {
    final encoder = _Encoder((frame) => 'encoded-${frame.time}');
    final rig = await _rig(_frame(1), encoder: encoder);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();
    encoder.answer = null;
    map.writes.clear();

    await _publish(rig, _frame(2));
    final slow = encoder.asked.last;
    await _publish(rig, _frame(3));
    encoder.asked.last.answer.complete(null); // built here, at once
    await pumpEventQueue();
    slow.answer.complete('encoded-2');
    await pumpEventQueue();

    expect(map.writes, hasLength(1));
    expect(map.lastJson, _builtHere(_frame(3)));
  });

  test('nor after the feed went offline', () async {
    final encoder = _Encoder((frame) => 'encoded-${frame.time}');
    final rig = await _rig(_frame(1), encoder: encoder);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();
    encoder.answer = null;
    map.writes.clear();

    await _publish(rig, _frame(2));
    final slow = encoder.asked.last;
    rig.elapsed.value += const Duration(seconds: 11);
    rig.channel.recomputeStatus();
    await pumpEventQueue();
    slow.answer.complete('encoded-2');
    await pumpEventQueue();

    expect(map.writes, hasLength(1));
    expect(map.lastJson, jsonEncode(monitorEmptyCollection));
  });

  test('a status change alone asks for nothing', () async {
    final encoder = _Encoder((frame) => 'encoded-${frame.time}');
    final rig = await _rig(_frame(1), encoder: encoder);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();
    final asked = encoder.asked.length;
    map.writes.clear();

    rig.elapsed.value += const Duration(seconds: 4); // live → stale
    rig.channel.recomputeStatus();
    await pumpEventQueue();

    expect(encoder.asked, hasLength(asked));
    expect(map.writes, isEmpty);
  });

  test('a real worker draws what the old builder drew', () async {
    final worker = RtsWorkerService();
    final payload = base64.encode(
      gzip.encode(utf8.encode(jsonEncode(_frame(7).toJson()))),
    );
    final frame = (await worker.decode(payload))!;
    final rig = await _rig(frame, encoder: worker);
    final map = _Map();
    await rig.layer.render(map);
    await pumpEventQueue();

    expect(map.writes.last.encoded, isTrue, reason: 'built on the worker');
    expect(map.lastJson, _builtHere(frame));
    worker.dispose();
  });
}
