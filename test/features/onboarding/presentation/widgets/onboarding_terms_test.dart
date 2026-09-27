/// The second onboarding step: the Terms of Service, which must be scrolled
/// to the end and ticked before "Agree" unlocks.
///
/// Two independent locks compose here, not one: [OnboardingScaffold]'s scroll
/// gate disables the checkbox itself while `atEnd` is false, and even once
/// scrolled, the Agree button additionally requires the checkbox to be
/// checked (`atEnd && _agreed`). Losing either half of that conjunction —
/// letting the checkbox be ticked before the terms were shown, or letting
/// Agree fire on `atEnd` alone — turns "read and accept" into "scroll past
/// and accept unread", which is the one guarantee this screen exists to make.
library;

import 'package:dpip/features/onboarding/presentation/widgets/onboarding_terms.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders the terms title and body copy', (tester) async {
    await tester.pumpWidget(_wrap(OnboardingTermsPage(onAccept: () {})));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(OnboardingTermsPage)),
    );
    expect(find.text(l10n.onboardingTermsTitle), findsOneWidget);
    expect(find.text(l10n.onboardingTermsBody), findsOneWidget);
  });

  testWidgets(
    'the checkbox and Agree button are both locked before the end is reached',
    (tester) async {
      tester.view.physicalSize = const Size(800, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(OnboardingTermsPage(onAccept: () {})));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnboardingTermsPage)),
      );
      expect(find.text(l10n.onboardingScrollHint), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      // Tapping a disabled CheckboxListTile must not flip the state it
      // guards — otherwise the lock above is cosmetic only.
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
    },
  );

  testWidgets(
    'reaching the end unlocks the checkbox; checking it then unlocks Agree',
    (tester) async {
      tester.view.physicalSize = const Size(800, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var accepted = false;
      await tester.pumpWidget(
        _wrap(OnboardingTermsPage(onAccept: () => accepted = true)),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(OnboardingTermsPage)),
      );
      expect(find.text(l10n.onboardingScrollHint), findsNothing);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNotNull,
      );
      // Reaching the end alone must not be enough — the checkbox is still
      // unticked, so Agree must stay locked.
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byType(FilledButton));
      expect(accepted, isTrue);
    },
  );
}
