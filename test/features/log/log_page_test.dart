import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/log/presentation/pages/log_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  // A replayed session must not re-trigger the old talker view's overflow
  // loop: the flood used to overflow TalkerScreen's header, route the layout
  // fault back through Log.handle into the very stream the page listens to,
  // and spin until the app hung. The rewritten page lays out with a plain
  // AppBar, and every one of these lines has to render without a single
  // overflow or exception.
  testWidgets('a log flood renders without exceptions or overflow', (
    tester,
  ) async {
    Log.talker.cleanHistory();
    for (var i = 0; i < 300; i++) {
      Log.info('flood line $i');
    }
    Log.error(
      'a persisted-looking error',
      StateError('boom'),
      StackTrace.current,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LogPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TalkerDataCard), findsWidgets);
    expect(tester.takeException(), isNull);
    expect(find.text('flood line 299'), findsOneWidget);
  });
}
