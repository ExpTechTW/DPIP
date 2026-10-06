/// A station sheet is what a tap on the map promises: the reading, or a
/// loading mark, or a failure the user can retry. An empty chart must not
/// look like a flat line of real observations.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Source implements StationSheetSource {
  _Source()
    : selection = ValueNotifier<String?>(null),
      selectionRevision = ValueNotifier(0);

  @override
  final ValueNotifier<String?> selection;

  @override
  final ValueNotifier<int> selectionRevision;

  final ranges = <String>[];
  int attempts = 0;
  String? subtitle = 'Hualien · Hualien';
  String? readingText = '27.8°C';
  Color? color = const Color(0xFFE53935);
  bool bars = false;
  double? minY;
  double? maxY;
  TrendSeries series = TrendSeries(
    times: [for (var i = 0; i < 6; i++) 1700000000 + i * 3600],
    values: const [1, 3, null, 8, 12, 4],
  );
  Result<TrendSeries>? failure;
  Completer<Result<TrendSeries>>? gate;

  void open(String id) {
    selection.value = id;
    selectionRevision.value++;
  }

  @override
  String stationName(String id) => 'Station $id';

  @override
  String? stationSubtitle(String id) => subtitle;

  @override
  String? reading(String id) => readingText;

  @override
  Widget? readingIcon(String id) => const Icon(Icons.air);

  @override
  Color? valueColor(String id) => color;

  @override
  String title(BuildContext context) => 'Temperature';

  @override
  String get unit => '°C';

  @override
  double? get chartMinY => minY;

  @override
  double? get chartMaxY => maxY;

  @override
  bool get chartBars => bars;

  @override
  Future<Result<TrendSeries>> trend(String id, String range) {
    attempts++;
    ranges.add(range);
    final pending = gate;
    if (pending != null) return pending.future;
    final failed = failure;
    if (failed != null) return Future.value(failed);
    return Future.value(Ok(series));
  }

  @override
  void select(String id) => open(id);

  @override
  void close() {
    selection.value = null;
    selectionRevision.value++;
  }
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('axis helpers stay finite on an empty or single-slot chart', () {
    expect(niceAxisStep(0, 4), 1);
    expect(niceAxisStep(double.nan, 4), 1);
    expect(niceAxisStep(10, 4), isPositive);
    expect(niceTimeLabelStepSec(0), 3600);
    expect(niceTimeLabelStepSec(1e12), 72 * 3600);
    expect(barSlotCenterX(0, 1, 8, 100), 4);
  });

  test('a wind tooltip omits the bearing when the sample has none', () {
    final colors = ThemeData.light().colorScheme;
    final textTheme = ThemeData.light().textTheme;
    final bar = LineChartBarData(spots: const [FlSpot(100, 4)]);
    final items = windTooltipItems(
      touched: [LineBarSpot(bar, 0, const FlSpot(100, 4))],
      unit: 'm/s',
      timeLabel: (x) => '${x.toInt()}h',
      directionAt: (_) => null,
      accentAt: (_) => const Color(0xFF03A9F4),
      colors: colors,
      textTheme: textTheme,
    );
    expect(items.single.children, hasLength(1));
    expect(items.single.text, '4.0 m/s');
  });

  testWidgets('nothing selected asks for a tap', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(_app(StationSheet(source: _Source())));
    await tester.pump();
    expect(find.text(l10n.stationSheetEmpty), findsOneWidget);
  });

  testWidgets('a loaded series draws, a gap is not a point, and 7d refetches', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final source = _Source()
      ..series = TrendSeries(
        times: [for (var i = 0; i < 6; i++) 1700000000 + i * 3600],
        values: const [1, 3, null, 8, 12, 4],
        directions: const [0, 45, null, 90, 180, 270],
      );
    await tester.pumpWidget(_app(StationSheet(source: source)));
    source.open('C0S730');
    await tester.pump();
    await tester.pump();

    expect(find.text('Station C0S730'), findsOneWidget);
    expect(find.text('Hualien · Hualien'), findsOneWidget);
    expect(find.text('27.8°C'), findsOneWidget);
    expect(find.byIcon(Icons.air), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(source.ranges, ['24h']);

    await tester.tap(find.text(l10n.trendRange7d));
    await tester.pump();
    await tester.pump();
    expect(source.ranges, ['24h', '7d']);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text(l10n.stationSheetEmpty), findsOneWidget);
  });

  testWidgets(
    'bars, an all-null series, and a station switch each take a path',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final source = _Source()
        ..bars = true
        ..minY = 0
        ..maxY = 20
        ..subtitle = null
        ..readingText = null
        ..color = null
        ..series = TrendSeries(
          times: [for (var i = 0; i < 4; i++) 1700000000 + i * 3600],
          values: const [0, 2.5, null, 10],
        );
      await tester.pumpWidget(_app(StationSheet(source: source)));
      source.open('rain');
      await tester.pump();
      await tester.pump();
      expect(find.byType(BarChart), findsOneWidget);

      source.series = const TrendSeries(times: [1], values: [null]);
      source.open('empty');
      await tester.pump();
      await tester.pump();
      expect(find.text(l10n.trendNoData), findsOneWidget);
    },
  );

  testWidgets('a hanging fetch shows loading, and a failure can be retried', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // The resting sheet is shorter than the error column, so the retry sits
    // below the fold on the default 600px surface.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = _Source()..gate = Completer<Result<TrendSeries>>();
    await tester.pumpWidget(_app(StationSheet(source: source)));
    source.open('C0S730');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    source.gate!.complete(Err(const NetworkFailure('trend failed')));
    source.gate = null;
    source.failure = Err(const NetworkFailure('trend failed'));
    await tester.pump();
    expect(find.text('trend failed'), findsOneWidget);

    source.failure = null;
    await tester.ensureVisible(find.text(l10n.commonRetry));
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();
    await tester.pump();
    expect(source.attempts, greaterThan(1));
    expect(find.text('trend failed'), findsNothing);
    expect(find.byType(LineChart), findsOneWidget);
    expect(source.attempts, greaterThan(1));
  });
}
