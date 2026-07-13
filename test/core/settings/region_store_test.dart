import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RegionStore> makeStore([List<String>? saved]) async {
    SharedPreferences.setMockInitialValues(
      saved == null ? {} : {'home.savedRegionCodes': saved},
    );
    return RegionStore(await SharedPreferences.getInstance());
  }

  test(
    'areas are [nationwide, current, ...saved]; default selects 所在地',
    () async {
      final store = await makeStore(['100', '900']);
      expect(store.count, 4);
      expect(store.areas[0], isA<NationwideArea>());
      expect(store.areas[1], isA<CurrentArea>());
      expect((store.areas[2] as SavedArea).code, '100');
      expect(store.selectedIndex, 1); // 所在地
      expect(store.selected, isA<CurrentArea>());
    },
  );

  test(
    'current code is set per session, not persisted as a saved region',
    () async {
      final store = await makeStore();
      expect(store.currentCode, isNull);
      store.setCurrentCode('100');
      expect(store.currentCode, '100');
      expect((store.areas[1] as CurrentArea).code, '100');
      expect(store.savedCodes, isEmpty);
    },
  );

  test('addSaved caps at 3, dedups, and persists codes', () async {
    final store = await makeStore();
    expect(store.addSaved('100'), isTrue);
    expect(store.addSaved('100'), isFalse); // duplicate
    expect(store.addSaved('200'), isTrue);
    expect(store.addSaved('300'), isTrue);
    expect(store.addSaved('400'), isFalse); // at the cap
    expect(store.savedCodes, ['100', '200', '300']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('home.savedRegionCodes'), ['100', '200', '300']);
  });

  test('removeSaved drops the code and keeps the selection valid', () async {
    final store = await makeStore(['100', '200', '300']);
    store.select(4); // the last saved (300)
    expect(store.selectedIndex, 4);
    store.removeSaved('300');
    expect(store.savedCodes, ['100', '200']);
    expect(store.selectedIndex, 3); // clamped to the new last
  });

  test(
    'removeSaved before the selection keeps the same region selected',
    () async {
      final store = await makeStore(['100', '200', '300']);
      store.select(3); // 200 (index 3)
      expect((store.selected as SavedArea).code, '200');
      store.removeSaved('100'); // an area before the selected one
      expect(store.savedCodes, ['200', '300']);
      // Selection tracks 200 down to index 2, not silently onto 300.
      expect((store.selected as SavedArea).code, '200');
    },
  );

  test('select / next / previous stay in range', () async {
    final store = await makeStore(['100']); // count 3
    store.select(0);
    store.previous();
    expect(store.selectedIndex, 0); // no-op at the start
    store.next();
    expect(store.selectedIndex, 1);
    store.select(99);
    expect(store.selectedIndex, 2); // clamped
  });
}
