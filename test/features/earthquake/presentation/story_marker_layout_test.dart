import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_marker_layout.dart';
import 'package:dpip/features/earthquake/presentation/story_observation_clustering.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_story_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _canvas = Rect.fromLTWH(0, 0, 360, 640);
const _report = EarthquakeReport(
  id: '115000-2026-0909-192104',
  longitude: 120.76,
  latitude: 24.54,
  location: '苗栗縣西湖鄉',
  depth: 11.1,
  magnitude: 2.7,
  time: 1788956464000,
  trem: 0,
  list: {},
);
final _icon = StoryMarkerFootprint(icon: const Size.square(22));

void main() {
  test('component bounds preserve the unused corners of the envelope', () {
    final footprint = StoryMarkerFootprint(
      icon: const Size.square(22),
      badge: const Size(24, 13),
    );
    expect(footprint.components, [
      const Rect.fromLTRB(-11, -18, 11, 4),
      const Rect.fromLTRB(-5, 5, 19, 18),
    ]);
    expect(footprint.envelope, const Rect.fromLTRB(-11, -18, 19, 18));

    const first = Offset(100, 100);
    const second = Offset(80, 124);
    expect(_place([(anchor: first, footprint: footprint), _at(second)]), [
      first,
      second,
    ]);
  });

  test('a single unblocked observation stays at its projected anchor', () {
    const point = Offset(123.5, 212.25);
    expect(_place([_at(point)]), [point]);
  });

  test('legend avoids original points, connectors and rendered components', () {
    const safe = Rect.fromLTWH(16, 57, 328, 543);
    const legend = Size(100, 24);
    final placement = layoutStoryLegend(
      legend: legend,
      safeRegion: safe,
      occupied: const [Rect.fromLTWH(130, 57, 102, 24)],
      observations: const [Offset(42, 74)],
      connectors: const [StoryConnector(Offset(256, 54), Offset(267, 90))],
    );
    expect(placement, const Rect.fromLTWH(16, 78, 100, 24));
    expect(
      layoutStoryLegend(
        legend: legend,
        safeRegion: safe,
        occupied: const [safe],
        observations: const [],
        connectors: const [],
      ),
      isNull,
    );
  });

  test('the canvas contains both components at the right and bottom edges', () {
    final wide = StoryMarkerFootprint(
      icon: const Size.square(22),
      badge: const Size(34, 14),
    );
    const anchor = Offset(359, 639);
    final center = _place([(anchor: anchor, footprint: wide)]).single;
    final bounds = wide.envelope.shift(center);
    expect(bounds.right, _canvas.right);
    expect(bounds.bottom, _canvas.bottom);

    const farOutside = Offset(-120, 200);
    expect(_place([_at(farOutside)]).single, const Offset(11, 200));
  });

  test('epicenter and HUD take priority over an observation', () {
    const epicenter = Rect.fromLTWH(162, 162, 36, 36);
    const hud = Rect.fromLTRB(16, 202, 344, 592);
    const anchor = Offset(180, 184);
    final center = _place([_at(anchor)], epicenter: epicenter, hud: hud).single;
    final icon = _icon.envelope.shift(center);
    expect(icon.overlaps(epicenter), isFalse);
    expect(icon.overlaps(hud), isFalse);
    expect((center - anchor).distance, lessThanOrEqualTo(48));
  });

  test('dense conflicts retain all markers within the displacement budget', () {
    const anchor = Offset(180, 180);
    final anchors = List.generate(20, (_) => _at(anchor));
    final centers = _place(anchors);
    expect(centers, hasLength(anchors.length));
    expect(centers.first, anchor);
    expect(centers.toSet().length, greaterThan(1));
    for (final center in centers) {
      expect(
        (center - anchor).distance,
        lessThanOrEqualTo(storyMarkerDisplacementLimit + 1e-9),
      );
    }
    expect(_place(anchors), centers);
  });

  test(
    'displaced marker connects to its anchor without crossing a neighbor',
    () {
      const anchor = Offset(180, 180);
      const neighbor = Offset(220, 180);
      const epicenter = Rect.fromLTWH(162, 162, 36, 36);
      final [first, moved] = _place([
        _at(neighbor),
        _at(anchor),
      ], epicenter: epicenter);
      expect(first, neighbor);
      expect(moved, isNot(anchor));
      expect(
        StoryConnector(
          anchor,
          moved,
        ).intersects(_icon.envelope.shift(neighbor)),
        isFalse,
      );
    },
  );

  test(
    'connector checks detect stroke near a badge and interior crossings',
    () {
      const line = StoryConnector(Offset(0, 10), Offset(20, 10));
      expect(line.intersects(const Rect.fromLTWH(4, 10.5, 6, 4)), isTrue);
      expect(line.intersects(const Rect.fromLTWH(4, 11, 6, 4)), isFalse);
      expect(line.intersects(const Rect.fromLTWH(22, 8, 3, 4)), isFalse);
      expect(
        line.crosses(const StoryConnector(Offset(8, 0), Offset(8, 20))),
        isTrue,
      );
      expect(
        line.crosses(const StoryConnector(Offset(4, 10), Offset(8, 10))),
        isTrue,
      );
      expect(
        line.crosses(const StoryConnector(Offset(20, 10), Offset(20, 20))),
        isFalse,
      );
    },
  );

  testWidgets('the count has its measured footprint clear of its own icon', (
    tester,
  ) async {
    _setViewport(tester);
    final map = await _image(tester);
    final icon = find.byWidgetPredicate(
      (w) => w is IntensityBadge && w.size == 22,
    );
    const point = Offset(345, 200);
    for (final count in [1, 9, 10, 100]) {
      final markers = [
        for (var i = 0; i < count; i++)
          _marker('station-$i', point, intensity: 3),
      ];
      double? unscaledWidth;
      for (final scale in [1.0, 1.3, 1.6, 2.0, 3.0]) {
        await _pump(tester, map, markers, scale: scale, useD75Compact: true);
        final card = tester.getRect(find.byType(EarthquakeShareStoryCard));
        final iconRect = tester.getRect(icon);
        expect(iconRect.size, const Size.square(22));
        if (count == 1) {
          expect(_countBadge('$count'), findsNothing);
          continue;
        }
        final badge = tester.getRect(_countBadge('$count'));
        final label = tester.getRect(find.text('$count'));
        expect(badge.right, iconRect.right + 8);
        expect(badge.top, iconRect.bottom + 1);
        expect(badge.overlaps(iconRect), isFalse);
        expect(
          badge.width,
          label.width + 8,
        ); // 3 px padding + 1 px border per side.
        expect(badge.height, label.height + 4);
        expect(badge.right, lessThanOrEqualTo(card.right));
        expect(badge.overlaps(tester.getRect(find.byType(ClipRRect))), isFalse);
        if (unscaledWidth == null) {
          unscaledWidth = badge.width;
        } else {
          expect(badge.width, unscaledWidth);
        }
      }
    }
  });

  testWidgets(
    'all locales fit two fixed-size legend lines without hiding the map',
    (tester) async {
      _setViewport(tester);
      final map = await _image(tester);
      final markers = [
        _marker('in the first legend slot', const Offset(22, 65), intensity: 4),
        _marker('elsewhere', const Offset(180, 220), intensity: 3),
      ];
      final icon = find.byWidgetPredicate(
        (widget) => widget is IntensityBadge && widget.size == 22,
      );
      for (final locale in appSupportedLocales) {
        await _pump(
          tester,
          map,
          markers,
          locale: locale,
          scale: 3,
          useD75Compact: true,
          onLayoutUnavailable: () => fail('Legend should fit $locale'),
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(EarthquakeShareStoryCard)),
        );
        final count = l10n.reportDetailStoryLegendCount;
        final intensity = l10n.reportDetailStoryLegendIntensity;
        final semantic = find.bySemanticsLabel('$count\n$intensity');
        expect(semantic, findsOneWidget);
        expect(find.bySemanticsLabel(count), findsNothing);
        expect(find.bySemanticsLabel(intensity), findsNothing);
        final box = tester.getRect(semantic);
        expect(const Rect.fromLTRB(16, 57, 344, 600).intersect(box), box);
        expect(box.topLeft, isNot(const Offset(16, 57)));
        expect(
          icon
              .evaluate()
              .map((e) => tester.getRect(find.byWidget(e.widget)))
              .any(box.overlaps),
          isFalse,
        );
        expect(box.overlaps(tester.getRect(find.byType(ClipRRect))), isFalse);
        for (final line in [count, intensity]) {
          final text = find.text(line);
          expect(MediaQuery.textScalerOf(tester.element(text)).scale(10), 10);
          expect(box.intersect(tester.getRect(text)), tester.getRect(text));
        }
      }
    },
  );

  testWidgets(
    'Story reads representative and single locations with report-specific intensity',
    (tester) async {
      _setViewport(tester);
      final map = await _image(tester);
      final report = _report.copyWith(
        list: {
          '宜蘭縣': AreaIntensity(
            intensity: 9,
            town: {
              '南澳': StationIntensity(
                latitude: 24,
                longitude: 121,
                intensity: 9,
              ),
              '南山': StationIntensity(
                latitude: 24,
                longitude: 120.9,
                intensity: 1,
              ),
              '頭城': StationIntensity(
                latitude: 24,
                longitude: 121.2,
                intensity: 3,
              ),
            },
          ),
        },
      );
      for (final (level, label, spoken) in [
        (5, '5⁻', '五弱等級'),
        (6, '5⁺', '五強等級'),
        (7, '6⁻', '六弱等級'),
        (8, '6⁺', '六強等級'),
        (9, '7', '7'),
      ]) {
        final markers = [
          _marker('["宜蘭縣","南澳"]', const Offset(180, 220), intensity: level),
          _marker(
            '["宜蘭縣","南山"]',
            const Offset(187, 222),
            intensity: 1,
            longitude: 120.9,
          ),
          _marker(
            '["宜蘭縣","頭城"]',
            const Offset(260, 270),
            intensity: 3,
            longitude: 121.2,
          ),
        ];
        await _pump(
          tester,
          map,
          markers,
          report: level == 9
              ? report.copyWith(
                  time: DateTime.utc(2018, 2, 6).millisecondsSinceEpoch,
                )
              : report,
          locale: const Locale('zh', 'TW'),
          useD75Compact: true,
        );
        expect(
          find.bySemanticsLabel('2 筆觀測，群內最大震度 $spoken，代表觀測地點為宜蘭縣南澳'),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is IntensityBadge &&
                widget.size == 22 &&
                widget.label == label,
          ),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('宜蘭縣頭城，震度 3，一筆觀測'), findsOneWidget);
        expect(find.bySemanticsLabel('2'), findsNothing);
        expect(find.bySemanticsLabel('宜蘭縣南山'), findsNothing);
      }
    },
  );

  testWidgets('system scaling leaves HUD and observation placement fixed', (
    tester,
  ) async {
    _setViewport(tester);
    final map = await _image(tester);
    final icon = find.byWidgetPredicate(
      (w) => w is IntensityBadge && w.size == 22,
    );
    const point = Offset(180, 363);
    final markers = [_marker('station', point, intensity: 3)];
    await _pump(tester, map, markers);
    final beforeHud = tester.getRect(find.byType(ClipRRect));
    final beforeIcon = tester.getRect(icon);
    await _pump(tester, map, markers, scale: 1.15);
    final afterHud = tester.getRect(find.byType(ClipRRect));
    final afterIcon = tester.getRect(icon);
    expect(afterHud, beforeHud);
    expect(afterIcon, beforeIcon);
    expect(afterIcon.overlaps(afterHud), isFalse);
    expect(markers.single.position, point);
  });

  testWidgets('the overlay paints a line only after moving a marker', (
    tester,
  ) async {
    _setViewport(tester);
    final map = await _image(tester);
    final cross = (await tester.runAsync(
      () => IntensityIconRenderer.render('cross'),
    ))!;
    const anchor = Offset(180, 180);
    final markers = [_marker('station', anchor, intensity: 3)];
    final icon = find.byWidgetPredicate(
      (w) => w is IntensityBadge && w.size == 22,
    );
    List<Invocation> lines() {
      final overlay = find.ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Stack &&
              w.children.any(
                (child) => child is Positioned && child.width == 22,
              ),
        ),
      );
      final canvas = TestRecordingCanvas();
      tester
          .renderObject<RenderBox>(overlay)
          .paint(TestRecordingPaintingContext(canvas), Offset.zero);
      return [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawLine &&
              (call.invocation.positionalArguments[2] as Paint).strokeWidth ==
                  StoryConnector.strokeWidth)
            call.invocation,
      ];
    }

    await _pump(tester, map, markers);
    expect(lines(), isEmpty);
    await _pump(tester, map, markers, epicenter: anchor, cross: cross);
    final crossImage = find.byWidgetPredicate(
      (w) => w is Image && w.width == 36,
    );
    expect(tester.getCenter(crossImage), anchor);
    expect(tester.getRect(crossImage).overlaps(tester.getRect(icon)), isFalse);
    expect(lines().single.positionalArguments.take(2), [
      anchor,
      tester.getCenter(icon),
    ]);
  });

  testWidgets('equal-intensity placement follows canonical anchor priority', (
    tester,
  ) async {
    _setViewport(tester);
    final map = await _image(tester);
    const east = Offset(120, 180);
    const west = Offset(91, 152);
    final markers = [
      _marker('east', east, intensity: 3, longitude: 122),
      for (var i = 0; i < 100; i++) _marker('west-$i', west, intensity: 3),
    ];
    final icon = find.byWidgetPredicate(
      (w) => w is IntensityBadge && w.size == 22,
    );
    Iterable<Offset> centers() {
      final origin = tester.getTopLeft(find.byType(EarthquakeShareStoryCard));
      return [
        for (final e in icon.evaluate())
          tester.getCenter(find.byWidget(e.widget)) - origin,
      ];
    }

    await _pump(tester, map, markers, scale: 2);
    final positions = centers();
    expect(positions.last, east);
    final badgeHeight = tester.getSize(_countBadge('100')).height;
    expect(positions.first, isNot(west - Offset(0, (badgeHeight + 1) / 2)));
    expect(
      tester.getRect(_countBadge('100')).overlaps(tester.getRect(icon.last)),
      isFalse,
    );
    await _pump(tester, map, markers.reversed.toList(), scale: 2);
    expect(centers(), positions);
  });
}

