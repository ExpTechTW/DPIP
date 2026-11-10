import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/features/earthquake/data/eew_ml_max_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source extends RealtimeSource<List<Eew>> {
  _Source(this.alerts);

  final List<Eew> alerts;

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(alerts);

  @override
  DateTime? timestampOf(List<Eew> value) => null;
}

class _Model implements MlIntensityEstimator {
  _Model({required this.ready, this.levels});

  @override
  bool ready;
  final Map<String, int>? levels;
  int prepareCalls = 0;

  @override
  Future<bool> prepare() async {
    prepareCalls++;
    return ready;
  }

  @override
  Future<Map<String, int>?> townLevels(EewInfo info) async => levels;
}

Eew _alert({int max = 7, int status = 0}) => Eew(
  agency: 'cwa',
  id: 'test',
  serial: 1,
  status: status,
  isFinal: false,
  info: EewInfo(
    time: 1700000000000,
    longitude: 121.5,
    latitude: 23.5,
    depth: 10,
    magnitude: 6,
    location: 'Test',
    max: max,
  ),
);

void main() {
  test('replaces the wire maximum with the ML nationwide maximum', () async {
    final model = _Model(ready: true, levels: {'100': 3, '630': 5, '970': 1});
    final result = await EewMlMaxSource(
      _Source([_alert(max: 7)]),
      model,
    ).fetch();

    expect(result.valueOrNull!.single.info.max, 5);
  });

  test('publishes immediately and starts loading an unready model', () async {
    final model = _Model(ready: false, levels: {'100': 5});
    final result = await EewMlMaxSource(
      _Source([_alert(max: 7)]),
      model,
    ).fetch();

    expect(result.valueOrNull!.single.info.max, 7);
    expect(model.prepareCalls, 1);
  });

  test('keeps the wire maximum when ML cannot score the solution', () async {
    final model = _Model(ready: true);
    final result = await EewMlMaxSource(
      _Source([_alert(max: 7)]),
      model,
    ).fetch();

    expect(result.valueOrNull!.single.info.max, 7);
  });

  test('does not attach an estimate to a cancelled warning', () async {
    final model = _Model(ready: true, levels: {'100': 5});
    final result = await EewMlMaxSource(
      _Source([_alert(max: 7, status: 3)]),
      model,
    ).fetch();

    expect(result.valueOrNull!.single.info.max, 7);
  });
}
