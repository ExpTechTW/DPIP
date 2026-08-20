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
  ValueChanged<bool>? onScrubbing,
  Duration? framePeriod,
  DateTime? dataTime,
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
          onScrubbing: onScrubbing,
          framePeriod: framePeriod,
          dataTime: dataTime,
        ),
      ),
    ),
  ),
);

/// A forecast's frames straddle the present: six hours of history and sixteen
/// ahead, hourly, so index 6 is now. Anchored on the real clock because the
/// widget asks the real clock.
List<MapFrame> _forecastFrames() {
  final now = DateTime.now();
  return [
    for (var h = -6; h <= 16; h++)
      MapFrame(
        id: '$h',
        time: now.add(Duration(hours: h)),
      ),
  ];
}

void main() {
  testWidgets('backpressure warning stays visible until rapid samples stop', (
    tester,
  ) async {
    final paused = TimelineScrubBackpressure(
      resumeDelay: const Duration(milliseconds: 100),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: MapTimelineScrubPauseNotice(paused: paused),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('scrubbing too fast'), findsNothing);
    paused.reportDroppedFrame();
    await tester.pump();
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.textContaining('scrubbing too fast'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 99));
    paused.reportDroppedFrame();
    await tester.pump(const Duration(milliseconds: 99));
    expect(paused.value, isTrue, reason: 'another dropped sample resets quiet');

    await tester.pump(const Duration(milliseconds: 1));
    expect(paused.value, isFalse);
    await tester.pumpAndSettle();
    expect(find.textContaining('scrubbing too fast'), findsNothing);
    expect(tester.takeException(), isNull);

    paused.reportDroppedFrame();
    paused.resume();
    expect(paused.value, isFalse, reason: 'finger-up resumes immediately');

    await tester.pumpWidget(const SizedBox.shrink());
    paused.dispose();
  });

  testWidgets('a forecast labels the present, not its furthest step', (
    tester,
  ) async {
    final frames = _forecastFrames();
    await tester.pumpWidget(
      _wrap(frames: frames, selectedIndex: 6, onSelected: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Now'),
      findsOneWidget,
      reason: 'the frame at the present moment is the one that is now',
    );

    // And the last step — sixteen hours out — must not claim to be now, which
    // is what left the scrubber parked at the right-hand end with the whole
    // forecast behind it and nothing ahead.
    await tester.pumpWidget(
      _wrap(
        frames: frames,
        selectedIndex: frames.length - 1,
        onSelected: (_) {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Now'), findsNothing);
  });

  testWidgets('history and future frames carry their own era labels', (
    tester,
  ) async {
    final frames = _forecastFrames(); // 6 hours back, 16 ahead; index 6 is now
    await tester.pumpWidget(
      _wrap(frames: frames, selectedIndex: 2, onSelected: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('Past'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(frames: frames, selectedIndex: 12, onSelected: (_) {}),
    );
    await tester.pumpAndSettle();
    expect(find.text('Future'), findsOneWidget);
    expect(find.text('Past'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('a release waits for an input-quiet window before settling', (
    tester,
  ) async {
    final states = <bool>[];
    await tester.pumpWidget(
      _wrap(
        frames: _frames(40),
        selectedIndex: 20,
        onSelected: (_) {},
        onScrubbing: states.add,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(41, 0));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 119));

    expect(states, [
      true,
    ], reason: 'finger-up and the alignment snap are not a cold-load boundary');

    await tester.pump(const Duration(milliseconds: 1));
    expect(states, [true, false]);
  });

  testWidgets('rapid consecutive drags report only the final settle', (
    tester,
  ) async {
    final states = <bool>[];
    await tester.pumpWidget(
      _wrap(
        frames: _frames(80),
        selectedIndex: 40,
        onSelected: (_) {},
        onScrubbing: states.add,
      ),
    );
    await tester.pumpAndSettle();

    final centre = tester.getCenter(find.byType(ListView));
    for (var i = 0; i < 20; i++) {
      final gesture = await tester.startGesture(centre);
      await gesture.moveBy(Offset(i.isEven ? 84 : -84, 0));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(
      states.where((state) => !state),
      isEmpty,
      reason: 'each new touch must cancel the preceding settle timer',
    );

    await tester.pumpAndSettle();
    expect(states, [true, false]);
  });

  testWidgets(
    'a frame period renders the big label as a range, ticks stay start times',
    (tester) async {
      final frames = _frames(10); // 07:00 + 9×10 min → newest 08:30
      await tester.pumpWidget(
        _wrap(
          frames: frames,
          selectedIndex: 9,
          onSelected: (_) {},
          framePeriod: const Duration(hours: 1),
        ),
      );
      await tester.pumpAndSettle();

      // The selected frame starts at 08:30 and covers the following hour.
      expect(find.text('08:30 – 09:30'), findsOneWidget);
      // Ticks keep their bare start times (every fourth slot is labelled).
      expect(find.text('08:20'), findsOneWidget);
      expect(find.text('08:30'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a data time renders as a line under the caption', (
    tester,
  ) async {
    final frames = _frames(10);
    await tester.pumpWidget(
      _wrap(
        frames: frames,
        selectedIndex: 9,
        onSelected: (_) {},
        dataTime: DateTime(2026, 7, 13, 6, 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Data 7/13 06:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a UTC-flagged frame renders in local time, not verbatim UTC', (
    tester,
  ) async {
    // The lightning bug: DateFormat prints a `isUtc: true` DateTime as
    // UTC (+00:00), so a strike at 22:34 Taipei read as 22:34 only because
    // devices here share the zone — anywhere else it read an hour/… off.
    // Same for any layer minting UTC frames (moon page). The ruler must
    // show the frame in the device's local time.
    final utc = DateTime.utc(2026, 7, 13, 14, 30); // 22:30 in UTC+8
    final frames = [MapFrame(id: '0', time: utc)];
    await tester.pumpWidget(
      _wrap(frames: frames, selectedIndex: 0, onSelected: (_) {}),
    );
    await tester.pumpAndSettle();

    final localHours = utc.toLocal();
    final expected =
        '${localHours.hour.toString().padLeft(2, '0')}:'
        '${localHours.minute.toString().padLeft(2, '0')}';
    // The big label uses HH:mm; ticks format the same instant.
    expect(find.text(expected), findsWidgets);
    // And the date line (yyyy/MM/dd) must reflect the local day too — a UTC
    // frame across midnight would otherwise print the UTC date.
    final localDate =
        '${localHours.year}/${localHours.month.toString().padLeft(2, '0')}/'
        '${localHours.day.toString().padLeft(2, '0')}';
    expect(find.text(localDate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
