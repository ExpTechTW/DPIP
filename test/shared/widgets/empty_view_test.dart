/// Empty is a successful outcome. The message and the icon have to both be
/// on screen, or a list that came back empty looks like it never loaded.
library;

import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty view shows its icon and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyView(icon: Icons.inbox_outlined, message: 'Nothing here'),
      ),
    );
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('section header keeps a trailing action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SectionHeader(
          'Places',
          trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
        ),
      ),
    );
    expect(find.text('Places'), findsOneWidget);
    expect(find.byIcon(Icons.sort), findsOneWidget);
  });
}
