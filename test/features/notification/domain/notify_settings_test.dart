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
}
