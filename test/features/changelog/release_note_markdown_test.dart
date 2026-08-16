import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:dpip/features/changelog/presentation/widgets/release_note_markdown.dart';

/// The shape a generated note actually has: an italic caveat, `###` sections,
/// and entries that open with platform tags.
const _note = '''
_快照，取自 main 的 `290bba4e`。未經審查，可能有問題。_

### 🌟 新功能

- ![Android](https://raw.githubusercontent.com/x/y/main/.github/assets/android.svg) ![iOS](https://raw.githubusercontent.com/x/y/main/.github/assets/ios.svg) 更新日誌會用你自己的語言顯示 — @whes1015 · `26w33a`

### 🐞 錯誤修正

- ![iOS](https://raw.githubusercontent.com/x/y/main/.github/assets/ios.svg) 修正拖曳雷達時間軸會跟不上手指 — @whes1015
''';

/// The style sheet, built the way a page builds it — from `Theme.of(context)`.
///
/// A bare `ThemeData` carries no font sizes at all: they are resolved against
/// the platform when a `MaterialApp` builds. Passing the unresolved object
/// would test a sheet whose every `fontSize` is null, which is to say nothing.
MarkdownStyleSheet _sheetFrom(BuildContext context) {
  final theme = Theme.of(context);
  return releaseNoteStyleSheet(
    theme,
    theme.colorScheme,
    theme.colorScheme.primary,
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(
            builder: (context) => MarkdownBody(
              data: _note,
              styleSheet: _sheetFrom(context),
              imageBuilder: platformTagIcon,
              builders: releaseNoteBuilders(Theme.of(context).colorScheme),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('platform tags are icons, not network images', (tester) async {
    await _pump(tester);
    // Three tags across two entries. An Image here would be a fetch on a
    // screen that exists to be read with the network down.
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.android), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsNWidgets(2));
  });

  testWidgets('a tag and the words after it stay on one line', (tester) async {
    await _pump(tester);
    // The regression this guards: MarkdownBuilder only merges inline children
    // it can pull a span out of, so an Icon returned bare became its own item
    // in the Wrap and pushed the entry's sentence onto the next line. Both
    // tags and the sentence must end up inside the *same* RichText.
    final entry = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((w) => w.text.toPlainText().contains('更新日誌會用你自己的語言'));
    var placeholders = 0;
    entry.text.visitChildren((span) {
      if (span is WidgetSpan) placeholders++;
      return true;
    });
    expect(
      placeholders,
      2,
      reason: 'both platform tags belong in the entry paragraph itself',
    );
  });

  testWidgets('each section heading is separated by a rule', (tester) async {
    await _pump(tester);
    // Without it a note reads as one list with bold lines scattered through
    // it — three short lists in a row need the separation to be visible.
    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.textContaining('🌟 新功能'), findsOneWidget);
    expect(find.textContaining('🐞 錯誤修正'), findsOneWidget);
  });

  testWidgets('a section heading outranks the entries under it', (
    tester,
  ) async {
    // The note's only structural heading is `###`. Rendering it at the size of
    // the entries beneath it is what made the whole note read flat — three
    // short lists with some bold lines scattered through them.
    late MarkdownStyleSheet sheet;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (context) {
            sheet = _sheetFrom(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(sheet.h3!.fontWeight, FontWeight.w800);
    expect(sheet.h3!.fontSize!, greaterThan(sheet.p!.fontSize!));
    // The caveat line is a caption, not a paragraph.
    expect(sheet.em!.fontSize!, lessThan(sheet.p!.fontSize!));
  });
}
