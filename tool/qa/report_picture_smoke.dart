import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/native_library.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'report_picture_fixture.dart';
import 'report_picture_native_info.dart';

// Alternate entry point used by tool/run.sh. No app navigation is registered.
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final status = ValueNotifier('RUNNING');
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: status,
          builder: (context, value, _) => Text('REPORT_PICTURE_SMOKE $value'),
        ),
      ),
    ),
  );
  await binding.endOfFrame;
  try {
    status.value = 'PASS ${await _smoke()}';
    Log.info('REPORT_PICTURE_SMOKE ${status.value}');
  } catch (error, stack) {
    status.value = 'FAIL $error';
    Log.error('REPORT_PICTURE_SMOKE FAIL', error, stack);
    rethrow;
  }
}

Future<String> _smoke() async {
  const expected = String.fromEnvironment(
    'DPIP_REPORT_PICTURE_EXPECT',
    defaultValue: 'ready',
  );
  final format = EqShareFormat.values.byName(
    const String.fromEnvironment(
      'DPIP_REPORT_PICTURE_SMOKE_FORMAT',
      defaultValue: 'landscape16By9',
    ),
  );
  final dimensions = '${format.width}x${format.height}';
  final opened = await ReportPicture.open();
  if (expected != 'ready') {
    final reason = ReportPictureFailureReason.values.byName(expected);
    _requireFailure(opened, reason);
    return 'open=$expected';
  }
  final picture = _requireValue(opened);

  try {
    final library = _requireValue(
      NativeLibrary.open(ReportPicture.libraryName),
    );
    final (abi, capabilities) = readReportPictureAbi(library);
    const storySymbols = [
      'eqr_qa_render_story_png_v1',
      'eqr_qa_render_story_png_v2',
    ];
    final symbols = [
      ...reportPictureAbiSymbols,
      reportPictureOptionsSymbol,
      'eqr_render_share_png_v3',
      if (reportPictureStoryQa) ...storySymbols,
    ];
    for (final symbol in symbols) {
      _check(library.providesSymbol(symbol), 'Missing $symbol');
    }
    for (final symbol in storySymbols) {
      _check(
        library.providesSymbol(symbol) == reportPictureStoryQa,
        'Unexpected $symbol for this build',
      );
    }
    _check(
      abi == 0x00010004 &&
          capabilities == (reportPictureStoryQa ? 0x1b1f : 0xb1f),
      'Unexpected native ABI or capabilities: $abi/$capabilities',
    );

    final (bytes, sourceEvidence) = _loadFixture();
    final fixtureHash = sha256.convert(bytes);

    final first = picture.renderSharePngV3(bytes, format: format);
    final invalid = picture.renderSharePngV3(
      Uint8List.fromList(utf8.encode('{')),
      format: format,
    );
    final callerBuffer = Uint8List.fromList(bytes);
    final recovered = picture.renderSharePngV3(callerBuffer, format: format);
    callerBuffer.fillRange(0, callerBuffer.length, 0);

    var completed = false;
    unawaited(
      first.then<void>((_) {
        completed = true;
      }),
    );
    await Future<void>.delayed(Duration.zero);
    _check(
      !completed,
      'The root isolate did not yield while the render was pending',
    );

    final dispose = picture.dispose();
    _requireFailure(
      await picture.renderSharePngV3(bytes, format: format),
      ReportPictureFailureReason.disposed,
    );
    final png = _requireValue(await first);
    _requireFailure(
      await invalid,
      ReportPictureFailureReason.invalidInput,
      nativeStatus: -1,
    );
    final nextPng = _requireValue(await recovered);
    await dispose;

    // Decode the original result after subsequent renders and native disposal.
    _check(
      listEquals(png, nextPng),
      'Identical requests returned different PNG bytes',
    );
    await _checkPng(png, EqTheme.light, format);

    final reopened = _requireValue(await ReportPicture.open());
    final Uint8List dark;
    try {
      _requireFailure(
        await reopened.renderSharePngV3(
          Uint8List(1024 * 1024 + 1),
          format: format,
        ),
        ReportPictureFailureReason.limitExceeded,
      );
      final badVersion = utf8
          .decode(bytes)
          .replaceFirst(
            RegExp(r'"schema_version":\s*3\b'),
            '"schema_version":2',
          );
      _requireFailure(
        await reopened.renderSharePngV3(
          utf8.encode(badVersion),
          format: format,
        ),
        ReportPictureFailureReason.unsupportedVersion,
        nativeStatus: -2,
      );
      for (final alternate in EqShareFormat.values.where(
        (item) => item != format,
      )) {
        final rendered = await reopened.renderSharePngV3(
          bytes,
          format: alternate,
        );
        if (alternate == EqShareFormat.story9By16 && !reportPictureStoryQa) {
          _requireFailure(
            rendered,
            ReportPictureFailureReason.unsupportedFeature,
          );
        } else {
          await _checkPng(_requireValue(rendered), EqTheme.light, alternate);
        }
      }
      dark = _requireValue(
        await reopened.renderSharePngV3(
          bytes,
          theme: EqTheme.dark,
          format: format,
        ),
      );
      final nextDark = _requireValue(
        await reopened.renderSharePngV3(
          bytes,
          theme: EqTheme.dark,
          format: format,
        ),
      );
      _check(
        listEquals(dark, nextDark),
        'Dark PNG bytes were not deterministic',
      );
      _check(!listEquals(png, dark), 'Dark theme did not change the output');
    } finally {
      await reopened.dispose();
    }
    await _checkPng(dark, EqTheme.dark, format);
    final documents = await getApplicationDocumentsDirectory();
    final filename = switch (format) {
      EqShareFormat.landscape16By9 => 'report-picture',
      EqShareFormat.information4By5 => 'report-picture-4x5',
      EqShareFormat.story9By16 => 'report-picture-story',
    };
    for (final (theme, bytes) in [(EqTheme.light, png), (EqTheme.dark, dark)]) {
      final output = File('${documents.path}/$filename-${theme.name}.png');
      await output.writeAsBytes(bytes, flush: true);
      Log.info(
        'REPORT_PICTURE_PNG theme=${theme.name} dimensions=$dimensions '
        'bytes=${bytes.length} sha256=${sha256.convert(bytes)} file=${output.path}',
      );
    }
    return 'ABI=${abi >> 16}.${abi & 0xffff} '
        'caps=0x${capabilities.toRadixString(16)} exports=${symbols.length} decoded=$dimensions '
        'fixture_sha256=$fixtureHash themes=light,dark deterministic=pass '
        '$sourceEvidence '
        'root-event=responsive invalid=-1 version=-2 retry=pass dispose=pass reopen=pass';
  } finally {
    await picture.dispose();
  }
}

