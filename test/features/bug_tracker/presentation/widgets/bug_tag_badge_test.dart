/// The tracker's tag vocabulary and its two renderings.
///
/// [BugTagKind.of] is the single seam between whatever a payload actually
/// contains — a canonical slug, Discord's raw "臭蟲 bug", or a body replayed
/// from the offline store predating canonicalisation — and the badge that
/// gets painted. A tag this doesn't recognise still has to render something:
/// falling through to [BugTagKind.other] shows the raw slug rather than
/// inventing a label or, worse, an icon that implies a state (fixed, invalid,
/// a security hole) the tag never claimed. [BugTagFilterChip]'s unselected
/// state is deliberately the same neutral grey for every tag — only the
/// selected state may show the tag's own accent — so an all-grey filter row
/// is never mistaken for "everything here is a bug".
library;

import 'package:dpip/features/bug_tracker/presentation/widgets/bug_tag_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BugTagKind.of', () {
    test('matches canonical slugs case-insensitively', () {
      expect(BugTagKind.of('bug'), BugTagKind.bug);
      expect(BugTagKind.of('BUG'), BugTagKind.bug);
      expect(BugTagKind.of('in_triage'), BugTagKind.inTriage);
      expect(BugTagKind.of('vulnerability'), BugTagKind.vulnerability);
    });

    test(
      "takes the slug after the last space, for Discord's bilingual form",
      () {
        expect(BugTagKind.of('臭蟲 bug'), BugTagKind.bug);
        expect(BugTagKind.of('已確認 confirmed'), BugTagKind.confirmed);
      },
    );

    test('trims surrounding whitespace before matching', () {
      expect(BugTagKind.of('  bug  '), BugTagKind.bug);
    });

    test('falls back to a whole-string Chinese match with no slug present', () {
      expect(BugTagKind.of('已解決'), BugTagKind.fixed);
      expect(BugTagKind.of('無法解決'), BugTagKind.wontfix);
      expect(BugTagKind.of('漏洞'), BugTagKind.vulnerability);
    });

    test('an unrecognized tag is other, not a crash or a guess', () {
      expect(BugTagKind.of('es_net_wave'), BugTagKind.other);
      expect(BugTagKind.of(''), BugTagKind.other);
    });
  });

  group('bugTagLabel', () {
    test(
      'other returns the raw tag verbatim; every other kind a fixed label',
      () {
        expect(bugTagLabel(BugTagKind.other, 'es_net_wave'), 'es_net_wave');
        expect(bugTagLabel(BugTagKind.bug, 'bug'), '錯誤');
        expect(bugTagLabel(BugTagKind.api, 'api'), 'API');
      },
    );
  });

  group('bugTagAccent', () {
    test('gives each kind a distinct, stable hue', () {
      expect(bugTagAccent(BugTagKind.bug), const Color(0xFFD1242F));
      expect(bugTagAccent(BugTagKind.fixed), const Color(0xFF1A7F37));
      expect(bugTagAccent(BugTagKind.other), const Color(0xFF6E7781));
    });
  });

  group('BugTagBadge', () {
    testWidgets('a known tag shows its icon and formal label', (tester) async {
      await tester.pumpWidget(_wrap(const BugTagBadge(tag: 'bug')));

      expect(find.text('錯誤'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    });

    testWidgets('an unrecognized tag shows the raw slug with no icon', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BugTagBadge(tag: 'es_net_wave')));

      expect(find.text('es_net_wave'), findsOneWidget);
      // BugTagKind.other has no icon — showing one would claim a state
      // (fixed, invalid, a vulnerability) the tag never asserted.
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('BugTagFilterChip', () {
    testWidgets('unselected is neutral grey regardless of the tag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          BugTagFilterChip(tag: 'bug', selected: false, onSelected: (_) {}),
        ),
      );

      final colors = Theme.of(tester.element(find.byType(BugTagFilterChip)))
          .colorScheme;
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, colors.surfaceContainerHighest);
    });

    testWidgets("selected adopts the tag's own accent", (tester) async {
      await tester.pumpWidget(
        _wrap(BugTagFilterChip(tag: 'bug', selected: true, onSelected: (_) {})),
      );

      expect(find.text('錯誤'), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    });

    testWidgets('tapping calls onSelected with the flipped state', (
      tester,
    ) async {
      bool? selected;
      await tester.pumpWidget(
        _wrap(
          BugTagFilterChip(
            tag: 'bug',
            selected: false,
            onSelected: (value) => selected = value,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(selected, isTrue);
    });
  });
}
