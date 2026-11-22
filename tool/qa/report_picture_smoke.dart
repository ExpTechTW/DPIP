import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/native_library.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

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
  final opened = await ReportPicture.open();
  if (expected != 'ready') {
    final reason = ReportPictureFailureReason.values.byName(expected);
    _requireFailure(opened, reason);
    return 'open=$expected';
  }
  final picture = _requireValue(opened);

  try {
    final abi = _readAbi();
    _check(
      abi == (0x00010002, 0x11f),
      'Unexpected native ABI or capabilities: $abi',
    );

    final bytes = base64Decode(
      const String.fromEnvironment('DPIP_REPORT_PICTURE_FIXTURE'),
    );
    final fixtureHash = sha256.convert(bytes);
    _check(
      fixtureHash.toString() ==
          '702a04ecdcd5fe7c81a45de86e122296cd3e30014b395a1ae52c351eb797f9f1',
      'Unexpected v2 fixture',
    );

    final first = picture.renderSharePngV2(bytes);
    final invalid = picture.renderSharePngV2(
      Uint8List.fromList(utf8.encode('{')),
    );
    final callerBuffer = Uint8List.fromList(bytes);
    final recovered = picture.renderSharePngV2(callerBuffer);
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
      await picture.renderSharePngV2(bytes),
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
    await _checkPng(png, EqTheme.light);

    final reopened = _requireValue(await ReportPicture.open());
    final Uint8List dark;
    try {
      _requireFailure(
        await reopened.renderSharePngV2(Uint8List(1024 * 1024 + 1)),
        ReportPictureFailureReason.limitExceeded,
      );
      final badVersion = utf8
          .decode(bytes)
          .replaceFirst('"schema_version": 2', '"schema_version": 3');
      _requireFailure(
        await reopened.renderSharePngV2(utf8.encode(badVersion)),
        ReportPictureFailureReason.unsupportedVersion,
        nativeStatus: -2,
      );
      dark = _requireValue(
        await reopened.renderSharePngV2(bytes, theme: EqTheme.dark),
      );
      _check(!listEquals(png, dark), 'Dark theme did not change the output');
    } finally {
      await reopened.dispose();
    }
    await _checkPng(dark, EqTheme.dark);
    final documents = await getApplicationDocumentsDirectory();
    for (final (theme, bytes) in [(EqTheme.light, png), (EqTheme.dark, dark)]) {
      final output = File('${documents.path}/report-picture-${theme.name}.png');
      await output.writeAsBytes(bytes, flush: true);
      Log.info(
        'REPORT_PICTURE_PNG theme=${theme.name} dimensions=1920x1080 '
        'bytes=${bytes.length} sha256=${sha256.convert(bytes)} file=${output.path}',
      );
    }
    return 'ABI=1.2 caps=0x11f exports=9 decoded=1920x1080 '
        'fixture_sha256=$fixtureHash themes=light,dark '
        'root-event=responsive invalid=-1 version=-2 retry=pass dispose=pass reopen=pass';
  } finally {
    await picture.dispose();
  }
}

Future<void> _checkPng(Uint8List png, EqTheme theme) async {
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
        frame.image.width == 1920 && frame.image.height == 1080,
        '${theme.name}: unexpected decoded dimensions',
      );
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

(int, int) _readAbi() {
  final library = _requireValue(NativeLibrary.open(ReportPicture.libraryName));
  for (final symbol in const [
    'eqr_renderer_new',
    'eqr_renderer_free',
    'eqr_render_png',
    'eqr_bytes_free',
    'eqr_last_error',
    'eqr_version',
    'eqr_abi_info',
    'eqr_render_share_png',
    'eqr_render_share_png_v2',
  ]) {
    _check(library.providesSymbol(symbol), 'Missing $symbol');
  }
  final info = library
      .lookupFunction<
        Uint32 Function(Pointer<Uint64>),
        int Function(Pointer<Uint64>)
      >('eqr_abi_info');
  return using((arena) {
    final capabilities = arena<Uint64>();
    final version = info(capabilities);
    return (version, capabilities.value);
  });
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
