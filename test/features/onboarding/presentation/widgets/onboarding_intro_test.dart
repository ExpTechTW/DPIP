/// The first onboarding step: the app's own introduction, gated behind
/// [OnboardingScaffold]'s "scroll to the end" rule before its Next button
/// unlocks.
///
/// The gate exists so first launch can't be dismissed by a single reflexive
/// tap before the user has seen what DPIP does — the same threshold
/// arithmetic gates the Terms step next in the flow, where skipping it would
/// be worse than a UX nit. A miscalibrated threshold fails in one of two
/// silent directions: too strict and the button never unlocks, soft-locking
/// first launch on a disaster-prep app with no other way in; too loose and it
/// unlocks before the content it gates was ever shown.
library;

import 'package:dpip/features/onboarding/presentation/widgets/onboarding_intro.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders the DPIP mark, title, and body copy', (tester) async {
    await tester.pumpWidget(_wrap(OnboardingIntroPage(onNext: () {})));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingIntroPage)),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text(l10n.onboardingIntroTitle), findsOneWidget);
    expect(find.text(l10n.onboardingIntroBody), findsOneWidget);
  });

  testWidgets(
    'content short enough to need no scrolling starts already unlocked',
    (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(OnboardingIntroPage(onNext: () {})));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Next is locked until scrolled to the end, then advances on tap',
    (tester) async {
      tester.view.physicalSize = const Size(800, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var advanced = false;
      await tester.pumpWidget(
        _wrap(OnboardingIntroPage(onNext: () => advanced = true)),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnboardingIntroPage)),
      );
      expect(find.text(l10n.onboardingScrollHint), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.onboardingScrollHint), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byType(FilledButton));
      expect(advanced, isTrue);
    },
  );
}
