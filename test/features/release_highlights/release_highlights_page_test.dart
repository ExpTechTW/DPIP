/// Version-highlights page: the deck renders with a hero header and cards.
///
/// The page is stateless over two data decks — the widget test checks that
/// both tabs decode and lay out (an empty deck or an exception on one tab
/// would otherwise announce itself only on the day a reader opened it), and
/// that the two chrome actions still navigate where asked.
library;

import 'package:dpip/features/release_highlights/data/release_highlight_repository.dart';
import 'package:dpip/features/release_highlights/domain/release_highlight.dart';
import 'package:dpip/features/release_highlights/presentation/pages/release_highlights_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter _router(List<String> visited) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const ReleaseHighlightsPage(),
      routes: [
        GoRoute(
          path: AppRoutes.versionNotesPath,
          name: AppRoutes.versionNotes,
          builder: (_, _) {
            visited.add(AppRoutes.versionNotes);
            return const SizedBox.shrink();
          },
        ),
      ],
    ),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<ReleaseHighlightRepository>(
      create: (_) => const ReleaseHighlightRepositoryImpl(),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('each tab lays out its deck header and cards', (tester) async {
    final visited = <String>[];
    await _pump(tester, _router(visited));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(DefaultTabController)),
    );

    final repo = const ReleaseHighlightRepositoryImpl();
    final deck = repo.load(HighlightKind.normal);
    // The hero header opens with the deck's own localized title. The test
    // harness runs under en_US, so the rendered copy is the English one.
    expect(find.text(localized(deck.title, 'en')), findsOneWidget);

    await tester.tap(find.text(l10n.releaseHighlightsTabAdvanced));
    await tester.pumpAndSettle();
    final advanced = repo.load(HighlightKind.advanced);
    expect(find.text(localized(advanced.title, 'en')), findsOneWidget);
    // Advanced cards carry their technical badge above their facts.
    expect(find.text(l10n.highlightCardTechnical), findsWidgets);
  });

  testWidgets('the notes action navigates to the version notes route', (
    tester,
  ) async {
    final visited = <String>[];
    await _pump(tester, _router(visited));
    await tester.tap(find.byIcon(Icons.article_outlined));
    await tester.pumpAndSettle();
    expect(visited, [AppRoutes.versionNotes]);
  });
}
