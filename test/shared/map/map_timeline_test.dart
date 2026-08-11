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

  testWidgets(
    'scrubbing away and back to newest still reports the newest index',
    (tester) async {
      // Parent keeps selectedIndex stale during scrub (no setState) — returning
      // to "now" must still fire onSelected, or the map stays on now−1.
      final frames = _frames(10);
      final reported = <int>[];
      await tester.pumpWidget(
        _wrap(frames: frames, selectedIndex: 9, onSelected: reported.add),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(3 * 14.0, 0));
      await tester.pumpAndSettle();
      expect(reported, isNotEmpty);
      expect(reported.last, lessThan(9));

      await tester.drag(find.byType(ListView), const Offset(-3 * 14.0, 0));
      await tester.pumpAndSettle();

      expect(reported.last, 9);
      expect(find.text('Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching to another layer\u0027s frames re-centres on its newest frame',
    (tester) async {
      final first = _frames(10);
      await tester.pumpWidget(
        _wrap(frames: first, selectedIndex: 9, onSelected: (_) {}),
      );
      await tester.pumpAndSettle();
      expect(find.text('08:30'), findsWidgets); // newest of the first set

      // The scaffold hands a brand-new list instance (the newly selected
      // layer's frames) plus that layer's newest index.
      final second = _frames(6);
      await tester.pumpWidget(
        _wrap(frames: second, selectedIndex: 5, onSelected: (_) {}),
      );
      await tester.pumpAndSettle();

      // The ruler re-labelled and re-centred — the old set is gone and the
      // new newest frame sits under the scrubber as "now".
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('07:50'), findsWidgets); // 07:00 + 5×10 min
      expect(find.text('08:30'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
