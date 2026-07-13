import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/ntp_time_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

void main() {
  final device = DateTime.utc(2026, 1, 1, 0, 0, 0);

  test('uses the primary host, applying its offset to device time', () async {
    final calls = <String>[];
    final source = NtpTimeSource(
      hosts: const ['primary', 'backup'],
      clock: _FixedClock(device),
      query: (host, _) async {
        calls.add(host);
        return const Duration(seconds: 2);
      },
    );

    final result = await source.serverTimeMs();

    expect(calls, ['primary'], reason: 'backup not consulted on success');
    expect(
      result.valueOrNull,
      device.add(const Duration(seconds: 2)).millisecondsSinceEpoch,
    );
  });

  test('falls back to the backup host when the primary throws', () async {
    final calls = <String>[];
    final source = NtpTimeSource(
      hosts: const ['primary', 'backup'],
      clock: _FixedClock(device),
      query: (host, _) async {
        calls.add(host);
        if (host == 'primary') throw Exception('primary down');
        return const Duration(seconds: 1);
      },
    );

    final result = await source.serverTimeMs();

    expect(calls, ['primary', 'backup']);
    expect(
      result.valueOrNull,
      device.add(const Duration(seconds: 1)).millisecondsSinceEpoch,
    );
  });

  test('every host failing yields an Err', () async {
    final source = NtpTimeSource(
      hosts: const ['a', 'b'],
      query: (_, _) async => throw Exception('down'),
    );

    final result = await source.serverTimeMs();

    expect(result.isOk, isFalse);
  });

  test('exposes ExpTech primary and Apple backup by default', () {
    expect(NtpTimeSource.primaryHost, 'time.exptech.com.tw');
    expect(NtpTimeSource.backupHost, 'time.apple.com');
  });
}
