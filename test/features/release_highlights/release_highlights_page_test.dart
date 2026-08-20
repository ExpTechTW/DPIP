/// Release-highlights presentation: the redesigned deck remains usable on a
/// narrow phone and both audience tabs expose their content.
library;

import 'package:dpip/features/release_highlights/data/release_highlight_repository.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip/features/release_highlights/presentation/pages/release_highlights_page.dart';
import 'package:dpip/features/release_highlights/presentation/widgets/highlight_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 700);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.4;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ReleaseHighlightsPage()),
      GoRoute(
        path: AppRoutes.versionNotesPath,
        name: AppRoutes.versionNotes,
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    Provider<ReleaseHighlightRepository>.value(
      value: const ReleaseHighlightRepositoryImpl(),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders both decks without overflow on a narrow phone', (
    tester,
  ) async {
    await _pumpPage(tester);

    expect(find.text('For users'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(ReleaseHighlightGroup), findsOneWidget);
    final userTile = find.byKey(
      const PageStorageKey('release-highlight-speed'),
    );
    await tester.ensureVisible(userTile);
    await tester.tap(userTile);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('The app used to ask the server'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Deep dive'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsWidgets);
    expect(find.byType(TechnicalHighlightGroup), findsOneWidget);
    final technicalTile = find.byKey(
      const PageStorageKey('technical-highlight-etag_core'),
    );
    await tester.ensureVisible(technicalTile);
    await tester.tap(technicalTile);
    await tester.pumpAndSettle();
    expect(find.textContaining('350 MiB'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
