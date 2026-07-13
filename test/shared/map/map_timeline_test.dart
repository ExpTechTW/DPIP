import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<MapFrame> _frames(int n) => [
  for (var i = 0; i < n; i++)
    MapFrame(
      id: '$i',
      time: DateTime(2026, 7, 13, 7, 0).add(Duration(minutes: 10 * i)),
    ),
];

Widget _wrap({
  required List<MapFrame> frames,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 300,
        child: MapTimeline(
          frames: frames,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'labels the newest selected frame as "now" without layout error',
    (tester) async {
      final frames = _frames(10);
      await tester.pumpWidget(
        _wrap(frames: frames, selectedIndex: 9, onSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Now'), findsOneWidget); // newest under the scrubber
      expect(find.text('Observed'), findsOneWidget); // the date's label
      expect(find.text('2026/07/13'), findsOneWidget); // date of the selection
      expect(
        find.text('08:30'),
        findsWidgets,
      ); // 07:00 + 9*10min, big label + tick
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('scrubbing to an older frame reports a smaller index', (
    tester,
  ) async {
    final frames = _frames(10);
    var selected = 9;
    await tester.pumpWidget(
      _wrap(frames: frames, selectedIndex: 9, onSelected: (i) => selected = i),
    );
    await tester.pumpAndSettle();

    // Drag the ruler right → older frames move under the centre scrubber.
    await tester.drag(find.byType(ListView), const Offset(3 * 14.0, 0));
    await tester.pumpAndSettle();

    expect(selected, lessThan(9));
    expect(selected, greaterThanOrEqualTo(0));
    expect(find.text('Now'), findsNothing); // no longer the newest
    expect(tester.takeException(), isNull);
  });
}
