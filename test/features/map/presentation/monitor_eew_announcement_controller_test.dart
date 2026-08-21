/// Tests latest-report-wins EEW speech on the visible seismic monitor.
library;

import 'dart:async';

import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/map/presentation/monitor_eew_announcement_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpeech implements SpeechService {
  final List<String> spoken = [];
  final List<Completer<void>> completions = [];
  int stops = 0;

  @override
  Future<void> speak(String text, {required String languageTag}) {
    spoken.add('$languageTag:$text');
    final completion = Completer<void>();
    completions.add(completion);
    return completion.future;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  void dispose() {}
}

Eew _alert(int serial) => Eew(
  agency: 'CWA',
  id: 'event',
  serial: serial,
  status: 0,
  isFinal: false,
  info: const EewInfo(
    time: 0,
    longitude: 121,
    latitude: 23,
    depth: 10,
    magnitude: 6,
    location: 'test',
    max: 6,
  ),
);

RealtimeState<List<Eew>> _live(Eew alert) =>
    RealtimeState(status: RealtimeStatus.live, data: [alert]);

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'new serial interrupts old speech and only latest releases sound',
    () async {
      final speech = _FakeSpeech();
      final gate = ForegroundEewAnnouncementGate();
      final controller = MonitorEewAnnouncementController(
        speech,
        gate,
        (alert) async => (scale: alert.serial, isLocal: true),
      );
      controller.setActive(true);
      controller.update(
        _live(_alert(1)),
        languageTag: 'zh-TW',
        format: (estimate) => '震度${estimate.scale}',
      );
      await _flush();
      expect(speech.spoken, ['zh-TW:震度1']);

      var notifications = 0;
      await gate.submit(() async => notifications++);
      controller.update(
        _live(_alert(2)),
        languageTag: 'zh-TW',
        format: (estimate) => '震度${estimate.scale}',
      );
      await _flush();
      expect(speech.spoken, ['zh-TW:震度1', 'zh-TW:震度2']);
      expect(speech.stops, greaterThanOrEqualTo(2));

      speech.completions.first.complete();
      await _flush();
      expect(notifications, 0);

      speech.completions.last.complete();
      await _flush();
      expect(notifications, 1);
      controller.dispose();
    },
  );

  test('duplicate and older serials are not spoken again', () async {
    final speech = _FakeSpeech();
    final controller = MonitorEewAnnouncementController(
      speech,
      ForegroundEewAnnouncementGate(),
      (_) async => (scale: 4, isLocal: true),
    );
    controller.setActive(true);
    for (final serial in [2, 2, 1]) {
      controller.update(
        _live(_alert(serial)),
        languageTag: 'zh-TW',
        format: (_) => '所在地預估震度，四級。',
      );
    }
    await _flush();

    expect(speech.spoken, hasLength(1));
    speech.completions.single.complete();
    controller.dispose();
  });

  test('stale feed stops speech and releases the pending warning', () async {
    final speech = _FakeSpeech();
    final gate = ForegroundEewAnnouncementGate();
    final controller = MonitorEewAnnouncementController(
      speech,
      gate,
      (_) async => (scale: 4, isLocal: true),
    );
    controller.setActive(true);
    controller.update(
      _live(_alert(1)),
      languageTag: 'zh-TW',
      format: (_) => '所在地預估震度，四級。',
    );
    await _flush();
    var displayed = false;
    await gate.submit(() async => displayed = true);

    controller.update(
      RealtimeState<List<Eew>>(status: RealtimeStatus.stale, data: [_alert(1)]),
      languageTag: 'zh-TW',
      format: (_) => 'unused',
    );
    await _flush();

    expect(displayed, isTrue);
    expect(speech.stops, greaterThanOrEqualTo(2));
    controller.dispose();
  });

  test(
    'repeated calm feed ticks do not call the platform every second',
    () async {
      final speech = _FakeSpeech();
      final controller = MonitorEewAnnouncementController(
        speech,
        ForegroundEewAnnouncementGate(),
        (_) async => (scale: 4, isLocal: true),
      );
      controller.setActive(true);
      const calm = RealtimeState<List<Eew>>(
        status: RealtimeStatus.live,
        data: [],
      );

      for (var i = 0; i < 3; i++) {
        controller.update(calm, languageTag: 'zh-TW', format: (_) => 'unused');
      }
      await _flush();

      expect(speech.stops, 0);
      controller.dispose();
    },
  );
}
