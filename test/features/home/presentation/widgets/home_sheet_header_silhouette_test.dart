/// Verifies the capture half of [RainOnCard.silhouette] end to end against
/// real [HomeSheetHeader] content — [silhouetteSurface] itself is unit-tested
/// against synthetic pixels in `card_water_field_test.dart`, but nothing else
/// confirms actual rendered text and icon glyphs clear the 0.35 alpha
/// threshold rather than anti-aliasing away to nothing.
///
/// `RainOnCard` itself is deliberately not mounted here — its ticker never
/// settles, so `pumpAndSettle` hangs against it (see `home_hero_preview_test
/// .dart`'s own note). Capturing a plain `RepaintBoundary` around the header
/// and feeding the bytes through `silhouetteSurface` directly exercises the
/// same pipeline `RainOnCard._capture` runs, without needing the ticker at
/// all.
///
/// Tagged `preview`, same as `home_hero_preview_test.dart`: this stalled for
/// minutes in this harness with no diagnosis yet (a second
/// `RenderRepaintBoundary.toImage()`-based test to do so), so it is excluded
/// from the default `flutter test` run rather than risking an unattended CI
/// hang. Run explicitly with `--run-skipped --tags preview`.
@Tags(['preview'])
library;

import 'dart:ui' as ui;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
import 'package:dpip/features/home/presentation/widgets/weather_sky/card_water_field.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeWeatherRepository implements MeteorWeatherRepository {
  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async =>
      const Ok(
        WeatherRealtime(
          id: '467410',
          station: WeatherRealtimeStation(
            name: '臺南',
            latitude: 23.0,
            longitude: 120.2,
            altitude: 40,
            distance: 1.2,
          ),
          time: 0,
          data: WeatherRealtimeData(
            weather: '短暫雨',
            weatherCode: 200,
            temperature: 28.7,
            humidity: 89,
            rain: 2.4,
            wind: WeatherWind(),
            gust: WeatherWind(),
          ),
        ),
      );

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(WeatherForecast(updateTime: 0, forecast: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'a located township header rasterises to a non-empty silhouette',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = RegionStore(Prefs(await SharedPreferences.getInstance()));
      store
        ..select(1)
        ..setCurrentCode('100');
      const directory = TownDirectory(<String, Town>{
        '100': Town(
          code: '100',
          city: '臺南',
          town: '永康',
          lat: 23.0,
          lng: 120.2,
          cityLevel: '市',
          townLevel: '區',
        ),
      });

      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh', 'TW'),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<RegionStore>.value(value: store),
              Provider<TownDirectory>.value(value: directory),
              ChangeNotifierProvider<HomeWeatherController>(
                create: (_) => HomeWeatherController(
                  _FakeWeatherRepository(),
                  store,
                  directory,
                ),
              ),
            ],
            child: Scaffold(
              // No background fill behind the boundary — matches production,
              // where the header sits directly on the sky with nothing
              // painting behind it (see HomeSheetHeader's own doc). Anything
              // opaque here would alpha-flood the whole capture and make
              // every column register as "solid" from row 0, defeating the
              // point of the assertion below.
              backgroundColor: Colors.transparent,
              body: RepaintBoundary(
                key: key,
                // Roughly the sheet's own content width (screen width minus
                // AppSpacing.lg margins either side) — silhouetteSurface reads
                // heights in this same card-local coordinate space. Height is
                // just generous headroom for the expanded layout's name +
                // temp + metrics stack; extra blank space below only adds
                // columns that correctly read as "nothing here."
                child: SizedBox(
                  width: 350,
                  height: 420,
                  child: HomeSheetHeader(
                    reveal: 1,
                    expanded: true,
                    weatherMode: WeatherMode.rain,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // No RainOnCard in this tree, so nothing keeps a ticker alive —
      // pumpAndSettle terminates normally here.
      await tester.pumpAndSettle();

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final surface = silhouetteSurface(data!, image.width, image.height);

      // At least a meaningful fraction of sampled columns must have caught
      // real ink — the area name, the temperature, or a metric — not just a
      // stray anti-aliased pixel or two.
      var solid = 0;
      const columnWidth = 3.0;
      final columns = (image.width / columnWidth).ceil();
      for (var i = 0; i < columns; i++) {
        if (surface.heightAt((i + 0.5) * columnWidth).isFinite) solid++;
      }
      expect(
        solid,
        greaterThan(columns ~/ 20),
        reason:
            'expected real header content (name/temp/metrics) to clear the '
            'silhouette alpha threshold across a meaningful span of columns, '
            'got $solid/$columns',
      );
    },
  );
}
