/// The coast blink rewrites layer properties twice a second. These pin that it
/// stops while the map is behind another tab, picks up again on return, and
/// never restarts for a coast that has been taken off the map.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/tsunami_layer.dart';
import 'package:dpip/features/tsunami/domain/tsunami_report.dart';
import 'package:dpip/features/tsunami/domain/tsunami_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

const Map<String, dynamic> _predict = {
  'id': 'CWA-TSU11300301-2024-0403-081100',
  'sent': 1712103060000,
  'msgType': 'Issue',
  'no': 113003,
  'rep': '第1報',
  'type': '海嘯警報',
  'content': '…',
  'eq': {
    't': 1712102280000,
    'lon': 121.67,
    'lat': 23.77,
    'loc': '臺灣東部海域',
    'dep': 15.5,
    'mag': 7.3,
  },
  'data': {
    'type': 'predict',
    'area': [
      ['東部沿海地區', '宜蘭縣南澳鄉至臺東縣長濱鄉沿岸', '<1', 1712102340000, '黃色'],
    ],
  },
};

class _Repo implements TsunamiRepository {
  @override
  Future<Result<List<TsunamiBulletin>>> bulletins() async => const Ok([]);

  @override
  Future<Result<TsunamiReport>> report(String id) async =>
      Ok(TsunamiReport.decode(_predict));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One blink step is 500 ms, so this always crosses at least one.
const Duration _pastTick = Duration(milliseconds: 650);

Future<void> _wait() => Future<void>.delayed(_pastTick);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(RecordingMapController, TsunamiMapLayer)> show({
    bool hiddenFirst = false,
  }) async {
    final map = RecordingMapController();
    final layer = TsunamiMapLayer(_Repo());
    if (hiddenFirst) layer.onSurfaceVisibility(false);
    await layer.render(map);
    await layer.selectBulletin('x');
    return (map, layer);
  }

  testWidgets('hiding the map stops the blink and showing it resumes', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (map, layer) = await show();
      await _wait();
      expect(map.sentKeys, isNotEmpty);

      layer.onSurfaceVisibility(false);
      final hidden = map.sentKeys.length;
      await _wait();
      expect(map.sentKeys.length, hidden);

      layer.onSurfaceVisibility(true);
      await _wait();
      expect(map.sentKeys.length, greaterThan(hidden));

      layer.onStyleReset();
    });
  });

  testWidgets('a coast drawn while hidden starts blinking only once shown', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (map, layer) = await show(hiddenFirst: true);
      await _wait();
      expect(map.sentKeys, isEmpty);

      layer.onSurfaceVisibility(true);
      await _wait();
      expect(map.sentKeys, isNotEmpty);

      layer.onStyleReset();
    });
  });

  testWidgets('a removed coast does not blink when the map is shown again', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (map, layer) = await show();
      layer.onSurfaceVisibility(false);
      await layer.clear(map);
      final cleared = map.sentKeys.length;

      layer.onSurfaceVisibility(true);
      await _wait();
      expect(map.sentKeys.length, cleared);
    });
  });
}
