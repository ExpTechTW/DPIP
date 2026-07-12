import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/data/eew_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEewRepository implements EewRepository {
  Result<List<Eew>> result = const Ok(<Eew>[]);

  @override
  Future<Result<List<Eew>>> activeEews() async => result;
}

Eew _eew({int serial = 1}) => Eew(
  agency: 'cwa',
  id: '113000',
  serial: serial,
  status: 0,
  isFinal: false,
  info: const EewInfo(
    time: 1700000000000,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6.0,
    location: 'Test',
    max: 4,
  ),
);

void main() {
  late _FakeEewRepository repository;
  late EewRealtimeSource source;

  setUp(() {
    repository = _FakeEewRepository();
    source = EewRealtimeSource(repository);
  });

  test('fetch passes the repository Result through unchanged', () async {
    repository.result = Ok([_eew()]);
    final ok = await source.fetch();
    expect(ok.valueOrNull, hasLength(1));

    repository.result = const Err(TimeoutFailure('slow'));
    final err = await source.fetch();
    expect(err.failureOrNull, isA<TimeoutFailure>());
  });

  test('timestampOf is null → the channel uses fetch-freshness', () {
    expect(source.timestampOf([_eew()]), isNull);
  });

  test('sameData compares alert content, not list identity', () {
    expect(source.sameData(const [], const []), isTrue);
    expect(source.sameData([_eew(serial: 1)], [_eew(serial: 1)]), isTrue);
    expect(source.sameData([_eew(serial: 1)], [_eew(serial: 2)]), isFalse);
    expect(source.sameData(const [], [_eew()]), isFalse);
  });
}
