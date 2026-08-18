/// The support call to action's gold.
///
/// The one place in DPIP that asks the user for money, and the only place with
/// a colour outside the [ColorScheme]. That is deliberate: the scheme's roles
/// are generated from one seed so that everything in the app looks like one
/// app, which is exactly why nothing drawn from them can read as *paid* — a
/// primary-tinted card is just another card. Gold is the one accent that has
/// to come from outside the system to do its job.
///
/// It is two palettes, not one colour with an opacity. A single gold cannot
/// work in both themes: on a white page a bright gold has no contrast to sit
/// on, and on a near-black page a deep gold turns to mud. So the light palette
/// is a warm champagne wash under a deep bronze ink, and the dark one is a
/// low, warm brown-gold under a bright ink — the same *material* under
/// different light, rather than the same numbers twice.
///
/// Every pair is checked against what it sits on. The title and body clear
/// 8.6:1 on the fill in both themes, and the badge's mark clears 4.5:1 on the
/// badge — so nothing here needs a scrim, and the card is legible before the
/// gold is doing any work at all.
/// The literals below are the *standard-vision* palette; each one is routed
/// through `.vision` at its definition, so the gold is recoloured with the rest
/// of the app when a colour-vision correction is on. Because the transform is
/// not a compile-time constant, the two palettes are getters rather than
/// `static const` — they are rebuilt per call, from `build`, where the current
/// setting is what matters.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:flutter/material.dart';

/// The gold pair for one brightness.
@immutable
class AppGold {
  const AppGold({
    required this.fill,
    required this.ink,
    required this.badge,
    required this.onBadge,
    required this.edge,
  });

  /// The card's flat fill — one stop now, not a gradient: the support card
  /// sits on the same tonal plane as its neighbours, and the ranking is
  /// carried by the gold colour alone.
  final Color fill;

  /// Title and body ink on [fill].
  final Color ink;

  /// The filled circular badge, and the mark inside it — the strongest
  /// statement of the gold, so it carries the most saturated step.
  final Color badge;
  final Color onBadge;

  /// Hairline along the card's edge, catching the light at the top.
  final Color edge;

  /// Champagne on white: the fill has to be pale enough for dark ink, so the
  /// *ink* carries the metal — a deep bronze reads as gold leaf where a bright
  /// yellow would read as a highlighter.
  static AppGold get light => AppGold(
    fill: const Color(0xFFFDF2D0).vision,
    ink: const Color(0xFF4A3208).vision,
    badge: const Color(0xFF87610F).vision,
    onBadge: const Color(0xFFFFF8E6).vision,
    edge: const Color(0x33A9822B).vision,
  );

  /// Deep amber on near-black: the fill carries the metal here, because a pale
  /// champagne on a dark page reads as plain cream. The ink lifts to a light
  /// gold so it stays legible on it.
  static AppGold get dark => AppGold(
    fill: const Color(0xFF4A3811).vision,
    ink: const Color(0xFFF7DFA5).vision,
    badge: const Color(0xFFE8C46A).vision,
    onBadge: const Color(0xFF3A2A06).vision,
    edge: const Color(0x40E8C46A).vision,
  );

  /// The palette for the ambient theme.
  static AppGold of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
