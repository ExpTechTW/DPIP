import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<MapLayerOrderController> controllerWith(
  Map<String, Object> initial,
) async {
  return MapLayerOrderController(SettingsStore.inMemory(initial));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts empty when nothing was saved', () async {
    final controller = await controllerWith({});
    expect(controller.order, isEmpty);
  });

  test('reads a previously saved order', () async {
    final controller = await controllerWith({
      'map.layerOrder': ['rain', 'radar'],
      'map.layerCategoryOrder': ['radar', 'typhoon'],
    });
    expect(controller.order, ['rain', 'radar']);
    expect(controller.categoryOrder, ['radar', 'typhoon']);
  });

  test('setOrder persists and notifies, and is idempotent', () async {
    final controller = await controllerWith({});
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setOrder(['typhoon', 'radar']);
    expect(controller.order, ['typhoon', 'radar']);
    expect(notified, 1);

    await controller.setOrder(['typhoon', 'radar']);
    expect(notified, 1, reason: 'an unchanged order must not notify');

    // A fresh controller reads the persisted value.
    final reloaded = await controllerWith({'map.layerOrder': []});
    await reloaded.setOrder(['typhoon', 'radar']);
    expect(controller.order, reloaded.order);
  });

  test('setOrder never leaks its input list', () async {
    final controller = await controllerWith({});
    final input = ['radar', 'rain'];
    await controller.setOrder(input);
    input.add('typhoon');
    expect(controller.order, ['radar', 'rain']);
  });

  test('reset clears the saved order and notifies once', () async {
    final controller = await controllerWith({
      'map.layerOrder': ['rain', 'radar'],
    });
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.reset();
    expect(controller.order, isEmpty);
    expect(notified, 1);

    // Resetting an already-empty order is a no-op.
    await controller.reset();
    expect(notified, 1);

    final reloaded = await controllerWith({});
    expect(reloaded.order, isEmpty);
  });

  test('category order starts empty and persists idempotently', () async {
    final controller = await controllerWith({});
    expect(controller.categoryOrder, isEmpty);
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setCategoryOrder(['radar', 'typhoon']);
    expect(controller.categoryOrder, ['radar', 'typhoon']);
    expect(notified, 1);

    await controller.setCategoryOrder(['radar', 'typhoon']);
    expect(notified, 1, reason: 'an unchanged order must not notify');

    final reloaded = await controllerWith({});
    await reloaded.setCategoryOrder(['radar', 'typhoon']);
    expect(controller.categoryOrder, reloaded.categoryOrder);
  });

  test('setCategoryOrder never leaks its input list', () async {
    final controller = await controllerWith({});
    final input = ['radar'];
    await controller.setCategoryOrder(input);
    input.add('typhoon');
    expect(controller.categoryOrder, ['radar']);
  });

  test('reset clears both orders and notifies once', () async {
    final controller = await controllerWith({
      'map.layerOrder': ['rain', 'radar'],
      'map.layerCategoryOrder': ['radar', 'typhoon'],
    });
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.reset();
    expect(controller.order, isEmpty);
    expect(controller.categoryOrder, isEmpty);
    expect(notified, 1);

    // Resetting an already-empty pair is a no-op.
    await controller.reset();
    expect(notified, 1);

    final reloaded = await controllerWith({});
    expect(reloaded.order, isEmpty);
    expect(reloaded.categoryOrder, isEmpty);
  });
}
