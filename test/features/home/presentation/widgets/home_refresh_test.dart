import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_content.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingWeatherRepository implements MeteorWeatherRepository {
  int calls = 0;

  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) async {
    calls++;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Home's real arrangement: the content inside a [DraggableScrollableSheet]
/// whose floor **is** its resting size, which is what lets a downward drag at
/// rest become overscroll instead of a sheet collapse.
Widget _wrap({
  required RegionStore store,
  required TownDirectory directory,
  required MeteorWeatherRepository repository,
  required HomeResetSignal reset,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<RegionStore>.value(value: store),
        Provider<TownDirectory>.value(value: directory),
        ChangeNotifierProvider<HomeResetSignal>.value(value: reset),
        ChangeNotifierProvider<HomeWeatherController>(
          create: (_) => HomeWeatherController(repository, store, directory),
        ),
      ],
      child: Scaffold(
        body: DraggableScrollableSheet(
          initialChildSize: HomeSheetExtent.rest,
          minChildSize: HomeSheetExtent.rest,
          maxChildSize: HomeSheetExtent.max,
          builder: (context, scrollController) =>
              HomeContent(scrollController: scrollController),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionStore store;
  late _CountingWeatherRepository repository;
  late HomeResetSignal reset;
  const directory = TownDirectory(<String, Town>{});

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = RegionStore(Prefs(await SharedPreferences.getInstance()));
    repository = _CountingWeatherRepository();
    reset = HomeResetSignal();
  });

  testWidgets('pulling down at the resting sheet refreshes the screen', (
    tester,
  ) async {
    var resets = 0;
    reset.addListener(() => resets++);

    await tester.pumpWidget(
      _wrap(
        store: store,
        directory: directory,
        repository: repository,
        reset: reset,
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
    await tester.pumpAndSettle();

    // The radar backdrop refreshes via the reset signal; the weather refetch is
    // the controller's job (no town resolves from an empty directory, so only
    // the signal is observable here).
    expect(resets, 1, reason: 'a pull should refresh the map backdrop');
  });

  testWidgets('the sheet still expands when dragged up', (tester) async {
    await tester.pumpWidget(
      _wrap(
        store: store,
        directory: directory,
        repository: repository,
        reset: reset,
      ),
    );
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(find.byType(ListView)).dy;
    await tester.fling(find.byType(ListView), const Offset(0, -320), 1000);
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.byType(ListView)).dy;

    // Forcing AlwaysScrollableScrollPhysics for the refresh gesture must not
    // cost the sheet its drag-to-expand.
    expect(
      after,
      lessThan(before),
      reason: 'dragging up should still grow the sheet',
    );
  });

  testWidgets(
    'an expanded sheet collapses on drag-down instead of refreshing',
    (tester) async {
      var resets = 0;
      reset.addListener(() => resets++);

      await tester.pumpWidget(
        _wrap(
          store: store,
          directory: directory,
          repository: repository,
          reset: reset,
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.byType(ListView), const Offset(0, -320), 1000);
      await tester.pumpAndSettle();
      final expanded = tester.getTopLeft(find.byType(ListView)).dy;

      await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
      await tester.pumpAndSettle();

      // The sheet consumes the drag first, so pull-to-refresh never steals the
      // gesture that closes an opened sheet.
      expect(
        tester.getTopLeft(find.byType(ListView)).dy,
        greaterThan(expanded),
        reason: 'the sheet should shrink back',
      );
      expect(resets, 0, reason: 'collapsing is not a refresh');
    },
  );
}
