/// The collapsed home sheet is the only place an active notice is a single
/// row. An empty feed that looks like a failure, or a retry that never asks
/// again, would hide a live warning or leave the sheet stuck on the empty line.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Events implements EventRepository {
  Result<List<Event>> next = const Ok([]);
  int calls = 0;

  @override
  Future<Result<List<Event>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async {
    calls++;
    return next;
  }
}

Event _event(String title, String description) => Event(
  id: title,
  type: EventType.earthquake,
  time: DateTime(2026, 3, 1, 9, 5),
  title: title,
  description: description,
);

Future<void> _pump(
  WidgetTester tester, {
  required RegionStore regions,
  required _Events repo,
  bool expanded = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = HomeActiveEventsController(repo, regions);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RegionStore>.value(value: regions),
        ChangeNotifierProvider<HomeActiveEventsController>.value(
          value: controller,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeActiveEventsSection(
            expanded: expanded,
            reveal: expanded ? 1 : 0,
            sky: const Color(0xFF224466),
            weatherMode: WeatherMode.auto,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('empty, failed retry, then two notices', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final regions = RegionStore(SettingsStore.inMemory());
    addTearDown(regions.dispose);
    final repo = _Events()..next = const Err(NetworkFailure('down'));

    regions.select(0);
    await _pump(tester, regions: regions, repo: repo, expanded: true);
    await tester.pump();
    expect(find.text(l10n.homeActiveEventsEmpty), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
    expect(repo.calls, 1);

    repo.next = Ok([
      _event('Quake near Hualien', 'Felt widely'),
      _event('', ''),
    ]);
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(find.text('Quake near Hualien'), findsOneWidget);
    expect(find.text('Felt widely'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('09:05'), findsWidgets);
    expect(repo.calls, 2);
  });
}
