/// Pins when the EEW feed counts as down and how each state reads.
library;

import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/eew_feed_down_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

void main() {
  test('stale and offline are down; connecting and live are not', () {
    expect(EewFeedDownNotice.isDown(RealtimeStatus.stale), isTrue);
    expect(EewFeedDownNotice.isDown(RealtimeStatus.offline), isTrue);
    // Every launch passes through connecting — not an outage.
    expect(EewFeedDownNotice.isDown(RealtimeStatus.connecting), isFalse);
    expect(EewFeedDownNotice.isDown(RealtimeStatus.live), isFalse);
  });

  testWidgets('offline reads on the error tones, stale on the tertiary ones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const EewFeedDownNotice(status: RealtimeStatus.offline)),
    );
    final colors = Theme.of(tester.element(find.byType(EewFeedDownNotice)))
        .colorScheme;
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EewFeedDownNotice)),
    );
    expect(find.text(l10n.eewFeedDown), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(
      tester
          .widget<Material>(
            find.descendant(
              of: find.byType(EewFeedDownNotice),
              matching: find.byType(Material),
            ),
          )
          .color,
      colors.errorContainer,
    );

    await tester.pumpWidget(
      _host(const EewFeedDownNotice(status: RealtimeStatus.stale)),
    );
    expect(
      tester
          .widget<Material>(
            find.descendant(
              of: find.byType(EewFeedDownNotice),
              matching: find.byType(Material),
            ),
          )
          .color,
      colors.tertiaryContainer,
    );
  });

  testWidgets('the inline form draws no surface of its own', (tester) async {
    await tester.pumpWidget(
      _host(const EewFeedDownNotice.inline(status: RealtimeStatus.offline)),
    );
    expect(
      find.descendant(
        of: find.byType(EewFeedDownNotice),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EewFeedDownNotice)),
    );
    expect(find.text(l10n.eewFeedDown), findsOneWidget);
  });
}
