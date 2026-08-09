import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/pages/events_page.dart';
import 'package:dpip/features/events/presentation/widgets/event_timeline.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records which areas the page actually asked for, so a fallback to the
/// nationwide feed is visible to the test rather than hidden behind an
/// identical-looking empty list.
class _RecordingEventRepository implements EventRepository {
  final List<String?> requests = [];

  @override
  Future<Result<List<Event>>> events({String? regionCode}) async {
    requests.add(regionCode);
    return const Ok([]);
  }

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async =>
      const Ok([]);
}

Widget _wrap(RegionStore store, EventRepository events) {
  const directory = TownDirectory(<String, Town>{});
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<RegionStore>.value(value: store),
        Provider<TownDirectory>.value(value: directory),
        Provider<EventRepository>.value(value: events),
      ],
      child: const EventsPage(),
    ),
  );
}

/// 全國, 所在地 and one saved township.
Future<RegionStore> _store() async {
  SharedPreferences.setMockInitialValues({
    'home.savedRegionCodes': ['100'],
  });
  return RegionStore(Prefs(await SharedPreferences.getInstance()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('所在地 with no GPS fix shows the notice, not a feed', (
    tester,
  ) async {
    final events = _RecordingEventRepository();
    final store = await _store()
      ..select(1); // 所在地, currentCode still null
    await tester.pumpWidget(_wrap(store, events));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regionCurrentUnavailable), findsOneWidget);
    expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    expect(find.byType(EventTimeline), findsNothing);
    // The nationwide feed must not stand in — it would read as "these are the
    // events where you are".
    expect(events.requests, isEmpty);
  });

  testWidgets('a GPS fix replaces the notice with that township feed', (
    tester,
  ) async {
    final events = _RecordingEventRepository();
    final store = await _store()
      ..select(1);
    await tester.pumpWidget(_wrap(store, events));
    await tester.pumpAndSettle();

    store.setCurrentCode('200');
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regionCurrentUnavailable), findsNothing);
    expect(find.byType(EventTimeline), findsOneWidget);
    expect(events.requests, contains('200'));
  });

  testWidgets('全國 fetches the nationwide feed', (tester) async {
    final events = _RecordingEventRepository();
    final store = await _store()
      ..select(0);
    await tester.pumpWidget(_wrap(store, events));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regionCurrentUnavailable), findsNothing);
    expect(find.byType(EventTimeline), findsOneWidget);
    expect(events.requests, [null]);
  });
}
