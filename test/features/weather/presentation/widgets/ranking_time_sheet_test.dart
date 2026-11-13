import 'package:dpip/features/weather/presentation/widgets/ranking_time_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

int _second(int year, int month, int day, int hour) =>
    DateTime.utc(year, month, day, hour - 8).millisecondsSinceEpoch ~/ 1000;

void main() {
  testWidgets('groups history by Taipei date and returns the selected second', (
    tester,
  ) async {
    final previous = _second(2024, 12, 31, 23);
    final midnight = _second(2025, 1, 1, 0);
    final morning = _second(2025, 1, 1, 1);
    final latest = _second(2025, 1, 1, 2);
    RankingTimeChoice? choice;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showRankingTimeSheet(
                  context: context,
                  times: [previous, midnight, morning, latest],
                  latest: latest,
                  selected: midnight,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('01/01'), findsOneWidget);
    expect(find.text('12/31'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('01/01 01:00'), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('00:00'));
    await tester.pumpAndSettle();
    expect(choice?.second, midnight);
  });
}
