/// The report list's day heading: what its date text says, and where the rule
/// and the count land.
///
/// Both halves have already been wrong in ways nothing caught. The text used to
/// lead with `今天` and drop the weekday for today and yesterday only, so two
/// adjacent headings were in different formats. The layout then made the date a
/// flex child, which hands it a *tight* share of the row: a short date sat in a
/// hole with the rule starting at the midpoint, and a long one was scaled down
/// to half width with empty space beside it. Neither throws, neither fails a
/// build, and both look deliberate in a screenshot — hence the geometry
/// assertions below.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_list_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A Saturday, so the weekday in the expected strings is not the same word in
/// two languages by accident.
final _day = DateTime(2026, 9, 19);

Future<AppLocalizations> _l10n(Locale locale) =>
    AppLocalizations.delegate.load(locale);

/// The heading at a fixed [width], so the geometry assertions have a frame of
/// reference the screen size cannot move.
Widget _wrap(Widget child, {required Locale locale, required double width}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  group('reportDayLabel', () {
    // The widget path gets this from the Material localizations delegate; a
    // plain unit test has to load the date symbols itself.
    setUpAll(initializeDateFormatting);

    test(
      'leads with the date and appends the relative day in parentheses',
      () async {
        final l10n = await _l10n(const Locale('en'));
        expect(
          reportDayLabel(_day, todayTaipei: _day, l10n: l10n, locale: 'en'),
          'Sat, Sep 19, 2026 (Today)',
        );
        expect(
          reportDayLabel(
            _day.subtract(const Duration(days: 1)),
            todayTaipei: _day,
            l10n: l10n,
            locale: 'en',
          ),
          'Fri, Sep 18, 2026 (Yesterday)',
        );
      },
    );

    test('an older day is the date alone — no empty parentheses', () async {
      final l10n = await _l10n(const Locale('en'));
      expect(
        reportDayLabel(
          _day.subtract(const Duration(days: 2)),
          todayTaipei: _day,
          l10n: l10n,
          locale: 'en',
        ),
        'Thu, Sep 17, 2026',
      );
    });

    test('today carries the weekday, exactly like every older heading', () async {
      // The regression this pins: today used to be formatted without the
      // weekday, so it was the one heading in the list shaped differently from
      // all the others sitting right under it.
      final l10n = await _l10n(const Locale('en'));
      String label(DateTime day) =>
          reportDayLabel(day, todayTaipei: _day, l10n: l10n, locale: 'en');

      expect(label(_day), startsWith('Sat, '));
      expect(
        label(_day.subtract(const Duration(days: 1))),
        startsWith('Fri, '),
      );
      expect(
        label(_day.subtract(const Duration(days: 30))),
        startsWith('Thu, '),
      );
    });

    test('the relative word comes from l10n, not a hardcoded string', () async {
      final zh = await _l10n(const Locale('zh', 'TW'));
      final en = await _l10n(const Locale('en'));
      expect(
        reportDayLabel(_day, todayTaipei: _day, l10n: zh, locale: 'zh_TW'),
        endsWith('(今天)'),
      );
      expect(
        reportDayLabel(_day, todayTaipei: _day, l10n: en, locale: 'en'),
        endsWith('(Today)'),
      );
    });

    test('a day two years back is still just a date', () async {
      final l10n = await _l10n(const Locale('en'));
      final label = reportDayLabel(
        DateTime(2024, 4, 3),
        todayTaipei: _day,
        l10n: l10n,
        locale: 'en',
      );
      expect(label, 'Wed, Apr 3, 2024');
      expect(label, isNot(contains('(')));
    });
  });

  group('ReportDayHeader layout', () {
    /// Rect of the date's own box — the [FittedBox] sizes itself to the text,
    /// so this is the width the date actually occupies, not its flex share.
    Rect labelRect(WidgetTester tester) =>
        tester.getRect(find.byType(FittedBox));

    Rect ruleRect(WidgetTester tester) => tester.getRect(find.byType(Divider));

    testWidgets(
      'the rule starts right after a short date, not at the midpoint',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ReportDayHeader(day: _day, count: 3),
            locale: const Locale('zh', 'TW'),
            width: 800,
          ),
        );

        final label = labelRect(tester);
        final rule = ruleRect(tester);
        // The whole point: one gap between them and the leftover is the rule's.
        // A flex date would put `rule.left` near the row's middle instead.
        expect(rule.left, moreOrLessEquals(label.right + AppSpacing.sm));
        expect(rule.width, greaterThan(label.width));
      },
    );

    testWidgets('the count sits at the far right, one gap past the rule', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ReportDayHeader(day: _day, count: 12),
          locale: const Locale('zh', 'TW'),
          width: 400,
        ),
      );

      final rule = ruleRect(tester);
      final count = tester.getRect(find.text('12'));
      final row = tester.getRect(find.byType(Row));
      expect(count.left, moreOrLessEquals(rule.right + AppSpacing.sm));
      expect(count.right, moreOrLessEquals(row.right));
    });

    testWidgets('a long date on a narrow row shrinks instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          // German runs long: "Sa., 19. Sept. 2026 (Heute)".
          ReportDayHeader(day: _day, count: 999),
          locale: const Locale('de'),
          width: 240,
        ),
      );

      expect(tester.takeException(), isNull);
      final row = tester.getRect(find.byType(Row));
      // Nothing was pushed off the end: the rule survives and the count is
      // still inside the row.
      expect(ruleRect(tester).width, greaterThan(0));
      expect(find.text('999'), findsOneWidget);
      expect(
        tester.getRect(find.text('999')).right,
        lessThanOrEqualTo(row.right + 0.5),
      );
    });

    testWidgets('the date is the same width on a phone row and a tablet one', (
      tester,
    ) async {
      // Both directions of the old bug in one assertion. A flex date grows with
      // the row (hole after a short date); a fraction-of-the-row cap shrinks it
      // on the narrow row (scaled-down text with space to spare beside it).
      // Neither may happen: only the rule may change width.
      final labels = <double>[];
      final rules = <double>[];
      for (final rowWidth in const [324.0, 800.0]) {
        await tester.pumpWidget(
          _wrap(
            ReportDayHeader(day: _day, count: 3),
            locale: const Locale('zh', 'TW'),
            width: rowWidth,
          ),
        );
        labels.add(labelRect(tester).width);
        rules.add(ruleRect(tester).width);
      }
      expect(labels[0], moreOrLessEquals(labels[1]));
      expect(rules[1] - rules[0], moreOrLessEquals(800 - 324));
    });
  });
}