(Uint8List, String) _loadFixture() {
  final fixture = ReportPictureFixtures.loadVerified();
  final input = fixture.inputV3();
  try {
    ReportPictureFixtures.historicalV3();
    throw StateError('Unexpectedly accepted historical report');
  } on EarthquakeReportSourceException catch (error) {
    _check(
      error.code == EarthquakeReportSourceError.unsupportedProfile,
      'Unexpected historical source failure: $error',
    );
  }
  return (
    input.bytes,
    'report_id=${input.snapshot.reportId} '
        'source_sha256=${input.snapshot.bodySha256} '
        'content_sha256=${input.contentSha256} '
        'stations=${fixture.stationCount} historical=pass',
  );
}

Future<void> _checkPng(
  Uint8List png,
  EqTheme theme,
  EqShareFormat format,
) async {
  _check(
    png.length >= 8 &&
        listEquals(png.sublist(0, 8), const [137, 80, 78, 71, 13, 10, 26, 10]),
    '${theme.name}: unexpected PNG signature',
  );
  final codec = await ui.instantiateImageCodec(png);
  try {
    final frame = await codec.getNextFrame();
    try {
      _check(
        frame.image.width == format.width &&
            frame.image.height == format.height,
        '${theme.name}: unexpected decoded dimensions',
      );
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

T _requireValue<T>(Result<T> result) => result.when(
  ok: (value) => value,
  err: (failure) => throw StateError(failure.message),
);

void _requireFailure(
  Result<Object?> result,
  ReportPictureFailureReason reason, {
  int? nativeStatus,
}) {
  final failure = result.failureOrNull;
  _check(
    failure is ReportPictureFailure &&
        failure.reason == reason &&
        failure.nativeStatus == nativeStatus,
    'Expected ${reason.name} ($nativeStatus), got ${failure?.message}',
  );
}

void _check(bool condition, String message) {
  if (!condition) throw StateError(message);
}
