import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/image_saver.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

Future<Uint8List> _fixturePng(
  ui.Color color, [
  EqShareFormat format = EqShareFormat.information4By5,
]) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(color, ui.BlendMode.src);
  final picture = recorder.endRecording();
  try {
    final image = picture.toImageSync(format.width, format.height);
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

class _Saver implements ImageSaver {
  Object? error;
  Uint8List? saved;

  @override
  Future<Result<void>> saveToGallery({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/png',
  }) async {
    if (error case final error?) throw error;
    saved = bytes;
    return const Ok(null);
  }

  @override
  Future<Result<void>> ensurePermission() async => const Ok(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = EarthquakeReportSnapshot.decode(
    File(
      'test/features/earthquake/domain/fixtures/share_input/exptech-modern.json',
    ).readAsBytesSync(),
    requestedReportId: '115000-2026-0422-111524',
  );
  EarthquakeShareInputV2 verified(EarthquakeReportSnapshot snapshot) =>
      adaptEarthquakeShareSnapshot(
        snapshot,
        identities: VerifiedEarthquakeReportIdentities(
          bodySha256: snapshot.bodySha256,
          scale: ReportIntensityScale.cwa2020,
          magnitudeIsMl: true,
          countyCodes: const {'臺東縣': '10014', '花蓮縣': '10015'},
          stationCodes: const {
            ('臺東縣', '成功'): 'CHK',
            ('臺東縣', '長濱'): 'ECB',
            ('臺東縣', '池上'): 'ECS',
            ('臺東縣', '東河'): 'EDH',
            ('花蓮縣', '紅葉'): 'EHY',
          },
        ),
      ) as EarthquakeShareInputV2;
  final input = verified(source);
  final l10n = lookupAppLocalizations(kHomeLocale);
  final retry = find.text(l10n.commonRetry);
  final save = find.text(l10n.reportShareSave);
  final shareButton = find.text(l10n.reportShareSend);
  late Uint8List lightPng;
  late Uint8List darkPng;

  setUpAll(() async {
    lightPng = await _fixturePng(const ui.Color(0xFFFFFFFF));
    darkPng = await _fixturePng(const ui.Color(0xFF000000));
  });

  Widget dialog({
    Future<Result<EarthquakeShareInput>> Function()? load,
    Future<Result<ReportPicture>> Function()? open,
    EarthquakeReport? report,
    ImageSaver? saver,
    Future<ShareResult> Function(ShareParams)? share,
    Locale locale = kHomeLocale,
    Duration timeout = const Duration(seconds: 20),
  }) => MaterialApp(
    locale: locale,
    supportedLocales: appSupportedLocales,
    localizationsDelegates: appLocalizationsDelegates,
    home: Scaffold(
      body: EarthquakeShareSheet(
        report: report ?? source.report,
        loadInput: load ?? () async => Ok(input),
        openRenderer: open ?? () async => throw StateError('Unexpected open'),
        saver: saver ?? _Saver(),
        isReportCurrent: () => true,
        share: share,
        renderTimeout: timeout,
      ),
    ),
  );

  ui.Image preview(WidgetTester tester) =>
      tester.widget<RawImage>(find.byType(RawImage)).image!;

  Future<int> previewPixel(WidgetTester tester) async {
    final image = preview(tester);
    final pixel = await tester.runAsync(image.toByteData);
    return pixel!.getUint32(0);
  }

  bool canSave(WidgetTester tester) {
    final button = find.ancestor(
      of: save,
      matching: find.bySubtype<OutlinedButton>(),
    );
    return button.evaluate().isNotEmpty &&
        tester.widget<OutlinedButton>(button).onPressed != null;
  }

  Future<void> waitForImage(WidgetTester tester) async {
    // The engine decodes asynchronously outside the fake clock.
    for (var i = 0; i < 100; i++) {
      await tester.pump();
      if (canSave(tester)) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    expect(canSave(tester), isTrue);
  }

  testWidgets('both themes export the identical bytes shown in the preview', (
    tester,
  ) async {
    final saver = _Saver();
    final requests = <(EqTheme, EqShareFormat)>[];
    Uint8List? shared;
    var released = 0;
    await tester.pumpWidget(
      dialog(
        saver: saver,
        open: () async => Ok(
          ReportPicture.forTesting((json, _, theme, format) async {
            expect(json, input.bytes);
            requests.add((theme, format));
            return theme == EqTheme.light ? lightPng : darkPng;
          }, () => released++),
        ),
        share: (params) async {
          expect(params.files!.single.mimeType, 'image/png');
          expect(params.fileNameOverrides!.single, endsWith('-dark-4x5.png'));
          expect(params.sharePositionOrigin!.isEmpty, isFalse);
          shared = await params.files!.single.readAsBytes();
          return const ShareResult('', ShareResultStatus.dismissed);
        },
      ),
    );
    await waitForImage(tester);
    expect(await previewPixel(tester), 0xFFFFFFFF);
    final copy = find.text(l10n.reportShareCopy);
    expect(tester.getCenter(copy).dy, tester.getCenter(save).dy);
    expect(tester.getCenter(save).dy, tester.getCenter(shareButton).dy);

    await tester.tap(find.text(l10n.themeDark));
    await tester.pump();
    expect(find.byType(RawImage), findsOneWidget);
    expect(await previewPixel(tester), 0xFFFFFFFF);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(canSave(tester), isFalse);
    await waitForImage(tester);
    expect(await previewPixel(tester), 0x000000FF);
    await tester.tap(save);
    await tester.pump();
    expect(saver.saved, darkPng);
    expect(find.text(l10n.reportDetailImageSaved), findsOneWidget);
    await tester.tap(shareButton);
    await tester.pump();
    expect(shared, darkPng);
    expect(find.text(l10n.reportShareExportFailed), findsNothing);
    expect(released, 2);
    expect(requests, [
      (EqTheme.light, EqShareFormat.information4By5),
      (EqTheme.dark, EqShareFormat.information4By5),
    ]);
  });

  testWidgets('switching layout and map style invalidates previous export', (
    tester,
  ) async {
    final landscape = await tester.runAsync(
      () =>
          _fixturePng(const ui.Color(0xffeeeeee), EqShareFormat.landscape16By9),
    );
    final requests = <(EqShareFormat, EqMapMode, EqTheme)>[];
    final stationResult = Completer<Uint8List>();
    final saver = _Saver();
    await tester.pumpWidget(
      dialog(
        saver: saver,
        open: () async => Ok(
          ReportPicture.forTesting((_, mode, theme, format) async {
            requests.add((format, mode, theme));
            if (mode == EqMapMode.stations) return stationResult.future;
            return format == EqShareFormat.landscape16By9
                ? landscape!
                : lightPng;
          }, () {}),
        ),
      ),
    );
    await waitForImage(tester);
    expect(find.text('測站'), findsNothing);
    final layoutChoice = find.text('16:9');
    final choicePosition = tester.getTopLeft(layoutChoice);
    await tester.tap(layoutChoice);
    await waitForImage(tester);
    await tester.tap(find.text('測站'));
    await tester.pump();
    expect(canSave(tester), isFalse);
    expect(tester.getTopLeft(layoutChoice), choicePosition);
    await tester.tap(find.text('4:5'));
    await tester.pump();
    stationResult.complete(landscape!);
    await waitForImage(tester);
    await tester.tap(save);
    await tester.pump();
    expect(saver.saved, lightPng);
    expect(requests, [
      (EqShareFormat.information4By5, EqMapMode.cluster, EqTheme.light),
      (EqShareFormat.landscape16By9, EqMapMode.cluster, EqTheme.light),
      (EqShareFormat.landscape16By9, EqMapMode.stations, EqTheme.light),
    ]);
  });

  testWidgets('reuses completed format, mode and theme combinations', (
    tester,
  ) async {
    final landscape = await tester.runAsync(
      () =>
          _fixturePng(const ui.Color(0xffeeeeee), EqShareFormat.landscape16By9),
    );
    var renders = 0;
    await tester.pumpWidget(
      dialog(
        open: () async => Ok(
          ReportPicture.forTesting((_, _, theme, format) async {
            renders++;
            return format == EqShareFormat.landscape16By9
                ? landscape!
                : theme == EqTheme.light
                ? lightPng
                : darkPng;
          }, () {}),
        ),
      ),
    );
    await waitForImage(tester);
    expect(await previewPixel(tester), 0xFFFFFFFF);

    Future<void> select(String label) async {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pump();
      await waitForImage(tester);
    }

    await select('16:9');
    await select(l10n.reportShareStations);
    await select(l10n.themeDark);
    final landscapeWidth = preview(tester).width;
    await select(l10n.themeLight);
    await select(l10n.reportShareCluster);
    await select(l10n.reportShareStations);
    await select(l10n.themeDark);
    expect(preview(tester).width, landscapeWidth);
    expect(renders, 4);
    await select('4:5');
    expect(await previewPixel(tester), 0x000000FF);
    final darkCard = preview(tester);
    await tester.tap(find.text(l10n.themeLight));
    await tester.pump();
    expect(preview(tester), same(darkCard));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(canSave(tester), isFalse);
    await waitForImage(tester);
    expect(await previewPixel(tester), 0xFFFFFFFF);
    expect(renders, 5);

    // The preview's live bytes survive memory pressure, but other selections
    // need to render again.
    final observer = tester.state(
      find.byType(EarthquakeShareSheet),
    ) as WidgetsBindingObserver;
    final card = preview(tester);
    observer.didHaveMemoryPressure();
    expect(preview(tester), same(card));
    await select(l10n.themeDark);
    expect(renders, 6);
  });

  testWidgets('joining the same in-flight render skips a queued selection', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    final requests = <EqTheme>[];
    var releases = 0;
    await tester.pumpWidget(
      dialog(
        open: () async => Ok(
          ReportPicture.forTesting((_, _, theme, _) {
            requests.add(theme);
            return pending.future;
          }, () => releases++),
        ),
      ),
    );
    await tester.tap(find.text(l10n.themeDark));
    await tester.pump();
    await tester.tap(find.text(l10n.themeLight));
    await tester.pump();
    expect(requests, [EqTheme.light]);
    expect(canSave(tester), isFalse);
    pending.complete(lightPng);
    await waitForImage(tester);
    expect(await previewPixel(tester), 0xFFFFFFFF);
    expect(requests, [EqTheme.light]);
    expect(releases, 1);
  });

  testWidgets(
    'a new body hash invalidates the cache even with the same model',
    (tester) async {
      final revision = EarthquakeReportSnapshot.decode(
        Uint8List.fromList([
          ...File(
            'test/features/earthquake/domain/fixtures/share_input/exptech-modern.json',
          ).readAsBytesSync(),
          32,
        ]),
        requestedReportId: source.report.id,
      );
      expect(revision.report, source.report);
      final updated = verified(revision);
      expect(updated.bytes, input.bytes);
      var activeInput = input;
      var renders = 0;
      await tester.pumpWidget(
        dialog(
          load: () async => Ok(activeInput),
          open: () async => Ok(
            ReportPicture.forTesting((_, _, theme, _) async {
              renders++;
              return theme == EqTheme.light ? lightPng : darkPng;
            }, () {}),
          ),
        ),
      );
      await waitForImage(tester);
      await tester.tap(find.text(l10n.themeDark));
      await waitForImage(tester);
      expect(renders, 2);
      activeInput = updated;
      await tester.tap(find.text(l10n.themeLight));
      await waitForImage(tester);
      await tester.tap(find.text(l10n.themeDark));
      await waitForImage(tester);
      expect(renders, 4);
    },
  );

  testWidgets('failed images are not cached and a retry can succeed', (
    tester,
  ) async {
    var renders = 0;
    await tester.pumpWidget(
      dialog(
        open: () async => Ok(
          ReportPicture.forTesting((_, _, _, _) async {
            if (++renders == 1) throw StateError('render failed');
            return lightPng;
          }, () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.reportShareRenderFailed), findsOneWidget);
    await tester.tap(retry);
    await waitForImage(tester);
    expect(await previewPixel(tester), 0xFFFFFFFF);
    expect(renders, 2);
  });

  testWidgets('large text preserves accessible options and export actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2.5;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final saver = _Saver();
    try {
      await tester.pumpWidget(
        dialog(
          saver: saver,
          open: () async => Ok(
            ReportPicture.forTesting(
              (_, _, theme, _) async =>
                  theme == EqTheme.dark ? darkPng : lightPng,
              () {},
            ),
          ),
        ),
      );
      await waitForImage(tester);
      expect(
        find.text('9:16'),
        reportPictureStoryQa ? findsOneWidget : findsNothing,
      );
      final card = find.widgetWithText(ChoiceChip, '4:5');
      expect(
        tester.getSemantics(card).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );

      final dark = find.text(l10n.themeDark);
      await tester.ensureVisible(dark);
      await tester.tap(dark);
      await waitForImage(tester);
      expect(find.bySemanticsLabel(l10n.reportSharePreview), findsOneWidget);
      final savePosition = tester.getCenter(save);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();
      expect(tester.getCenter(save), savePosition);
      expect(save.hitTestable(), findsOneWidget);
      await tester.tap(save);
      await tester.pump();
      expect(saver.saved, darkPng);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('report replacement clears an earlier result and actions', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    var disposed = false;
    await tester.pumpWidget(
      dialog(
        open: () async => Ok(
          ReportPicture.forTesting(
            (_, _, _, _) => pending.future,
            () => disposed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    final historical = source.report.copyWith(id: '105006-2016-0206-035726');
    await tester.pumpWidget(
      dialog(
        report: historical,
        load: () async => Ok(adaptEarthquakeShareInput(historical)),
      ),
    );
    pending.complete(lightPng);
    await tester.pumpAndSettle();
    expect(disposed, isTrue);
    expect(find.text(l10n.reportShareUnsupportedReport), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
    expect(canSave(tester), isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: shareButton,
              matching: find.bySubtype<FilledButton>(),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('timeout discards an in-flight result and allows retry', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    var opens = 0;
    var releases = 0;
    await tester.pumpWidget(
      dialog(
        timeout: const Duration(seconds: 1),
        open: () async {
          final attempt = ++opens;
          return Ok(
            ReportPicture.forTesting(
              (_, _, _, _) async => attempt == 1 ? pending.future : darkPng,
              () => releases++,
            ),
          );
        },
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(l10n.reportShareTimeout), findsOneWidget);
    await tester.tap(retry);
    await tester.pump();
    expect(opens, 1);
    pending.complete(lightPng);
    await waitForImage(tester);
    expect(opens, 2);
    expect(releases, 2);
    expect(await previewPixel(tester), 0x000000FF);
  });

  testWidgets('closing during Rust work still releases the handle', (
    tester,
  ) async {
    final pending = Completer<Uint8List>();
    var released = false;
    await tester.pumpWidget(
      dialog(
        open: () async => Ok(
          ReportPicture.forTesting(
            (_, _, _, _) => pending.future,
            () => released = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(released, isFalse);
    pending.complete(lightPng);
    await tester.pump();
    expect(released, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unsupported locale does not load report evidence', (
    tester,
  ) async {
    await tester.pumpWidget(
      dialog(
        locale: const Locale('en'),
        load: () async => throw StateError('Unexpected source load'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        lookupAppLocalizations(const Locale('en'))
            .reportShareUnsupportedLanguage,
      ),
      findsOneWidget,
    );
  });

  for (final (reason, message) in [
    (
      ReportPictureFailureReason.unavailable,
      l10n.reportShareRendererUnavailable,
    ),
    (
      ReportPictureFailureReason.unsupportedAbi,
      l10n.reportShareRendererIncompatible,
    ),
    (
      ReportPictureFailureReason.unsupportedFeature,
      l10n.reportShareRendererIncompatible,
    ),
  ]) {
    testWidgets('shows a native ${reason.name} state', (tester) async {
      const error = 'Native image renderer unavailable in this test';
      await tester.pumpWidget(
        dialog(
          open: () async =>
              reason == ReportPictureFailureReason.unsupportedFeature
              ? Ok(
                  ReportPicture.forTesting(
                    (_, _, _, _) async =>
                        throw ReportPictureFailure(reason, error),
                    () {},
                  ),
                )
              : Err(ReportPictureFailure(reason, error)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(retry, findsNothing);
      expect(canSave(tester), isFalse);
    });
  }

  testWidgets('export failures keep the successful PNG available', (
    tester,
  ) async {
    final saver = _Saver()..error = PlatformException(code: 'write-failed');
    await tester.pumpWidget(
      dialog(
        saver: saver,
        open: () async =>
            Ok(ReportPicture.forTesting((_, _, _, _) async => lightPng, () {})),
        share: (_) async => throw PlatformException(code: 'share-failed'),
      ),
    );
    await waitForImage(tester);
    final image = preview(tester);
    await tester.tap(save);
    await tester.pump();
    expect(find.text(l10n.reportDetailImageSaveFailed), findsOneWidget);
    await tester.tap(shareButton);
    await tester.pump();
    expect(find.text(l10n.reportShareExportFailed), findsOneWidget);
    expect(preview(tester), same(image));

    saver.error = null;
    await tester.tap(save);
    await tester.pump();
    expect(saver.saved, lightPng);
    expect(find.text(l10n.reportDetailImageSaved), findsOneWidget);
  });

  for (final (reply, message) in [
    (true, '已複製圖片'),
    (false, null),
    (null, '無法複製圖片'),
  ]) {
    testWidgets('copy uses the current PNG and reports native reply $reply', (
      tester,
    ) async {
      const channel = MethodChannel('com.exptech.dpip/image_saver');
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (reply == null) throw PlatformException(code: 'copy_failed');
        return reply;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      var renders = 0;
      final writable = _Saver();
      await tester.pumpWidget(
        dialog(
          saver: writable,
          open: () async => Ok(
            ReportPicture.forTesting((_, _, _, _) async {
              renders++;
              return lightPng;
            }, () {}),
          ),
        ),
      );
      await waitForImage(tester);
      final image = preview(tester);
      final copy = find.text(l10n.reportShareCopy);
      final semantics = tester.ensureSemantics();
      try {
        expect(find.bySemanticsLabel(l10n.reportShareCopy), findsOneWidget);
      } finally {
        semantics.dispose();
      }
      await tester.tap(copy);
      await tester.pump();
      expect(calls.map((call) => call.method), ['copyPng']);
      expect(calls.single.arguments, lightPng);
      expect(writable.saved, isNull);
      expect(renders, 1);
      expect(preview(tester), same(image));
      expect(find.text('已複製圖片'), reply == true ? findsOneWidget : findsNothing);
      if (message != null) expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('a share sheet closed during gallery permission never saves', (
    tester,
  ) async {
    final permission = Completer<String>();
    const channel = MethodChannel('qa/earthquake-gallery');
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return call.method == 'request' ? permission.future : 'notDetermined';
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      dialog(
        saver: IosImageSaver(channel: channel, isSupportedPlatform: true),
        open: () async =>
            Ok(ReportPicture.forTesting((_, _, _, _) async => lightPng, () {})),
      ),
    );
    await waitForImage(tester);
    await tester.tap(save);
    await tester.pump();
    expect(calls, ['status', 'request']);
    await tester.pumpWidget(const SizedBox.shrink());
    permission.complete('granted');
    await tester.pump();
    expect(calls, ['status', 'request']);
  });
}
