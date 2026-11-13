/// Seismometer page: phase copy, reset, and when sampling runs.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/core/platform/accelerometer.dart';
import 'package:dpip/features/seismometer/domain/jma_intensity.dart';
import 'package:dpip/features/seismometer/presentation/seismometer_controller.dart';
import 'package:dpip/features/seismometer/presentation/seismometer_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const int _hz = 50;
const int _periodNanos = 1000000000 ~/ _hz;
const int _calibrationSamples = 3 * _hz;
const _absent = '\u2014';

/// 2 Hz, 50 gal, the same value on every axis. Calibration is an integer
/// number of periods, so the intensity window matches a direct calculation.
double _sine(int index) => 50 * math.sin(2 * math.pi * 2 * index / _hz);

/// The data hub's branch, as the router passes it.
const int _tabIndex = 3;

void main() {
  test('trace scale is at least 1 gal and steps by 1, 2, 5', () {
    expect(seismometerTraceScale(0), 1);
    expect(seismometerTraceScale(0.4), 1);
    expect(seismometerTraceScale(1), 1);
    expect(seismometerTraceScale(1.01), 2);
    expect(seismometerTraceScale(2), 2);
    expect(seismometerTraceScale(2.01), 5);
    expect(seismometerTraceScale(5), 5);
    expect(seismometerTraceScale(6), 10);
    expect(seismometerTraceScale(40), 50);
    expect(seismometerTraceScale(100), 100);
    expect(seismometerTraceScale(double.nan), 1);
    expect(seismometerTraceScale(double.infinity), 1);
  });

  testWidgets('calibrating asks for the phone to be held still', (
    tester,
  ) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));

    expect(
      find.text('Calibrating \u2014 keep the phone still (3 s)'),
      findsOneWidget,
    );
    expect(find.text(_absent), findsNWidgets(4));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Measuring'), findsNothing);
    expect(find.text('Acceleration'), findsOneWidget);
    expect(find.text('Peak acceleration'), findsOneWidget);
    expect(find.text('Sample rate'), findsOneWidget);
    expect(find.text('0.0 gal'), findsNWidgets(2));
    expect(find.text('0 Hz'), findsOneWidget);
    expect(
      find.text(
        'Lay the phone flat on a steady surface. Phone sensors are '
        'imprecise, so this reading is for reference only and is not an '
        'official CWA intensity.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Computed with the JMA instrumental intensity method used by ES-Net',
      ),
      findsOneWidget,
    );
    expect(feed.controller.phase, SeismometerPhase.calibrating);
  });

  testWidgets('buffering shows a determinate progress bar', (tester) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));
    feed.add(0, _calibrationSamples + JmaIntensityCalculator.maxSamples ~/ 2);
    await tester.pump();

    expect(feed.controller.phase, SeismometerPhase.buffering);
    expect(find.text('Collecting data 50%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.5, 1e-9));
  });

  testWidgets('measuring shows the level and two decimal places', (
    tester,
  ) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));
    feed.add(0, _calibrationSamples + JmaIntensityCalculator.maxSamples);
    await tester.pump();

    final latest = feed.controller.latest;
    expect(latest, isNotNull);
    final label = Intensity.label(Intensity.toScale(latest!.intensity));
    expect(find.text('Measuring'), findsOneWidget);
    expect(find.text(label), findsNWidgets(2));
    expect(find.text(latest.intensity.toStringAsFixed(2)), findsNWidgets(2));
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('unavailable names the missing sensor', (tester) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));
    feed.unavailable();
    await tester.pump();

    expect(feed.controller.phase, SeismometerPhase.unavailable);
    expect(
      find.text('This device has no usable accelerometer'),
      findsOneWidget,
    );
    expect(find.text(_absent), findsNWidgets(4));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Measuring'), findsNothing);
  });

  testWidgets('reset clears the session maximum and keeps measuring', (
    tester,
  ) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));
    feed.add(0, _calibrationSamples + JmaIntensityCalculator.maxSamples);
    await tester.pump();

    final latest = feed.controller.latest;
    expect(latest, isNotNull);
    expect(feed.controller.sessionMax, isNotNull);
    expect(feed.controller.peakAcceleration, greaterThan(0));

    await tester.tap(find.byTooltip('Reset'));
    await tester.pump();

    expect(feed.controller.sessionMax, isNull);
    expect(feed.controller.peakAcceleration, 0);
    expect(feed.controller.phase, SeismometerPhase.measuring);
    expect(feed.controller.latest, same(latest));
    expect(find.text(latest!.intensity.toStringAsFixed(2)), findsOneWidget);
    expect(find.text('Measuring'), findsOneWidget);
  });

  testWidgets('dispose stops the controller', (tester) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));
    expect(feed.controller.phase, SeismometerPhase.calibrating);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(feed.controller.phase, SeismometerPhase.idle);
    feed.add(0, _calibrationSamples);
    expect(feed.controller.phase, SeismometerPhase.idle);
  });

  testWidgets('background stops sampling and resume starts it', (tester) async {
    final feed = _Feed();
    addTearDown(feed.close);
    await _show(tester, _page(feed));
    expect(feed.controller.phase, SeismometerPhase.calibrating);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.calibrating);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.idle);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.calibrating);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.idle);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.idle);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.calibrating);
  });

  testWidgets('leaving the data tab or covering the shell stops sampling', (
    tester,
  ) async {
    final feed = _Feed();
    addTearDown(feed.close);
    final tabs = VisibleTab(_tabIndex);
    await _show(tester, VisibleTabScope(visibleTab: tabs, child: _page(feed)));
    expect(feed.controller.phase, SeismometerPhase.calibrating);

    tabs.value = 0;
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.idle);

    tabs.value = _tabIndex;
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.calibrating);

    tabs.shellOnTop = false;
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.idle);

    tabs.shellOnTop = true;
    await tester.pump();
    expect(feed.controller.phase, SeismometerPhase.calibrating);
  });
}

SeismometerPage _page(_Feed feed) => SeismometerPage(
  tabIndex: _tabIndex,
  createController: () => feed.controller,
);

Future<void> _show(WidgetTester tester, Widget home) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

final class _Feed {
  _Feed() {
    controller = SeismometerController(source: () => input.stream);
  }

  final input = StreamController<List<AccelerometerSample>>.broadcast(
    sync: true,
  );
  late final SeismometerController controller;

  void unavailable() {
    input.addError(PlatformException(code: 'unavailable'));
  }

  void add(int from, int count) {
    input.add([
      for (var offset = 0; offset < count; offset++)
        AccelerometerSample(
          timestampNanos: (from + offset) * _periodNanos,
          x: _sine(from + offset),
          y: _sine(from + offset),
          z: _sine(from + offset),
        ),
    ]);
  }

  Future<void> close() => input.close();
}
