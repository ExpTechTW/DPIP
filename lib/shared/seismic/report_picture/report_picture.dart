import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/native_library.dart';
import 'package:dpip/shared/seismic/report_picture/eq_report_pic_bindings.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

export 'eq_report_pic_bindings.dart'
    show EqMapMode, EqShareFormat, EqTheme, reportPictureStoryQa;

enum _ShareSchema { v2, v3 }

/// Renders Share Render Input into a Dart-owned PNG at a native share format.
final class ReportPicture {
  ReportPicture._(this._render, this._release);

  @visibleForTesting
  ReportPicture.forTesting(
    Future<Uint8List> Function(Uint8List, EqMapMode, EqTheme, EqShareFormat)
    render,
    this._release,
  ) : _render = ((_, input, mode, theme, format) =>
          render(input, mode, theme, format));

  static const libraryName = reportPictureStoryQa
      ? 'eq_report_pic_story_qa'
      : 'eq_report_pic';

  /// The verified manifest fingerprints the bundled fonts and embedded assets.
  static const cacheIdentity = (
    revision: String.fromEnvironment('DPIP_EQR_REVISION'),
    assets: String.fromEnvironment('DPIP_EQR_MANIFEST_SHA256'),
    profile: libraryName,
  );

  static const _maxInputBytes = 1024 * 1024;
  static const _fontAssets = [
    (
      'mplus-2p-bold.ttf',
      '6f1d3d4e52a27922f613861ce7013570a0d3e7ced2a63133656764bbad8bb377',
    ),
    (
      'GenShinGothic-Bold.ttf',
      '5d2e4192894bf9c41c8fee25ff1c5a1af983e2d489f66f3d6f98f1ac6a6211dd',
    ),
    (
      'NotoSansTC-Black.ttf',
      '4dd7294060de686017dfa58c999f02ccbb2658a8519f897fa3681e33a66d6aaa',
    ),
  ];

  final Future<Uint8List> Function(
    _ShareSchema,
    Uint8List,
    EqMapMode,
    EqTheme,
    EqShareFormat,
  )
  _render;
  final void Function() _release;
  Future<void> _pending = Future.value();
  Future<void>? _disposal;

  /// Checks native support before loading fonts and creating the renderer.
  static Future<Result<ReportPicture>> open() => _open(_ShareSchema.v3);

  /// Opens an explicitly legacy renderer for v2 compatibility tooling.
  static Future<Result<ReportPicture>> openLegacyV2() => _open(_ShareSchema.v2);

  static Future<Result<ReportPicture>> _open(_ShareSchema schema) async {
    final probe = _openBindings(schema);
    final bindings = probe.valueOrNull;
    if (bindings == null) return Err(probe.failureOrNull!);

    try {
      final fonts = <Uint8List>[];
      for (final (name, hash) in _fontAssets) {
        final data = await rootBundle.load('assets/fonts/report/$name');
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        if (sha256.convert(bytes).toString() != hash) {
          throw StateError('Unexpected report font bytes: $name');
        }
        fonts.add(bytes);
      }
      final address = await _createRenderer(fonts, schema);
      return Ok(
        ReportPicture._(
          (schema, input, mode, theme, format) =>
              _renderInIsolate(address, schema, input, mode, theme, format),
          () => bindings.freeRenderer(address),
        ),
      );
    } catch (error) {
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unavailable,
          'The native report renderer could not start: $error',
        ),
      );
    }
  }

  /// Renders schema 3 in the background, without falling back to schema 2.
  Future<Result<Uint8List>> renderSharePngV3(
    Uint8List json, {
    EqMapMode mode = EqMapMode.cluster,
    EqTheme theme = EqTheme.light,
    EqShareFormat format = EqShareFormat.landscape16By9,
  }) => _enqueue(_ShareSchema.v3, json, mode, theme, format);

  /// Explicit compatibility entry for original UTF-8 schema 2 bytes.
  Future<Result<Uint8List>> renderSharePngV2(
    Uint8List json, {
    EqMapMode mode = EqMapMode.cluster,
    EqTheme theme = EqTheme.light,
    EqShareFormat format = EqShareFormat.landscape16By9,
  }) => _enqueue(_ShareSchema.v2, json, mode, theme, format);

  // Bound the live PNG canvases and copy the caller's bytes before yielding.
  // A failed request leaves the renderer ready for the next one.
  Future<Result<Uint8List>> _enqueue(
    _ShareSchema schema,
    Uint8List json,
    EqMapMode mode,
    EqTheme theme,
    EqShareFormat format,
  ) {
    if (_disposal != null) {
      return Future.value(
        const Err(
          ReportPictureFailure(
            ReportPictureFailureReason.disposed,
            'The report picture renderer has been disposed',
          ),
        ),
      );
    }
    if (json.length > _maxInputBytes) {
      return Future.value(
        Err(
          ReportPictureFailure(
            ReportPictureFailureReason.limitExceeded,
            'Share Render Input ${schema.name} exceeds 1 MiB',
          ),
        ),
      );
    }

    final input = Uint8List.fromList(json);
    final render = _pending.then(
      (_) => _renderRequest(() => _render(schema, input, mode, theme, format)),
    );
    _pending = render.then((_) {});
    return render;
  }

  /// Stops accepting work and frees the handle once scheduled calls finish.
  /// Dropping a render Future does not cancel its synchronous FFI call.
  Future<void> dispose() => _disposal ??= _pending.then((_) => _release());
}

