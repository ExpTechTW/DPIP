import 'dart:math' as math;

import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_camera_fit.dart';
import 'package:dpip/features/earthquake/presentation/story_map_snapshot.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_story_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _report = EarthquakeReport(
  id: '115075-2026-1101-162007',
  longitude: 122.56,
  latitude: 23.9,
  location: '臺灣東部',
  depth: 19.0,
  magnitude: 5.6,
  time: 1793521200000,
  trem: 0,
  list: {},
);

StoryCameraLayout _layout(double hudTop) => storyCameraLayout(
  canvas: StoryMapSnapshot.canvas,
  safeTop: 56,
  safeBottom: 40,
  hud: Rect.fromLTRB(16, hudTop, 344, 592),
  footprint: const Rect.fromLTRB(-18, -18, 19, 18),
  gap: 8,
);

EarthquakeReport _withStations(Map<String, StationIntensity> stations) =>
    _report.copyWith(
      list: {'area': AreaIntensity(intensity: 4, town: stations)},
    );

Offset _mercatorPoint(double latitude, double longitude, StoryCamera camera) {
  double y(double latitude) {
    final s = math.sin(latitude * math.pi / 180);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }

  final world = 512 * math.pow(2, camera.zoom);
  return StoryMapSnapshot.canvas.center(Offset.zero) +
      Offset(
        (longitude - camera.target.longitude) * world / 360,
        (y(latitude) - y(camera.target.latitude)) * world,
      );
}

void main() {
  test('reserves the symbol box and breathing room within the map band', () {
    final layout = _layout(395);
    expect(layout.mapRegion, const Rect.fromLTRB(0, 56, 360, 395));
    expect(layout.anchorRegion, const Rect.fromLTRB(27, 82, 333, 369));
    expect(_layout(625).mapRegion.bottom, 600);
    expect(() => fitStoryCamera(_report, _layout(107)), throwsStateError);
  });

  test('FULL fits the offshore epicenter and both weaker extremes', () {
    const west = StationIntensity(
      longitude: 118.22,
      latitude: 24.43,
      intensity: 1,
    );
    const south = StationIntensity(
      longitude: 121.3,
      latitude: 21.84,
      intensity: 2,
    );
    const invalid = StationIntensity(longitude: 199, latitude: 0, intensity: 4);
    final report = _withStations({'west': west, 'south': south});
    final wide = _layout(395);
    final expandedHud = _layout(235);
    final normalCamera = fitStoryCamera(report, wide);
    final compactCamera = fitStoryCamera(report, expandedHud);
    expect(compactCamera.zoom, lessThan(normalCamera.zoom));
    for (final (camera, layout) in [
      (normalCamera, wide),
      (compactCamera, expandedHud),
    ]) {
      for (final (lat, lon) in [
        (report.latitude, report.longitude),
        (west.latitude, west.longitude),
        (south.latitude, south.longitude),
      ]) {
        expect(
          layout.anchorRegion
              .inflate(1e-7)
              .contains(_mercatorPoint(lat, lon, camera)),
          isTrue,
        );
      }
    }
    expect(
      fitStoryCamera(
        _withStations({'south': south, 'bad': invalid, 'west': west}),
        wide,
      ),
      normalCamera,
    );
  });

  test('caps zoom for zero and single nearby observations', () {
    final layout = _layout(395);
    final empty = fitStoryCamera(_report, layout);
    expect(empty.zoom, 7);
    expect(
      (_mercatorPoint(_report.latitude, _report.longitude, empty) -
              layout.anchorRegion.center)
          .distance,
      lessThan(0.001),
    );
    final one = fitStoryCamera(
      _withStations({
        'nearby': const StationIntensity(
          longitude: 122.5,
          latitude: 23.88,
          intensity: 2,
        ),
      }),
      layout,
    );
    expect(one.zoom, 7);
  });

  test(
    'keeps minimum zoom for an impossible span and rejects bad epicenter',
    () {
      final layout = _layout(395);
      final wide = _withStations({
        'distant': const StationIntensity(
          longitude: -40,
          latitude: 23,
          intensity: 1,
        ),
      });
      expect(fitStoryCamera(wide, layout).zoom, 2);
      expect(
        () => fitStoryCamera(_report.copyWith(latitude: double.nan), layout),
        throwsFormatException,
      );
    },
  );

  testWidgets('measures wrapped locations at the fixed Story text size', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = StoryMapSnapshot.canvas;
    addTearDown(tester.view.reset);
    final layouts = <StoryCameraLayout>[];
    Future<Rect> render(String location, double scale) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Material(
            child: Center(
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: EarthquakeShareStoryCard(
                  report: _report.copyWith(location: location),
                  showSafeAreaGuides: true,
                  onMapLayout: layouts.add,
                ),
              ),
            ),
          ),
        ),
      );
      final card = tester.getRect(find.byType(EarthquakeShareStoryCard));
      final hud = tester.getRect(find.byType(ClipRRect)).shift(-card.topLeft);
      expect(layouts.last.mapRegion.bottom, hud.top);
      expect(hud.bottom, 592);
      expect(layouts.last.mapRegion.top, 56);
      return hud;
    }

    final oneLine = await render('臺灣東部', 1);
    await render('臺灣東部', 1);
    expect(layouts, hasLength(1));
    final twoLines = await render('臺灣東部\n外海', 1);
    expect(twoLines.height, greaterThan(oneLine.height));
    final long = List.filled(10, '臺灣東部外海').join();
    final standard = await render(long, 1);
    final scaled = await render(long, 3);
    expect(scaled.height, greaterThan(twoLines.height));
    expect(scaled, standard);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(long));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(layouts.last.anchorRegion.isEmpty, isFalse);
    await render(List.filled(40, '臺灣東部外海').join(), 3);
    expect(layouts.last.anchorRegion.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });
}
