import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/qa/report_picture_preview.dart';

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwM'
    'CAO+aX1sAAAAASUVORK5CYII=',
  );
  const unavailable = ReportPictureFailure(
    ReportPictureFailureReason.unavailable,
    'Native test library is missing',
  );

  PreviewImage image(EqTheme theme) => (
    png: png,
    width: 1,
    height: 1,
    sha256: 'test-${theme.name}',
    abi: 0x00010002,
    capabilities: 0x11f,
  );

  testWidgets('generates, compares repeated output and changes theme', (
    tester,
  ) async {
    final first = Completer<PreviewImage>();
    final requests = <EqTheme>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReportPicturePreview(
          generate: (scenario, theme) async {
            expect(scenario, PreviewScenario.verified);
            requests.add(theme);
            return requests.length == 1 ? first.future : image(theme);
          },
        ),
      ),
    );
    expect(find.text('等待產圖'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.text('產生 PNG'));
    // Even stale callbacks before a rebuild cannot start another request.
    await tester.tap(find.text('產生 PNG'));
    await tester.pump();
    expect(requests, [EqTheme.light]);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<SegmentedButton<EqTheme>>(
            find.byType(SegmentedButton<EqTheme>),
          )
          .onSelectionChanged,
      isNull,
    );

    first.complete(image(EqTheme.light));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('產圖成功'), findsOneWidget);
    expect(find.textContaining('1 × 1 px'), findsOneWidget);
    expect(find.textContaining('ABI 1.2 · Capabilities 0x11f'), findsOneWidget);

    await tester.tap(find.text('重新產生 PNG'));
    await tester.pumpAndSettle();
    expect(find.textContaining('與上一次同主題的 SHA-256 相同'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('產生 PNG'));
    await tester.pumpAndSettle();
    expect(find.textContaining('test-dark'), findsOneWidget);
    expect(find.textContaining('此主題首次產圖'), findsOneWidget);
    expect(requests, [EqTheme.light, EqTheme.light, EqTheme.dark]);
  });

  testWidgets('shows structured failure and retries the same request', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReportPicturePreview(
          generate: (scenario, theme) async {
            expect(scenario, PreviewScenario.verified);
            expect(theme, EqTheme.light);
            if (++calls == 1) throw unavailable;
            return image(theme);
          },
        ),
      ),
    );
    await tester.tap(find.text('產生 PNG'));
    await tester.pumpAndSettle();
    expect(find.text('產圖失敗'), findsOneWidget);
    expect(find.textContaining('原生渲染 · unavailable'), findsOneWidget);
    expect(find.textContaining(unavailable.message), findsOneWidget);
    await tester.tap(find.text('重試'));
    await tester.pumpAndSettle();
    expect(find.text('產圖成功'), findsOneWidget);
    expect(find.textContaining(unavailable.message), findsNothing);
    expect(calls, 2);
  });

  testWidgets('disposal ignores late results and releases the renderer', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    var released = 0;
    final renderer = ReportPicture.forTesting(
      (_, _, _) => pending.future,
      () => released++,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReportPicturePreview(
          generate: (_, theme) async {
            await renderPreviewPng(png, theme, open: () async => Ok(renderer));
            return image(theme);
          },
        ),
      ),
    );
    await tester.tap(find.text('產生 PNG'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(released, 0);
    pending.complete(png);
    await tester.pumpAndSettle();
    expect(released, 1);
    expect(tester.takeException(), isNull);
  });

  test('releases the renderer after a render failure', () async {
    var released = 0;
    final renderer = ReportPicture.forTesting(
      (_, _, _) async => throw unavailable,
      () => released++,
    );
    await expectLater(
      renderPreviewPng(png, EqTheme.light, open: () async => Ok(renderer)),
      throwsA(same(unavailable)),
    );
    expect(released, 1);
  });

  test('production Dart files do not refer to the QA entry point', () {
    final imports = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('report_picture_preview'),
        );
    expect(imports.map((file) => file.path), isEmpty);
  });
}