Result<EqReportPicBindings> _openBindings(_ShareSchema schema) =>
    probeReportPictureBindings(
      NativeLibrary.open(ReportPicture.libraryName),
      fromProcess: Platform.isIOS,
      legacyV2: schema == _ShareSchema.v2,
    );

@visibleForTesting
Result<EqReportPicBindings> probeReportPictureBindings(
  Result<DynamicLibrary> probe, {
  required bool fromProcess,
  bool legacyV2 = false,
}) {
  final library = probe.valueOrNull;
  if (library == null) {
    return Err(
      ReportPictureFailure(
        ReportPictureFailureReason.unavailable,
        probe.failureOrNull!.message,
      ),
    );
  }
  try {
    // iOS opens the process even when the optional static library is absent.
    if (fromProcess &&
        !library.providesSymbol('eqr_renderer_new') &&
        !library.providesSymbol('eqr_abi_info')) {
      return const Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unavailable,
          'The native report library is not linked into this build',
        ),
      );
    }
    final bindings = EqReportPicBindings(library);
    final unavailable = legacyV2
        ? bindings.sharePngV2Unavailable
        : bindings.sharePngV3Unavailable();
    if (unavailable != null) {
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unsupportedAbi,
          unavailable,
        ),
      );
    }
    return Ok(bindings);
  } on ArgumentError catch (error) {
    return Err(
      ReportPictureFailure(
        ReportPictureFailureReason.unsupportedAbi,
        'The native report library does not export the expected symbols: $error',
      ),
    );
  }
}

EqReportPicBindings _workerBindings(_ShareSchema schema) {
  final probe = _openBindings(schema);
  final bindings = probe.valueOrNull;
  if (bindings != null) return bindings;
  throw probe.failureOrNull!;
}

// Top-level isolate entry points capture only sendable inputs. The handle
// stays process-local. Only ReportPicture.dispose frees it.
Future<int> _createRenderer(List<Uint8List> fonts, _ShareSchema schema) =>
    Isolate.run(
      () => EqReportPic.create(_workerBindings(schema), fonts).address,
      debugName: 'report-picture-create',
    );

Future<Uint8List> _renderInIsolate(
  int address,
  _ShareSchema schema,
  Uint8List input,
  EqMapMode mode,
  EqTheme theme,
  EqShareFormat format,
) => Isolate.run(() {
  final renderer = EqReportPic.fromAddress(_workerBindings(schema), address);
  return switch (schema) {
    _ShareSchema.v2 => renderer.renderSharePngV2(
      input,
      mode: mode,
      theme: theme,
      format: format,
    ),
    _ShareSchema.v3 => renderer.renderSharePngV3(
      input,
      mode: mode,
      theme: theme,
      format: format,
    ),
  };
}, debugName: 'report-picture-render');

Future<Result<Uint8List>> _renderRequest(
  Future<Uint8List> Function() render,
) async {
  try {
    return Ok(await render());
  } on ReportPictureFailure catch (failure) {
    return Err(failure);
  } on EqShareRenderException catch (error) {
    Log.warning(
      'report picture: ${error.message} (native status ${error.nativeStatus})',
    );
    final reason = switch (error.reason) {
      EqShareRenderError.invalidArgument =>
        ReportPictureFailureReason.invalidInput,
      EqShareRenderError.unsupportedVersion =>
        ReportPictureFailureReason.unsupportedVersion,
      EqShareRenderError.unsupportedFeature =>
        ReportPictureFailureReason.unsupportedFeature,
      EqShareRenderError.limitExceeded =>
        ReportPictureFailureReason.limitExceeded,
      EqShareRenderError.internal ||
      EqShareRenderError.unknown => ReportPictureFailureReason.renderFailed,
    };
    return Err(
      ReportPictureFailure(
        reason,
        error.message,
        nativeStatus: error.nativeStatus,
      ),
    );
  } catch (error) {
    Log.warning('report picture: $error');
    return Err(
      ReportPictureFailure(
        ReportPictureFailureReason.renderFailed,
        'The native report renderer failed: $error',
      ),
    );
  }
}
