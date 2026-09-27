/// The astronomy pages' shared display primitives: the rounded card, the
/// divided reading list, and the dawn/dusk time-span row.
///
/// [AstroReadings] draws a divider only *between* rows (`if (index > 0)`) — an
/// off-by-one here either draws a leading divider above the first reading or
/// drops the one that should separate the last two, and both are easy to miss
/// by eye in a design review. [AstroSpan] joins two already-localised times
/// with a literal en dash tagged `l10n-ignore`, which means the ARB pipeline
/// never sees this string and only a literal-character assertion in a test
/// can tell an en dash from a hyphen that looks the same at a glance.
library;

import 'package:dpip/features/data/presentation/widgets/astro_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('AstroCard renders its child inside the rounded surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AstroCard(child: Text('astro content'))),
    );

    expect(find.text('astro content'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AstroCard),
        matching: find.byType(DecoratedBox),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'AstroReadings shows one row per reading and a Divider only between '
    'rows, never leading or trailing',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AstroReadings(
            rows: [
              (Icons.wb_sunny, 'Sunrise', '06:12'),
              (Icons.wb_twilight, 'Sunset', '18:04'),
              (Icons.nightlight, 'Moonrise', '20:31'),
            ],
          ),
        ),
      );

      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('06:12'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('Moonrise'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
      // 3 rows -> exactly 2 separators: none leading, none trailing.
      expect(find.byType(Divider), findsNWidgets(2));
    },
  );

  testWidgets('AstroReadings with a single row draws no divider at all', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AstroReadings(rows: [(Icons.wb_sunny, 'Sunrise', '06:12')])),
    );

    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('AstroSpan joins the two times with a literal en dash', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const AstroSpan(
          icon: Icons.wb_twilight,
          label: 'Civil twilight',
          from: '06:12',
          to: '06:38',
        ),
      ),
    );

    expect(find.text('Civil twilight'), findsOneWidget);
    // U+2013 EN DASH, not a hyphen-minus — the exact character that ships,
    // since this string bypasses AppLocalizations entirely.
    expect(find.text('06:12 – 06:38'), findsOneWidget);
  });
}