StoryMarkerAnchor _at(Offset point) => (anchor: point, footprint: _icon);

List<Offset> _place(
  List<StoryMarkerAnchor> markers, {
  Rect? epicenter,
  Rect hud = Rect.zero,
}) => layoutStoryMarkers(
  markers: markers,
  canvas: _canvas,
  epicenter: epicenter,
  hud: hud,
);

StoryStationMarker _marker(
  String id,
  Offset point, {
  required int intensity,
  double longitude = 121,
}) => StoryStationMarker(
  sourceId: id,
  latitude: 24,
  longitude: longitude,
  position: point,
  intensity: intensity,
);

Finder _countBadge(String count) => find.ancestor(
  of: find.text(count),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.decoration is BoxDecoration,
  ),
);

void _setViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = _canvas.size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<Uint8List> _image(WidgetTester tester) async =>
    (await tester.runAsync(() => IntensityIconRenderer.render('intensity-1')))!;

Future<void> _pump(
  WidgetTester tester,
  Uint8List map,
  List<StoryStationMarker> markers, {
  double scale = 1,
  Offset? epicenter,
  Uint8List? cross,
  bool useD75Compact = false,
  VoidCallback? onLayoutUnavailable,
  Locale? locale,
  EarthquakeReport report = _report,
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: appSupportedLocales,
    home: Material(
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Center(
            child: EarthquakeShareStoryCard(
              report: report,
              mapPng: map,
              stationMarkers: markers,
              epicenterPosition: epicenter,
              markerIcons: {'cross': ?cross},
              useD75Compact: useD75Compact,
              onLayoutUnavailable: onLayoutUnavailable,
            ),
          ),
        ),
      ),
    ),
  ),
);
