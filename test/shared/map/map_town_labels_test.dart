import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Standalone township-label dropdown, as [MapScaffold] shows it for layers
/// with no settings menu of their own.
Widget _wrap(ValueNotifier<bool> labels, {ValueChanged<bool>? onChanged}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: MapTownLabelsMenu(
            showTownLabels: labels,
            onShowTownLabelsChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

void main() {
  testWidgets('the chip is unmarked while the labels are on (the default)', (
    tester,
  ) async {
    final labels = ValueNotifier<bool>(true);
    await tester.pumpWidget(_wrap(labels));

    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );
  });

  testWidgets('the dropdown carries the township-name toggle', (tester) async {
    final labels = ValueNotifier<bool>(true);
    await tester.pumpWidget(_wrap(labels));

    final l10n = await _l10n();
    expect(find.text(l10n.mapTownLabels), findsNothing);

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.mapTownLabels), findsOneWidget);
    // On by default: the box starts ticked.
    expect(find.byIcon(Icons.check_box), findsOneWidget);
  });

  testWidgets('tapping the row flips the shared setting', (tester) async {
    final labels = ValueNotifier<bool>(true);
    final flipped = <bool>[];
    await tester.pumpWidget(_wrap(labels, onChanged: flipped.add));

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapTownLabels));
    await tester.pumpAndSettle();

    // The scaffold owns the value; the menu only reports the flip.
    expect(flipped, [false]);
  });

  testWidgets('the chip marks itself once the labels are switched off', (
    tester,
  ) async {
    final labels = ValueNotifier<bool>(false);
    await tester.pumpWidget(_wrap(labels));

    // Off is a deviation from the default, so the chip carries the dot.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );
  });
}
