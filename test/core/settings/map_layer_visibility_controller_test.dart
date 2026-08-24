import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<MapLayerVisibilityController> controllerWith(
  Map<String, Object> initial,
) async {
  return MapLayerVisibilityController(SettingsStore.inMemory(initial));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts empty — every layer shown — when nothing was saved', () async {
    final controller = await controllerWith({});
    expect(controller.hiddenIds, isEmpty);
    expect(controller.isHidden('rts'), isFalse);
  });

  test('reads a previously saved hidden set', () async {
    final controller = await controllerWith({
      'map.layerHiddenIds': ['rts', 'lightning'],
    });
    expect(controller.isHidden('rts'), isTrue);
    expect(controller.isHidden('lightning'), isTrue);
    expect(controller.isHidden('radar'), isFalse);
  });

  test('setHidden persists, notifies, and is idempotent', () async {
    final controller = await controllerWith({});
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setHidden('rts', hidden: true);
    expect(controller.isHidden('rts'), isTrue);
    expect(notified, 1);

    // Hiding an already-hidden layer changes nothing.
    await controller.setHidden('rts', hidden: true);
    expect(notified, 1, reason: 'an unchanged state must not notify');

    // Showing it again persists the removal.
    await controller.setHidden('rts', hidden: false);
    expect(controller.isHidden('rts'), isFalse);
    expect(notified, 2);

    // A fresh controller reads the persisted value.
    final reloaded = await controllerWith({
      'map.layerHiddenIds': ['radar'],
    });
    expect(reloaded.isHidden('radar'), isTrue);
  });

  test('hiddenIds never leaks its internal set', () async {
    final controller = await controllerWith({
      'map.layerHiddenIds': ['rts'],
    });
    expect(() => controller.hiddenIds.add('radar'), throwsUnsupportedError);
    expect(controller.isHidden('radar'), isFalse);
  });

  test('unknown ids are tolerated', () async {
    // An id saved by one surface but not offered by another must be inert
    // there — surfaces resolve against their own layer sets.
    final controller = await controllerWith({
      'map.layerHiddenIds': ['not-a-layer'],
    });
    expect(controller.isHidden('not-a-layer'), isTrue);
    expect(controller.isHidden('rts'), isFalse);
  });
}
