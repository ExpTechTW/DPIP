import 'package:dpip/features/earthquake/presentation/widgets/replay_eew_notice.dart';
import 'package:dpip/features/earthquake/replay_eew_probe.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ReplayEewSlot slot) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Center(child: ReplayEewNotice(slot: slot)),
  ),
);

void main() {
  late AppLocalizations l10n;

  Future<void> pump(WidgetTester tester, ReplayEewSlot slot) async {
    await tester.pumpWidget(_app(slot));
    l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
  }

  testWidgets('draws nothing before there is anything to say', (tester) async {
    await pump(tester, ReplayEewSlot.pending);
    expect(find.byType(Text), findsNothing);

    // The caller passes the card slot through the same path; the notice must
    // stay out of its way.
    await pump(tester, ReplayEewSlot.card);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('says the instant has no bulletin yet', (tester) async {
    await pump(tester, ReplayEewSlot.waiting);
    expect(find.text(l10n.replayEewWaiting), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
  });

  testWidgets('says it is retrying, not that there is no data', (tester) async {
    await pump(tester, ReplayEewSlot.retrying);
    expect(find.text(l10n.replayEewRetrying), findsOneWidget);
    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    expect(find.text(l10n.replayEewNone), findsNothing);
  });

  testWidgets('separates a dead feed from an empty one', (tester) async {
    await pump(tester, ReplayEewSlot.unavailable);
    expect(find.text(l10n.replayEewUnavailable), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text(l10n.replayEewNone), findsNothing);
  });

  testWidgets('qualifies the verdict with what it was based on', (
    tester,
  ) async {
    await pump(tester, ReplayEewSlot.none);
    expect(find.text(l10n.replayEewNone), findsOneWidget);
    expect(find.text(l10n.replayEewNoneDetail), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });
}
