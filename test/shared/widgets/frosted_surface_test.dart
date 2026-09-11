/// The frost's one platform rule: Android never blurs what is under it.
library;

import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness() => const MaterialApp(
    home: Scaffold(body: FrostedSurface(child: Text('chrome'))),
  );

  // The binding checks foundation debug variables when a test body ends —
  // before any tearDown — so each test restores the override itself.
  testWidgets('Android draws a flat tint — no backdrop filter', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(harness());
    debugDefaultTargetPlatformOverride = null;

    expect(
      find.byType(BackdropFilter),
      findsNothing,
      reason:
          'over a platform-view map the blur is blind (HCPP) or re-rasterises '
          'the whole scene per map frame (virtual display) — see '
          'mapChromeBlursBackdrop',
    );
    final tint = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(FrostedSurface),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(
      tint.color.a,
      closeTo(kMapFrostSurfaceAlpha + kMapFrostFlatAlphaBoost, 1e-6),
      reason: 'a flat tint carries a little more opacity than a frosted one',
    );
  });

  testWidgets('iOS blurs, reusing one filter across rebuilds', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(harness());
    final first = tester.widget<BackdropFilter>(find.byType(BackdropFilter));

    await tester.pumpWidget(harness());
    final second = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    debugDefaultTargetPlatformOverride = null;

    expect(
      identical(first.filter, second.filter),
      isTrue,
      reason:
          'ImageFilter has no value equality — a fresh one per build would '
          'recomposite the backdrop even when nothing under it moved',
    );
  });
}
