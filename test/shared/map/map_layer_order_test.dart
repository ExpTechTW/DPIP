import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [MapLayer] for ordering tests — only [id] matters.
class _FakeLayer implements MapLayer {
  _FakeLayer(this.id);

  @override
  final String id;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  List<String> ids(List<MapLayer> layers) => [for (final l in layers) l.id];

  final radar = _FakeLayer('radar');
  final rain = _FakeLayer('rain');
  final typhoon = _FakeLayer('typhoon');
  final layers = [radar, rain, typhoon];

  group('orderedLayers', () {
    test('an empty surface yields an empty list', () {
      expect(orderedLayers(const [], const []), isEmpty);
    });

    test('an empty saved order keeps the declared order', () {
      expect(ids(orderedLayers(layers, const [])), [
        'radar',
        'rain',
        'typhoon',
      ]);
    });

    test('a partial order moves those layers first, rest keep their order', () {
      expect(ids(orderedLayers(layers, ['typhoon'])), [
        'typhoon',
        'radar',
        'rain',
      ]);
    });

    test('a full order is honoured exactly', () {
      expect(ids(orderedLayers(layers, ['rain', 'typhoon', 'radar'])), [
        'rain',
        'typhoon',
        'radar',
      ]);
    });

    test('a layer added after the order was saved appends at the bottom', () {
      // 'dpm' was introduced later and never placed in the saved order.
      final grown = [...layers, _FakeLayer('dpm')];
      expect(ids(orderedLayers(grown, ['typhoon'])), [
        'typhoon',
        'radar',
        'rain',
        'dpm',
      ]);
    });

    test('a stale id is ignored without dropping any layer', () {
      expect(ids(orderedLayers(layers, ['gone', 'rain', 'radar'])), [
        'rain',
        'radar',
        'typhoon',
      ]);
    });

    test('duplicate ids in the order count once', () {
      expect(ids(orderedLayers(layers, ['rain', 'rain', 'typhoon', 'rain'])), [
        'rain',
        'typhoon',
        'radar',
      ]);
    });
  });
}
