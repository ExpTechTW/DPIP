import 'dart:convert';

import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dpip/features/meshtastic/presentation/pages/meshtastic_page.dart';

/// Drives the real composer through a widget, since the formatter it uses is
/// private to the page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the budget keeps the documented 5% headroom', () {
    expect(
      MeshPorts.maxTextBytes,
      (MeshPorts.maxPayloadBytes * (1 - MeshPorts.payloadHeadroom)).floor(),
    );
    expect(MeshPorts.maxTextBytes, 221);
  });

  testWidgets('caps input by bytes, not characters', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            inputFormatters: composerInputFormatters,
          ),
        ),
      ),
    );

    // 100 Chinese characters = 300 UTF-8 bytes: a character-based cap would
    // have accepted every one of them.
    await tester.enterText(find.byType(TextField), '測' * 100);
    final kept = controller.text;
    expect(utf8.encode(kept).length, lessThanOrEqualTo(MeshPorts.maxTextBytes));
    expect(kept.characters.length, 73); // 73 × 3 bytes = 219
  });

  testWidgets('fills the budget exactly with single-byte text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            inputFormatters: composerInputFormatters,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'a' * 300);
    expect(controller.text.length, MeshPorts.maxTextBytes);
  });

  testWidgets('never splits an emoji in half', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            inputFormatters: composerInputFormatters,
          ),
        ),
      ),
    );

    // 4 bytes each; 56 of them is 224 bytes, so the cut lands mid-run.
    await tester.enterText(find.byType(TextField), '😀' * 56);
    expect(
      utf8.encode(controller.text).length,
      lessThanOrEqualTo(MeshPorts.maxTextBytes),
    );
    // A truncation that cut code units would leave a lone surrogate.
    expect(controller.text.contains('�'), isFalse);
    expect(controller.text.characters.every((c) => c == '😀'), isTrue);
  });
}
