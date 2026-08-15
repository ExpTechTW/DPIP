/// The support callout's gold stays legible in both themes.
///
/// Gold is the one colour in the app not generated from the seed, so nothing
/// else keeps it honest: the [ColorScheme] guarantees its own on-colours, and
/// these have no such guarantee. A gold that is tweaked to look richer is one
/// edit away from ink that no longer reads on it — and this is the card that
/// asks the user for money, which is the worst place to be unreadable.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_gold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final (name, gold) in [
    ('light', AppGold.light),
    ('dark', AppGold.dark),
  ]) {
    group(name, () {
      test('ink reads on both ends of the gradient', () {
        // Both ends: a gradient that only passes at one end is unreadable
        // across half the card.
        for (final (where, fill) in [
          ('start', gold.fillStart),
          ('end', gold.fillEnd),
        ]) {
          expect(
            _contrast(gold.ink, fill),
            greaterThanOrEqualTo(4.5),
            reason: '$name ink on the gradient $where',
          );
        }
      });

      test('the badge mark reads on the badge', () {
        expect(_contrast(gold.onBadge, gold.badge), greaterThanOrEqualTo(4.5));
      });

      test('the badge separates from the card it sits on', () {
        // A filled badge is a non-text element: 3:1 is what makes it a shape
        // rather than a smudge on the gradient behind it.
        expect(_contrast(gold.badge, gold.fillEnd), greaterThanOrEqualTo(3));
      });
    });
  }

  test('the two palettes are genuinely different material', () {
    // The failure this guards is the tempting one: reuse the light gold in
    // dark mode with an opacity. A dark fill that is not actually dark makes
    // the card glare on a near-black page.
    expect(
      _luminance(AppGold.light.fillEnd),
      greaterThan(_luminance(AppGold.dark.fillEnd) * 4),
      reason: 'the dark fill is not meaningfully darker',
    );
    expect(
      _luminance(AppGold.dark.ink),
      greaterThan(_luminance(AppGold.light.ink)),
      reason: 'dark mode needs light ink, not the light theme\'s bronze',
    );
  });

  testWidgets('of() follows the ambient theme', (tester) async {
    late AppGold seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            seen = AppGold.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.ink, AppGold.dark.ink);
  });
}
