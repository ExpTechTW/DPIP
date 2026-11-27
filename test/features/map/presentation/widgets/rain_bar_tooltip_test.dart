import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Every rain bar is the rain of the hour before its reading, so its tooltip
/// has to say which hour. "Past hour" next to a bare "14h" read as 13:00–14:00
/// for a 24-hour bar from 14:10, and for a 7-day bar that holds the hour's last
/// reading, about 13:50–14:50.
void main() {
  final theme = ThemeData.light();
  const zhTW = Locale('zh', 'TW');
  const en = Locale('en');
  // 2026-11-28 00:00 Taipei, in Unix seconds.
  const midnight = 1795795200.0;

  BarTooltipItem tooltip(
    String range,
    double x,
    Locale locale, {
    double? runningTotal = 3.4,
  }) => rainBarTooltipItem(
    value: 1.2,
    x: x,
    runningTotal: runningTotal,
    range: range,
    unit: 'mm',
    l10n: lookupAppLocalizations(locale),
    valueColor: theme.colorScheme.primary,
    totalColor: theme.colorScheme.tertiary,
    colors: theme.colorScheme,
    textTheme: theme.textTheme,
  );

  List<String> lines(BarTooltipItem item) => [
    item.text,
    for (final span in item.children ?? const <TextSpan>[]) span.text ?? '',
  ].join().split('\n');

  test('a 24-hour bar gives its reading time to the minute', () {
    // 14:10 Taipei is 06:10 UTC: the time is Taipei's, whatever the device's.
    const at1410 = midnight + 14 * 3600 + 10 * 60;

    expect(lines(tooltip('24h', at1410, zhTW)), [
      '1.2 mm',
      '過去 1 小時雨量',
      '累計 3.4 mm',
      '14:10',
    ]);
    expect(lines(tooltip('24h', at1410, en)), [
      '1.2 mm',
      'Rain in the past hour',
      'Cumulative 3.4 mm',
      '14:10',
    ]);
  });

  test('a 7-day bar names its hour and says it is the last reading', () {
    // The 7-day series has only the hour; the value is that hour's last
    // 10-minute reading, so no minute is made up for it.
    const at1400Yesterday = midnight - 24 * 3600 + 14 * 3600;

    expect(lines(tooltip('7d', at1400Yesterday, zhTW)), [
      '1.2 mm',
      '截至該小時最後一筆的 1 小時雨量',
      '累計 3.4 mm',
      '11/27 14時',
    ]);
    expect(lines(tooltip('7d', at1400Yesterday, en)), [
      '1.2 mm',
      "1-hour rain up to this hour's last reading",
      'Cumulative 3.4 mm',
      '11/27 14h',
    ]);
  });

  test('the 7-day bar at midnight still names its hour', () {
    // The axis drops the hour at midnight; the tooltip cannot.
    expect(lines(tooltip('7d', midnight, zhTW)).last, '11/28 0時');
  });

  test('without a running total there is no total line', () {
    expect(lines(tooltip('24h', midnight, zhTW, runningTotal: null)), [
      '1.2 mm',
      '過去 1 小時雨量',
      '00:00',
    ]);
  });
}
