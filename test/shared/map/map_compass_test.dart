import 'dart:math' as math;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_compass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(double bearing, VoidCallback onPressed) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: MapCompass(bearing: ValueNotifier(bearing), onPressed: onPressed),
      ),
    );
  }

  testWidgets('hidden while the map faces north (bearing ≈ 0)', (tester) async {
    await tester.pumpWidget(harness(0, () {}));

    expect(
      find.byType(MapCompass),
      findsOneWidget,
      reason: 'the widget itself is always in the tree',
    );
    expect(
      find.byIcon(Icons.navigation),
      findsNothing,
      reason: 'a north-facing map must not float an idle needle',
    );
  });

  testWidgets('needle appears once the camera turns', (tester) async {
    await tester.pumpWidget(harness(0, () {}));
    expect(find.byIcon(Icons.navigation), findsNothing);

    // Rotate the camera — only the compass rebuilds.
    await tester.pumpWidget(harness(45, () {}));

    expect(find.byIcon(Icons.navigation), findsOneWidget);
  });

  testWidgets('needle counter-rotates by the bearing', (tester) async {
    await tester.pumpWidget(harness(90, () {}));

    final transform = tester.widget<Transform>(
      find.ancestor(
        of: find.byIcon(Icons.navigation),
        matching: find.byType(Transform),
      ),
    );
    // Bearing 90° (camera turned east) ⇒ north sits 90° counter-clockwise from
    // the screen top, so the needle must rotate by -90° (pi / 2).
    expect(transform.transform, isNot(Matrix4.identity()));
    final angle = math.atan2(
      transform.transform.entry(1, 0),
      transform.transform.entry(0, 0),
    );
    expect(angle, closeTo(-math.pi / 2, 1e-6));
  });

  testWidgets('tap resets the camera', (tester) async {
    var reset = 0;
    await tester.pumpWidget(harness(120, () => reset++));

    await tester.tap(find.byIcon(Icons.navigation));
    await tester.pump();

    expect(reset, 1);
  });
}
