/// The report filter sheet's contract with the list page: opening it and
/// confirming must not change the query, dismissing must keep the edits without
/// triggering a fetch, and a full/default range must come back as *no filter*
/// rather than as an explicit one.
///
/// That last one is not cosmetic. The list page decides between "nothing in the
/// catalogue" and "nothing matched your filter" on `query.isEmpty`, and the
/// network layer caches on the canonical URL — so a sheet that hands back
/// `minIntensity: 1, maxIntensity: 9` for an untouched slider turns an empty
/// catalogue into a false "your filter is hiding results", and splits the cache
/// entry for an identical request.
library;

import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/presentation/widgets/report_filter_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-03-01 – 2026-03-05, intensity 3–6, magnitude 4.5–7, depth 10–80 km,
/// sorted by magnitude ascending. Every field is deliberately *not* a server
/// default, so a round trip that drops or widens one is visible.
const _partial = ReportListQuery(
  minIntensity: 3,
  maxIntensity: 6,
  minMagnitude: 4.5,
  maxMagnitude: 7,
  minDepth: 10,
  maxDepth: 80,
  startTime: '2026-03-01',
  endTime: '2026-03-05',
  sort: 'magnitude',
  order: 'asc',
);

/// What the sheet handed back, or null if it was dismissed without a result.
ReportFilterSheetResult? _result;

Future<void> _open(
  WidgetTester tester, {
  required ReportListQuery initial,
}) async {
  _result = null;
  // Tall enough that the whole form lays out: the last section and the confirm
  // button sit below a 0.72-extent sheet, and an off-screen button cannot be
  // tapped.
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                _result = await showReportFilterSheet(
                  context,
                  initial: initial,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

Future<void> _confirm(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.text(l10n.reportFilterApply));
  await tester.pumpAndSettle();
}

/// Android back / the system dismiss gesture, which is a pop *attempt* — the
/// sheet refuses it and answers with the edits instead.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opening and confirming changes nothing', (tester) async {
    await _open(tester, initial: _partial);
    final l10n = await _l10n();

    await _confirm(tester, l10n);

    expect(_result!.query, _partial);
    expect(_result!.search, isTrue);
  });

  testWidgets('a full range comes back as no filter at all', (tester) async {
    const wide = ReportListQuery(
      minIntensity: 1,
      maxIntensity: 9,
      minMagnitude: 0,
      maxMagnitude: 8,
      minDepth: 0,
      maxDepth: 150,
      sort: 'time',
      order: 'desc',
    );

    await _open(tester, initial: wide);
    final l10n = await _l10n();
    await _confirm(tester, l10n);

    expect(_result!.query.isEmpty, isTrue);
  });

  testWidgets('reset clears every control, including the sort', (tester) async {
    await _open(tester, initial: _partial);
    final l10n = await _l10n();

    await tester.tap(find.widgetWithText(TextButton, l10n.reportFilterReset));
    await tester.pumpAndSettle();
    await _confirm(tester, l10n);

    expect(_result!.query.isEmpty, isTrue);
  });

  testWidgets('the sort order is reported back, the default is not', (
    tester,
  ) async {
    await _open(tester, initial: ReportListQuery.empty);
    final l10n = await _l10n();

    await tester.tap(find.text(l10n.reportFilterOrderAsc));
    await tester.pumpAndSettle();
    await _confirm(tester, l10n);

    expect(_result!.query.order, 'asc');
    // `time` is what the server does anyway; sending it would make an untouched
    // sort look like a filter.
    expect(_result!.query.sort, isNull);
  });

  testWidgets('a sort chip is reported back', (tester) async {
    await _open(tester, initial: ReportListQuery.empty);
    final l10n = await _l10n();

    await tester.tap(
      find.widgetWithText(ChoiceChip, l10n.reportFilterSortDepth),
    );
    await tester.pumpAndSettle();
    await _confirm(tester, l10n);

    expect(_result!.query.sort, 'depth');
  });

  testWidgets('a dismiss keeps the edits and does not search', (tester) async {
    await _open(tester, initial: ReportListQuery.empty);
    final l10n = await _l10n();

    await tester.tap(
      find.widgetWithText(ChoiceChip, l10n.reportFilterSortMagnitude),
    );
    await tester.pumpAndSettle();
    await _systemBack(tester);

    // The list page remembers the draft across a dismiss, and only a search may
    // cost a request.
    expect(_result!.search, isFalse);
    expect(_result!.query.sort, 'magnitude');
  });

  testWidgets('a malformed date is dropped rather than sent', (tester) async {
    // The wire format is a Taipei calendar day; anything that is not one has to
    // fail closed. `DateTime.tryParse` would read it as UTC and shift the day
    // in a non-Taipei timezone, which is why the sheet parses it by hand.
    const broken = ReportListQuery(
      startTime: 'not-a-date',
      endTime: '2026-03-05',
    );

    await _open(tester, initial: broken);
    final l10n = await _l10n();
    await _confirm(tester, l10n);

    expect(_result!.query.startTime, isNull);
    expect(_result!.query.endTime, isNull);
  });

  testWidgets('the intensity scale explainer opens and closes', (tester) async {
    await _open(tester, initial: ReportListQuery.empty);
    final l10n = await _l10n();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.reportFilterIntensityInfoLegacyTitle),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.commonClose));
    await tester.pumpAndSettle();
    expect(find.text(l10n.commonClose), findsNothing);
    // Closing the explainer leaves the sheet open and still answerable.
    expect(find.text(l10n.reportFilterApply), findsOneWidget);
  });
}
