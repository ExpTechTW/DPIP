import 'package:dpip/features/notification/domain/notify_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // [eew, monitor, report, intensity, thunderstorm, weatherAdvisory,
  //  evacuation, tsunami, announcement]
  const wire = [1, 2, 0, 1, 1, 0, 1, 0, 1];

  test('fromWire maps each channel to its option index and kind', () {
    final s = NotifySettings.fromWire(wire);
    expect(s.optionOf(NotifyChannel.eew), 1);
    expect(s.kindOf(NotifyChannel.eew), NotifyOptionKind.localIntensity1);
    expect(s.kindOf(NotifyChannel.monitor), NotifyOptionKind.all);
    expect(s.kindOf(NotifyChannel.tsunami), NotifyOptionKind.tsunamiWarning);
    expect(s.kindOf(NotifyChannel.announcement), NotifyOptionKind.all);
  });

  test('fromWire rejects a wrong-length list', () {
    expect(
      () => NotifySettings.fromWire(const [0, 1, 2]),
      throwsFormatException,
    );
  });

  test('fromWire clamps an out-of-range index into the option list', () {
    final s = NotifySettings.fromWire(const [9, 0, 0, 0, 0, 0, 0, 0, 0]);
    expect(s.optionOf(NotifyChannel.eew), 2); // eew has 3 options → max 2
  });

  test('withChannel returns a copy, leaving the original unchanged', () {
    final s = NotifySettings.fromWire(wire);
    final updated = s.withChannel(NotifyChannel.eew, 2);
    expect(updated.optionOf(NotifyChannel.eew), 2);
    expect(s.optionOf(NotifyChannel.eew), 1);
  });

  test('optionsFor gives each channel its expected choices', () {
    expect(optionsFor(NotifyChannel.eew).length, 3);
    expect(
      optionsFor(NotifyChannel.eew).first,
      NotifyOptionKind.localIntensity4,
    );
    expect(optionsFor(NotifyChannel.monitor), [
      NotifyOptionKind.off,
      NotifyOptionKind.localIntensity1,
      NotifyOptionKind.all,
    ]);
    expect(optionsFor(NotifyChannel.thunderstorm).length, 2);
    expect(optionsFor(NotifyChannel.tsunami), [
      NotifyOptionKind.tsunamiWarning,
      NotifyOptionKind.tsunamiAll,
    ]);
    expect(optionsFor(NotifyChannel.announcement), [
      NotifyOptionKind.off,
      NotifyOptionKind.all,
    ]);
  });

  group('notifyOptionsForDisplay', () {
    test('is optionsFor reversed, each entry keeping its wire index', () {
      for (final channel in NotifyChannel.values) {
        final wireOptions = optionsFor(channel);
        final display = notifyOptionsForDisplay(channel);
        expect(display.length, wireOptions.length);
        for (final (displayPos, entry) in display.indexed) {
          final (wireIndex, kind) = entry;
          // Position i from the end of wire order is position i from the
          // start of display order.
          final expectedWireIndex = wireOptions.length - 1 - displayPos;
          expect(wireIndex, expectedWireIndex);
          expect(kind, wireOptions[wireIndex]);
        }
      }
    });

    test('puts off last and the broadest option first, matching legacy', () {
      // "接收全部/local" first, "關閉" last — the reverse of wire order (which
      // has to keep off at index 0 for channels that carry it, per the server
      // contract), matching the legacy app's hand-built option lists.
      expect(notifyOptionsForDisplay(NotifyChannel.monitor).map((e) => e.$2), [
        NotifyOptionKind.all,
        NotifyOptionKind.localIntensity1,
        NotifyOptionKind.off,
      ]);
      expect(
        notifyOptionsForDisplay(NotifyChannel.thunderstorm).map((e) => e.$2),
        [NotifyOptionKind.weatherLocal, NotifyOptionKind.off],
      );
      expect(
        notifyOptionsForDisplay(NotifyChannel.announcement).map((e) => e.$2),
        [NotifyOptionKind.all, NotifyOptionKind.off],
      );
      expect(notifyOptionsForDisplay(NotifyChannel.eew).map((e) => e.$2), [
        NotifyOptionKind.all,
        NotifyOptionKind.localIntensity1,
        NotifyOptionKind.localIntensity4,
      ]);
      expect(notifyOptionsForDisplay(NotifyChannel.tsunami).map((e) => e.$2), [
        NotifyOptionKind.tsunamiAll,
        NotifyOptionKind.tsunamiWarning,
      ]);
    });

    test('tapping the first displayed row for monitor sends wire value 2', () {
      // Regression: display order must not leak into the value sent to the
      // server — "接收全部" is shown first but its wire index is still 2.
      final first = notifyOptionsForDisplay(NotifyChannel.monitor).first;
      expect(first, (2, NotifyOptionKind.all));
    });
  });
}
