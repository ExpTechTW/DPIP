@Tags(['benchmark'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dpip/features/earthquake/data/rts_worker.dart';
import 'package:dpip/features/earthquake/data/rts_worker_service.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/shared/map/monitor_map_stack.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl_platform_interface/maplibre_gl_platform_interface.dart';

/// What one live RTS frame costs the UI isolate, from the SSE event to the
/// bytes handed to the platform channel — on the path the monitor took before
/// the RTS worker, and on the worker's.
///
/// `tool/dev/test.sh --run-skipped --tags benchmark <this file>`
///
/// Before: the frame is inflated and parsed here, the station layer is built
/// here, and MapLibre's `setGeoJsonSource` — the payload being over its
/// hundred-feature threshold — copies the map into a fresh `compute` isolate
/// to encode it. After: the payload string goes to the worker and the decoded
/// frame comes back; the layer is asked for by the frame's number and comes
/// back encoded. Both end in the same platform-channel encode of one string.
///
/// Two numbers per path. *Synchronous work* adds up every stretch the UI
/// isolate spends on the frame. *Longest stall* is the longest the UI
/// isolate's event loop went without a turn while frames went through it —
/// what a dropped frame on screen is made of. Host numbers, JIT: a cheap
/// phone runs the same work several times slower, so read the ratio.
void main() {
  test('one live RTS frame on the UI isolate, before and after', () async {
    const stations = 1000;
    const warmUp = 40;
    const measured = 200;
    final random = Random(42);
    final directory = <String, SeismicStation>{
      for (var n = 0; n < stations; n++)
        _id(n): SeismicStation(
          id: _id(n),
          latitude: 21.9 + random.nextDouble() * 3.4,
          longitude: 119.9 + random.nextDouble() * 2.2,
        ),
    };
    final payloads = [
      for (var f = 0; f < warmUp + measured; f++) _payload(f, stations, random),
    ];
    final icons = [
      for (var level = 0; level < 10; level++)
        monitorBadgeIcon(level, dark: false),
    ];
    const codec = StandardMethodCodec();
    void toChannel(String geojson) => codec.encodeMethodCall(
      MethodCall('source#setGeoJson', {
        'sourceId': 'rts-src',
        'geojson': geojson,
      }),
    );

    final beforeWork = <int>[];
    final stages = <String, List<int>>{
      'decode': [],
      'build': [],
      'hand-off': [],
      'channel': [],
    };
    var beforeStall = Duration.zero;
    final watch = Stopwatch();
    for (var f = 0; f < payloads.length; f++) {
      final probe = _StallProbe();
      final marks = <int>[];
      watch
        ..reset()
        ..start();
      final frame = decodeRtsJson(
        gzip.decode(base64.decode(payloads[f].trim())),
      );
      marks.add(watch.elapsedMicroseconds);
      final geojson = rtsStationGeoJson(
        frame.stations,
        directory,
        eventLit: false,
        eewActive: false,
        badgeIcons: icons,
      );
      marks.add(watch.elapsedMicroseconds);
      final encoding = MapLibreMethodChannel.isLargeGeoJson(geojson)
          ? compute(jsonEncode, geojson)
          : Future.value(jsonEncode(geojson));
      watch.stop();
      marks.add(watch.elapsedMicroseconds);
      final encoded = await encoding;
      watch.start();
      toChannel(encoded);
      watch.stop();
      marks.add(watch.elapsedMicroseconds);
      final stall = await probe.stop();
      if (f >= warmUp) {
        beforeWork.add(watch.elapsedMicroseconds);
        for (final (i, stage) in stages.values.indexed) {
          stage.add(marks[i] - (i == 0 ? 0 : marks[i - 1]));
        }
        if (stall > beforeStall) beforeStall = stall;
      }
    }

    final worker = RtsWorkerService()..placeStations(directory);
    final afterWork = <int>[];
    final latency = <int>[];
    var afterStall = Duration.zero;
    final total = Stopwatch();
    for (var f = 0; f < payloads.length; f++) {
      final probe = _StallProbe();
      total
        ..reset()
        ..start();
      watch
        ..reset()
        ..start();
      final decoding = worker.decode(payloads[f])!;
      watch.stop();
      final frame = (await decoding)!;
      watch.start();
      final encoding = worker.encode(
        frame,
        eventLit: false,
        eewActive: false,
        badgeIcons: icons,
      );
      watch.stop();
      final encoded = (await encoding)!;
      watch.start();
      toChannel(encoded);
      watch.stop();
      total.stop();
      final stall = await probe.stop();
      if (f >= warmUp) {
        afterWork.add(watch.elapsedMicroseconds);
        latency.add(total.elapsedMicroseconds);
        if (stall > afterStall) afterStall = stall;
      }
    }
    worker.dispose();

    final size = payloads.first.length;
    stdout
      ..writeln('RTS frame: $stations stations, ${size ~/ 1024} KB payload')
      ..writeln(
        'before  sync work  ${_summary(beforeWork)}   '
        'longest stall ${_ms(beforeStall.inMicroseconds)}',
      )
      ..writeln(
        '        ${stages.entries.map((stage) => '${stage.key} '
            '${_summary(stage.value)}').join('; ')}',
      )
      ..writeln(
        'after   sync work  ${_summary(afterWork)}   '
        'longest stall ${_ms(afterStall.inMicroseconds)}',
      )
      ..writeln('after   frame to string ${_summary(latency)} (off the UI)');
    expect(afterWork, hasLength(measured));
  }, timeout: const Timeout(Duration(minutes: 5)));
}

String _id(int n) => (0x11D0000 + n * 37).toRadixString(16).toUpperCase();

/// A frame as the stream sends it, with readings shaped like the wire's: two
/// decimals, most stations calm, a few alerting.
String _payload(int f, int stations, Random random) {
  double two(double v) => (v * 100).roundToDouble() / 100;
  final json = {
    'ts': 1790537637000 + f * 500,
    'stations': {
      for (var n = 0; n < stations; n++)
        _id(n): {
          'i': two(random.nextDouble() * 4 - 3),
          'pga': two(random.nextDouble() * 3),
          if (random.nextInt(200) == 0) 'alert': 1,
        },
    },
  };
  return base64.encode(gzip.encode(utf8.encode(jsonEncode(json))));
}

/// Watches the UI isolate's event loop: a timer that re-arms itself on every
/// turn, keeping the longest gap between two turns.
class _StallProbe {
  _StallProbe() {
    _clock.start();
    Timer.run(_tick);
  }

  final Stopwatch _clock = Stopwatch();
  Duration _last = Duration.zero;
  Duration _longest = Duration.zero;
  bool _running = true;
  final Completer<Duration> _done = Completer();

  void _tick() {
    final now = _clock.elapsed;
    final gap = now - _last;
    if (gap > _longest) _longest = gap;
    _last = now;
    if (_running) {
      Timer.run(_tick);
    } else {
      _done.complete(_longest);
    }
  }

  Future<Duration> stop() {
    _running = false;
    return _done.future;
  }
}

String _summary(List<int> micros) {
  final sorted = [...micros]..sort();
  final median = sorted[sorted.length ~/ 2];
  final p95 = sorted[(sorted.length * 0.95).floor()];
  return 'median ${_ms(median)}, p95 ${_ms(p95)}';
}

String _ms(int micros) => '${(micros / 1000).toStringAsFixed(2)} ms';
