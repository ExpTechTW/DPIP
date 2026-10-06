/// Every astronomy page names the township it computed for. With no selection
/// and no GPS fix that name is the nearest town to the documented fallback,
/// not a blank.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/observer_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _taipei = Town(
  code: '6300100',
  city: '臺北',
  town: '中正',
  lat: 25.03,
  lng: 121.56,
  cityLevel: '市',
  townLevel: '區',
);

const _hualien = Town(
  code: '1001502',
  city: '花蓮',
  town: '吉安',
  lat: 23.96,
  lng: 121.56,
  cityLevel: '縣',
  townLevel: '鄉',
);

void main() {
  testWidgets('falls back to the nearest township when nothing is selected', (
    tester,
  ) async {
    late Town? seen;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TownDirectory>.value(
            value: const TownDirectory({
              '6300100': _taipei,
              '1001502': _hualien,
            }),
          ),
          ChangeNotifierProvider(
            create: (_) => RegionStore(SettingsStore.inMemory()),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              seen = observerTown(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(seen?.code, '6300100');
  });

  testWidgets('an empty directory yields no town', (tester) async {
    late Town? seen;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TownDirectory>.value(value: const TownDirectory({})),
          ChangeNotifierProvider(
            create: (_) => RegionStore(SettingsStore.inMemory()),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              seen = observerTown(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(seen, isNull);
  });
}
