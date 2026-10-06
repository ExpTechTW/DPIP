/// [DpmSheet] picks a body from whichever sub-layer holds a selection, and
/// each body renders the loaded detail (or a loading placeholder when the
/// tap has not resolved yet). Empty hours, an unknown restroom grade, and a
/// missing category collapse to nothing.
library;

import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/features/map/presentation/widgets/dpm_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnusedRepo implements DisasterMapRepository {
  int cancels = 0;

  @override
  Future<Never> aedDetail(int id) => Future.error(StateError('unused'));

  @override
  void cancelTilePrefetch() => cancels++;

  @override
  Future<void> prefetchTiles({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) async {}

  @override
  Future<Never> restroomDetail(int id) => Future.error(StateError('unused'));

  @override
  Future<Never> shelterDetail(int id) => Future.error(StateError('unused'));

  @override
  String tileUrl(String layer) => 'https://example.invalid/$layer/{z}/{x}/{y}';
}

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: home),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _UnusedRepo repo;
  late DisasterMapLayer layer;

  setUp(() {
    repo = _UnusedRepo();
    layer = DisasterMapLayer(repo);
  });

  tearDown(() => layer.close());

  testWidgets('nothing selected shows the empty hint', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      _app(
        DpmSheet(
          aed: layer.aed,
          restroom: layer.restroom,
          shelter: layer.shelter,
          onClose: layer.close,
        ),
      ),
    );
    await tester.pump();
    expect(find.text(l10n.dpmSheetEmpty), findsOneWidget);
  });

  testWidgets('an AED selection with no detail shows the preview name', (
    tester,
  ) async {
    layer.aed.selectionId.value = 7;
    layer.aed.previewName.value = '車站 AED';
    layer.aed.previewPlace.value = '大廳';
    await tester.pumpWidget(
      _app(
        DpmSheet(
          aed: layer.aed,
          restroom: layer.restroom,
          shelter: layer.shelter,
          onClose: layer.close,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('車站 AED'), findsOneWidget);
    expect(find.text('大廳'), findsOneWidget);
  });

  testWidgets('a loaded AED lists address, hours, and the emergency phone', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    layer.aed.selectionId.value = 3;
    layer.aed.setDetail(
      const AedDetail(
        id: 3,
        aedId: 'A-3',
        name: '市府 AED',
        city: '臺北市',
        district: '中正區',
        category: '公共',
        type: '固定',
        place: '一樓',
        lat: 25.04,
        lng: 121.51,
        address: '市府路 1 號',
        description: '靠柱',
        placeDesc: '服務台旁',
        weekdayStart: '08:00',
        weekdayEnd: '17:00',
        saturdayStart: '09:00',
        sundayEnd: '12:00',
        openRemark: '國定假日休',
        emergencyPhone: '02-1234',
      ),
    );
    await tester.pumpWidget(
      _app(
        DpmSheet(
          aed: layer.aed,
          restroom: layer.restroom,
          shelter: layer.shelter,
          onClose: layer.close,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('市府路 1 號'), findsOneWidget);
    expect(find.text('臺北市 中正區'), findsOneWidget);
    expect(find.text('08:00 – 17:00'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('02-1234'), findsOneWidget);
    expect(find.text(l10n.aedEmergencyPhone), findsOneWidget);
  });

  testWidgets('restroom and shelter bodies name type, grade, and capacity', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    layer.restroom.selectionId.value = 1;
    layer.restroom.setDetail(
      const RestroomDetail(
        name: '公園廁所',
        address: '公園路',
        latitude: 25,
        longitude: 121,
        type: 4,
        type2: 2,
        typegrade: 3,
      ),
    );
    await tester.pumpWidget(
      _app(
        DpmSheet(
          aed: layer.aed,
          restroom: layer.restroom,
          shelter: layer.shelter,
          onClose: layer.close,
        ),
      ),
    );
    await tester.pump();
    expect(find.text(l10n.restroomTypeAccessible), findsWidgets);
    expect(find.text(l10n.restroomCategoryPark), findsOneWidget);
    expect(find.text(l10n.restroomGradeExcellent), findsOneWidget);

    for (final grade in [2, 1, -1, 0]) {
      layer.restroom.setDetail(
        RestroomDetail(
          name: '公園廁所',
          address: '公園路',
          type: 0,
          type2: 99,
          typegrade: grade,
        ),
      );
      await tester.pump();
    }
    expect(find.text('公園廁所'), findsOneWidget);

    layer.restroom.clearSelection();
    layer.shelter.selectionId.value = 9;
    layer.shelter.setDetail(
      const ShelterDetail(
        id: 9,
        name: '活動中心',
        capacity: 120,
        category: ['地震', '風災'],
        indoor: true,
        outdoor: false,
        vulnerableOk: true,
        lat: 24.1,
        lng: 120.6,
        address: '中山路',
      ),
    );
    await tester.pump();
    expect(find.text('活動中心'), findsOneWidget);
    expect(find.text(l10n.shelterCapacityValue(120)), findsOneWidget);
    expect(find.text('地震, 風災'), findsOneWidget);
    expect(find.text(l10n.dpmYes), findsWidgets);
    expect(find.text(l10n.dpmNo), findsOneWidget);
  });

  test(
    'labels cover every sub-layer and restroom type, including unknowns',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(DisasterMapLayer.layerLabel(l10n, 'aed'), l10n.mapLayerAed);
      expect(
        DisasterMapLayer.layerLabel(l10n, 'restroom'),
        l10n.mapLayerRestroom,
      );
      expect(
        DisasterMapLayer.layerLabel(l10n, 'shelter'),
        l10n.mapLayerShelter,
      );
      expect(DisasterMapLayer.layerLabel(l10n, 'other'), 'other');
      expect(
        DisasterMapLayer.layerTooltip(l10n, 'aed'),
        l10n.disasterMapOverlayAedTooltip,
      );
      expect(
        DisasterMapLayer.layerTooltip(l10n, 'restroom'),
        l10n.disasterMapOverlayRestroomTooltip,
      );
      expect(
        DisasterMapLayer.layerTooltip(l10n, 'shelter'),
        l10n.disasterMapOverlayShelterTooltip,
      );
      expect(DisasterMapLayer.layerTooltip(l10n, 'other'), isEmpty);
      for (var type = 0; type <= 8; type++) {
        DisasterMapLayer.restroomTypeLabel(l10n, type);
      }
      expect(DisasterMapLayer.restroomTypeLabel(l10n, 99), isEmpty);
    },
  );

  testWidgets('the legend lists AED, every restroom kind, and shelter', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_app(Builder(builder: layer.buildLegend)));
    expect(find.text(l10n.mapLayerAed), findsOneWidget);
    expect(find.text(l10n.restroomTypeFemale), findsOneWidget);
    expect(find.text(l10n.restroomTypeFamily), findsOneWidget);
    expect(find.text(l10n.mapLayerShelter), findsOneWidget);
  });

  test('hiding the last visible sub-layer cancels prefetch', () {
    layer.aed.selectionId.value = 1;
    layer.setSubLayerVisible(layer.aed, false);
    layer.setSubLayerVisible(layer.restroom, false);
    layer.setSubLayerVisible(layer.shelter, false);
    expect(layer.shelter.selectionId.value, isNull);
    expect(repo.cancels, 1);
    layer.setSubLayerVisible(layer.shelter, false);
    expect(repo.cancels, 1);
    layer.setSubLayerVisible(layer.aed, true);
    expect(layer.aed.visible.value, isTrue);
  });
}
