/// The one row every ranking list (rain, temperature, wind, pressure...)
/// renders through, so a medal, a fill bar, or a merged title only has to be
/// right once.
///
/// [fraction] is clamped before it reaches the gradient `stops` list — a
/// caller normalizes against the list's own live max, and floating-point slop
/// or a value arriving fractionally over the current leader (the row that
/// *is* the max, mid-update) is the ordinary case, not the exception. Skipping
/// the clamp would hand `LinearGradient` a non-increasing stop list for
/// exactly the row a user is most likely to be looking at: the top one.
library;

import 'package:dpip/features/weather/domain/weather_ranking.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/presentation/widgets/weather_ranking_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _station = WeatherStation(
  name: 'Taipei',
  county: 'Taipei City',
  town: 'Daan',
  altitude: 10,
  latitude: 25.03,
  longitude: 121.53,
);

RankedObservation _item() =>
    RankedObservation(id: 's1', station: _station, value: 10);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

bool _hasCircleMedal(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .any((c) => (c.decoration as BoxDecoration?)?.shape == BoxShape.circle);

void main() {
  testWidgets('ranks 1 through 3 draw a circular medal', (tester) async {
    for (final rank in [1, 2, 3]) {
      await tester.pumpWidget(
        _wrap(
          WeatherRankingRow(
            rank: rank,
            item: _item(),
            merge: RankingMerge.none,
            valueLabel: '12.3 mm',
            fraction: 0.5,
          ),
        ),
      );
      expect(_hasCircleMedal(tester), isTrue, reason: 'rank $rank');
      expect(find.text('$rank'), findsOneWidget);
    }
  });

  testWidgets('rank 4 and below show a plain number, no medal', (tester) async {
    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 4,
          item: _item(),
          merge: RankingMerge.none,
          valueLabel: '9.1 mm',
          fraction: 0.3,
        ),
      ),
    );

    expect(_hasCircleMedal(tester), isFalse);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('RankingMerge.none shows the station name and county/town', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 5,
          item: _item(),
          merge: RankingMerge.none,
          valueLabel: '9.1 mm',
          fraction: 0.3,
        ),
      ),
    );

    expect(find.text('Taipei'), findsOneWidget);
    expect(find.text('Taipei CityDaan'), findsOneWidget);
  });

  testWidgets('RankingMerge.town collapses the title and drops the subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 5,
          item: _item(),
          merge: RankingMerge.town,
          valueLabel: '9.1 mm',
          fraction: 0.3,
        ),
      ),
    );

    expect(find.text('Taipei CityDaan'), findsOneWidget);
    expect(find.text('Taipei'), findsNothing);
  });

  testWidgets('shows leadingExtra and the event-time label when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 1,
          item: _item(),
          merge: RankingMerge.none,
          valueLabel: '9.1 mm',
          fraction: 0.3,
          leadingExtra: const Icon(Icons.arrow_upward),
          eventTimeLabel: '14:32',
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.text('14:32'), findsOneWidget);
  });

  testWidgets('tapping the row calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 1,
          item: _item(),
          merge: RankingMerge.none,
          valueLabel: '9.1 mm',
          fraction: 0.3,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('an out-of-range fraction is clamped, not thrown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 1,
          item: _item(),
          merge: RankingMerge.none,
          valueLabel: '9.1 mm',
          fraction: 1.5,
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _wrap(
        WeatherRankingRow(
          rank: 1,
          item: _item(),
          merge: RankingMerge.none,
          valueLabel: '9.1 mm',
          fraction: -0.5,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
