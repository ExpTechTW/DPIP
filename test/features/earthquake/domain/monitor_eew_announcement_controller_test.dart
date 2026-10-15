/// Tests latest-report-wins EEW speech on the visible seismic monitor.
library;

import 'dart:async';

import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/monitor_eew_announcement_controller.dart';
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

Eew _alert(int serial, {String id = 'event', int status = 0, int max = 6}) =>
    Eew(
      agency: 'CWA',
      id: id,
      serial: serial,
      status: status,
      isFinal: false,
      info: EewInfo(
        time: 0,
        longitude: 121,
        latitude: 23,
        depth: 10,
        magnitude: 6,
        location: 'test',
        max: max,
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

  test('leaving the monitor stops speech and a second leave is a no-op', () {
    final speech = _FakeSpeech();
    final controller = MonitorEewAnnouncementController(
      speech,
      ForegroundEewAnnouncementGate(),
      (_) async => (scale: 4, isLocal: true),
    );
    controller.setActive(true);
    controller.setActive(false);
    controller.setActive(false);

    expect(speech.stops, 1);
    controller.dispose();
  });

  test(
    'a speech failure while the report is still current stops playback',
    () async {
      final speech = _FakeSpeech();
      final controller = MonitorEewAnnouncementController(
        speech,
        ForegroundEewAnnouncementGate(),
        (_) async => (scale: 4, isLocal: true),
        speechTimeout: Duration.zero,
      );
      controller.setActive(true);
      controller.update(
        _live(_alert(1)),
        languageTag: 'zh-TW',
        format: (_) => '所在地預估震度，四級。',
      );
      await _flush();

      expect(speech.stops, greaterThanOrEqualTo(2));
      controller.dispose();
    },
  );

  group('cancelled reports', () {
    test('a cancelled report is never announced', () async {
      final speech = _FakeSpeech();
      final controller = MonitorEewAnnouncementController(
        speech,
        ForegroundEewAnnouncementGate(),
        (_) async => (scale: 4, isLocal: true),
      );
      controller.setActive(true);
      controller.update(
        _live(_alert(1, status: 3)),
        languageTag: 'zh-TW',
        format: (_) => 'should not be said',
      );
      await _flush();

      expect(speech.spoken, isEmpty);
      expect(speech.stops, 0);
      controller.dispose();
    });

    test('a cancel for the alert being spoken cuts the phrase off and '
        'releases the held warning', () async {
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
        format: (_) => '震度四級',
      );
      await _flush();
      var displayed = false;
      await gate.submit(() async => displayed = true);
      final stopsBefore = speech.stops;

      controller.update(
        _live(_alert(2, status: 3)),
        languageTag: 'zh-TW',
        format: (_) => 'should not be said',
      );
      await _flush();

      expect(speech.spoken, ['zh-TW:震度四級']);
      expect(speech.stops, greaterThan(stopsBefore));
      expect(displayed, isTrue);
      controller.dispose();
    });

    test('a cancel for the spoken event stops it even while another alert '
        'stays up, and the other is not re-announced', () async {
      final speech = _FakeSpeech();
      final controller = MonitorEewAnnouncementController(
        speech,
        ForegroundEewAnnouncementGate(),
        (alert) async => (scale: alert.serial, isLocal: true),
      );
      controller.setActive(true);
      controller.update(
        RealtimeState(
          status: RealtimeStatus.live,
          data: [_alert(1, id: 'b')],
        ),
        languageTag: 'zh-TW',
        format: (estimate) => 'b${estimate.scale}',
      );
      await _flush();
      controller.update(
        RealtimeState(
          status: RealtimeStatus.live,
          data: [
            _alert(2, id: 'a'),
            _alert(1, id: 'b'),
          ],
        ),
        languageTag: 'zh-TW',
        format: (estimate) => 'a${estimate.scale}',
      );
      await _flush();
      expect(speech.spoken, ['zh-TW:b1', 'zh-TW:a2']);
      final stopsBefore = speech.stops;

      controller.update(
        RealtimeState(
          status: RealtimeStatus.live,
          data: [
            _alert(3, id: 'a', status: 3),
            _alert(1, id: 'b'),
          ],
        ),
        languageTag: 'zh-TW',
        format: (estimate) => 'again${estimate.scale}',
      );
      await _flush();

      expect(speech.stops, greaterThan(stopsBefore));
      expect(speech.spoken, ['zh-TW:b1', 'zh-TW:a2']);
      controller.dispose();
    });
  });

  group('which alert is spoken', () {
    test(
      'by default, the strongest of several — not the feed\'s first',
      () async {
        final speech = _FakeSpeech();
        final controller = MonitorEewAnnouncementController(
          speech,
          ForegroundEewAnnouncementGate(),
          (alert) async => (scale: alert.info.max, isLocal: false),
        );
        controller.setActive(true);
        controller.update(
          RealtimeState(
            status: RealtimeStatus.live,
            data: [
              _alert(1, id: 'weak', max: 3),
              _alert(1, id: 'strong'),
            ],
          ),
          languageTag: 'zh-TW',
          format: (estimate) => 'max${estimate.scale}',
        );
        await _flush();
        expect(speech.spoken, ['zh-TW:max6']);
        controller.dispose();
      },
    );

    test('the caller\'s ranking decides when it supplies one', () async {
      final speech = _FakeSpeech();
      final seen = <List<String>>[];
      final controller = MonitorEewAnnouncementController(
        speech,
        ForegroundEewAnnouncementGate(),
        (alert) async => (scale: alert.info.max, isLocal: false),
        primary: (alerts) {
          seen.add([for (final a in alerts) a.id]);
          return alerts.last;
        },
      );
      controller.setActive(true);
      controller.update(
        RealtimeState(
          status: RealtimeStatus.live,
          data: [
            _alert(1, id: 'gone', status: 3),
            _alert(1, id: 'a', max: 6),
            _alert(1, id: 'b', max: 2),
          ],
        ),
        languageTag: 'zh-TW',
        format: (estimate) => 'max${estimate.scale}',
      );
      await _flush();
      // Cancelled alerts never reach the ranking.
      expect(seen, [
        ['a', 'b'],
      ]);
      expect(speech.spoken, ['zh-TW:max2']);
      controller.dispose();
    });
  });
}
