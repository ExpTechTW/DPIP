import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/native_library.dart';
import 'package:dpip/shared/seismic/report_picture/eq_report_pic_bindings.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

export 'eq_report_pic_bindings.dart' show EqMapMode, EqTheme;

/// Renders Share Render Input v2 into a Dart-owned, 1920×1080 landscape PNG.
final class ReportPicture {
  ReportPicture._(this._render, this._release);

  @visibleForTesting
  ReportPicture.forTesting(this._render, this._release);

  static const libraryName = 'eq_report_pic';
  static const _maxInputBytes = 1024 * 1024;
  static const _fontAssets = [
    'assets/fonts/report/mplus-2p-bold.ttf',
    'assets/fonts/report/GenShinGothic-Bold.ttf',
    'assets/fonts/report/NotoSansTC-Black.ttf',
  ];

  final Future<Uint8List> Function(Uint8List, EqMapMode, EqTheme) _render;
  final void Function() _release;
  Future<void> _pending = Future.value();
  Future<void>? _disposal;

  /// Checks native support before loading fonts and creating the renderer.
  static Future<Result<ReportPicture>> open() async {
    final probe = _openBindings();
    final bindings = probe.valueOrNull;
    if (bindings == null) return Err(probe.failureOrNull!);

    try {
      final fonts = <Uint8List>[];
      for (final asset in _fontAssets) {
        final data = await rootBundle.load(asset);
        fonts.add(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
      final address = await _createRenderer(fonts);
      return Ok(
        ReportPicture._(
          (input, mode, theme) => _renderInIsolate(address, input, mode, theme),
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

  /// Renders the original UTF-8 bytes. Native validation sees the original
  /// keys and number spellings, including inputs that JSON decoding would
  /// normalize. The caller may reuse or change its buffer after this call.
  ///
  /// Requests are queued on this renderer to bound the number of live PNG
  /// canvases. A failed request leaves the renderer ready for the next one.
  Future<Result<Uint8List>> renderSharePngV2(
    Uint8List json, {
    EqMapMode mode = EqMapMode.cluster,
    EqTheme theme = EqTheme.light,
  }) {
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
        const Err(
          ReportPictureFailure(
            ReportPictureFailureReason.limitExceeded,
            'Share Render Input v2 exceeds 1 MiB',
          ),
        ),
      );
    }

    final input = Uint8List.fromList(json);
    final render = _pending.then(
      (_) => _renderRequest(() => _render(input, mode, theme)),
    );
    _pending = render.then((_) {});
    return render;
  }

  /// Stops accepting work and frees the handle once scheduled calls finish.
  /// Dropping a render Future does not cancel its synchronous FFI call.
  Future<void> dispose() => _disposal ??= _pending.then((_) => _release());
}

Result<EqReportPicBindings> _openBindings() => probeReportPictureBindings(
  NativeLibrary.open(ReportPicture.libraryName),
  fromProcess: Platform.isIOS,
);

@visibleForTesting
Result<EqReportPicBindings> probeReportPictureBindings(
  Result<DynamicLibrary> probe, {
  required bool fromProcess,
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
    final unavailable = bindings.sharePngV2Unavailable;
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

EqReportPicBindings _workerBindings() {
  final probe = _openBindings();
  final bindings = probe.valueOrNull;
  if (bindings != null) return bindings;
  throw probe.failureOrNull!;
}

// Top-level isolate entry points capture only sendable inputs. The handle
// stays process-local. Only ReportPicture.dispose frees it.
Future<int> _createRenderer(List<Uint8List> fonts) => Isolate.run(
  () => EqReportPic.create(_workerBindings(), fonts).address,
  debugName: 'report-picture-create',
);

Future<Uint8List> _renderInIsolate(
  int address,
  Uint8List input,
  EqMapMode mode,
  EqTheme theme,
) => Isolate.run(
  () => EqReportPic.fromAddress(
    _workerBindings(),
    address,
  ).renderSharePngV2(input, mode: mode, theme: theme),
  debugName: 'report-picture-render',
);

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
