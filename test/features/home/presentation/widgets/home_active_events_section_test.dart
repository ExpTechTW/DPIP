/// The collapsed home sheet is the only place an active notice is a single
/// row. An empty feed that looks like a failure, or a retry that never asks
/// again, would hide a live warning or leave the sheet stuck on the empty line.
library;

import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/event_labels.dart';
import 'package:dpip/features/events/presentation/widgets/event_card_tile.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_active_events_section.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../events/presentation/event_card_fixtures.dart';

class _Events implements EventRepository {
  Result<List<EventCard>> next = const Ok([]);
  int calls = 0;

  @override
  Future<Result<List<EventCard>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<List<EventCard>>> activeEvents({String? regionCode}) async {
    calls++;
    return next;
  }

  @override
  Future<Result<EventCardDetail>> detail({
    required int id,
    String? regionCode,
  }) async => const Err(NetworkFailure('unused'));
}

/// Sent at 09:05 Taipei time today (01:05 UTC), in force for a day.
EventCard _event(int id, String title, String subtitle) {
  final today = AppTime.taipei(AppTime.utc);
  return eventCard(
    id: id,
    hazard: EventHazard.earthquake,
    type: 'earthquake.eew',
    title: title,
    subtitle: subtitle,
    send: DateTime.utc(today.year, today.month, today.day, 1, 5),
    expires: AppTime.utc.add(const Duration(days: 1)),
  );
}

/// The row the app layer hands the section (see `app_router.dart`).
Widget _row(
  BuildContext context,
  EventCard card, {
  required String? regionCode,
  required Color foreground,
  required Color secondary,
}) => EventCardTile(
  card: card,
  regionCode: regionCode,
  compact: true,
  foreground: foreground,
  secondary: secondary,
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
        Provider<HomeEventRowBuilder>.value(value: _row),
        ChangeNotifierProvider<RegionStore>.value(value: regions),
        ChangeNotifierProvider<HomeActiveEventsController>.value(
          value: controller,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
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
      _event(1, 'Quake near Hualien', 'Felt widely'),
      _event(2, '', ''),
    ]);
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(find.text('Quake near Hualien'), findsOneWidget);
    expect(find.text('Felt widely'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('09:05'), findsWidgets);
    expect(find.byType(EventCardTile), findsNWidgets(2));
    // Earthquakes carry no in-force state.
    expect(find.text(EventCardStatus.active.label(l10n)), findsNothing);
    expect(repo.calls, 2);
  });

  testWidgets('a card that has ended is not shown as active', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final regions = RegionStore(SettingsStore.inMemory());
    addTearDown(regions.dispose);
    final now = AppTime.utc;
    final repo = _Events()
      ..next = Ok([
        eventCard(
          title: 'Ended a minute ago',
          send: now.subtract(const Duration(hours: 1)),
          expires: now.subtract(const Duration(minutes: 1)),
        ),
      ]);

    regions.select(0);
    await _pump(tester, regions: regions, repo: repo);
    await tester.pump();
    expect(find.text('Ended a minute ago'), findsNothing);
    expect(find.text(l10n.homeActiveEventsEmpty), findsOneWidget);
  });
}
