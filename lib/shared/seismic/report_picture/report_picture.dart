import 'dart:ffi';
import 'dart:isolate';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/native_library.dart';
import 'package:dpip/shared/seismic/report_picture/eq_report_pic_bindings.dart';
import 'package:flutter/services.dart';

/// How stations are drawn on the report image's map.
enum ReportPictureMode { cluster, stations, towns }

/// The report image's colour theme.
enum ReportPictureTheme { light, dark }

/// A landscape 1920×1080 PNG of one CWA earthquake report.
///
/// The image is drawn by `ExpTechTW/eq-report-pic`, a pure-Rust library called
/// over `dart:ffi`; it is the same drawing cwa-eq-map's share images use, and
/// one render takes about 60 ms. Keeping it out of Flutter is the point: the
/// map, the clustering and the font layout are the renderer's job, and the UI
/// isolate only receives bytes.
abstract interface class ReportPictureRenderer {
  /// Renders [reportJson] — the body of `/api/v2/eq/report/{id}` — to a PNG.
  ///
  /// [scale] multiplies the 1920×1080 layout, up to 4×. The work happens on a
  /// fresh isolate, so this is safe to call from a frame callback and the
  /// result can be written straight to the share sheet or the photo library.
  Future<Result<Uint8List>> render(
    Uint8List reportJson, {
    double scale = 1.0,
    ReportPictureMode mode = ReportPictureMode.cluster,
    ReportPictureTheme theme = ReportPictureTheme.light,
  });

  /// Releases the native renderer. Safe to call more than once.
  ///
  /// Render in flight at the same time must have completed first: the handle
  /// is what they are drawing into.
  void dispose();
}

/// A test seam: production opens the packaged library, tests supply their own
/// answer because the host they run on has no native artifact.
typedef NativeLibraryOpener = Result<DynamicLibrary> Function(String name);

/// Opens the native report-image renderer.
///
/// This is readiness plumbing, not a feature yet: no screen calls it, and the
/// app ships without the native binary, so [open] answers
/// [ReportPictureFailureReason.unavailable] until a build adds one. See
/// ARCHITECTURE.md → Native libraries.
abstract final class ReportPicture {
  /// The native library's base name; [NativeLibrary] adds the platform's file
  /// name and extension.
  static const String libraryName = 'eq_report_pic';

  /// TTF bytes in the renderer's fallback order. They are assets of the app,
  /// not of the library: embedding them in a `cdylib` would put a 13.8 MB copy
  /// in every Android ABI, and the caller must pass them once at creation.
  static const List<String> fontAssets = [
    'assets/fonts/report/mplus-2p-bold.ttf',
    'assets/fonts/report/GenShinGothic-Bold.ttf',
    'assets/fonts/report/NotoSansTC-Black.ttf',
  ];

  /// Creates a renderer, or explains why this build cannot.
  ///
  /// Parsing the fonts and decoding the embedded basemap happen once and are
  /// what makes creation slow (~170 ms); they run on a throwaway isolate so
  /// opening the share sheet does not drop frames.
  static Future<Result<ReportPictureRenderer>> open({
    NativeLibraryOpener? openLibrary,
  }) async {
    final probe = (openLibrary ?? NativeLibrary.open)(libraryName);
    final library = probe.valueOrNull;
    if (library == null) {
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unavailable,
          probe.failureOrNull?.message ??
              'Native library "$libraryName" is not available',
        ),
      );
    }

    final EqReportPicBindings bindings;
    try {
      // Looking the symbols up here, not on first render, is deliberate: a
      // library built from an older ABI fails at open, where the caller can
      // fall back to the Flutter-drawn card, rather than mid-render.
      bindings = EqReportPicBindings(library);
    } catch (error) {
      Log.warning(
        'report picture: $libraryName does not export the ABI: $error',
      );
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unavailable,
          'Native library "$libraryName" does not export the expected symbols: $error',
        ),
      );
    }

    final List<Uint8List> fonts;
    try {
      fonts = await _loadFonts();
    } catch (error) {
      Log.warning('report picture: fonts unavailable: $error');
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unavailable,
          'Bundled report fonts are missing: $error',
        ),
      );
    }

    try {
      final address = await Isolate.run(() => _createRenderer(fonts));
      return Ok(_NativeReportPictureRenderer(bindings, address));
    } catch (error) {
      Log.warning('report picture: renderer creation failed: $error');
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.unavailable,
          'The native report renderer could not start: $error',
        ),
      );
    }
  }

  static Future<List<Uint8List>> _loadFonts() async {
    final fonts = <Uint8List>[];
    for (final asset in fontAssets) {
      final data = await rootBundle.load(asset);
      fonts.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    }
    return fonts;
  }
}

/// Runs on the render isolate: `DynamicLibrary` cannot cross an isolate
/// boundary, so each one opens the library itself, then adopts the handle the
/// main isolate owns by address.
int _createRenderer(List<Uint8List> fonts) {
  final result = NativeLibrary.open(ReportPicture.libraryName);
  final library = result.valueOrNull;
  if (library == null) throw StateError(result.failureOrNull!.message);
  return EqReportPic.create(EqReportPicBindings(library), fonts).address;
}

/// The render itself, on its own isolate. The native renderer is thread-safe
/// and may be used by several isolates at once; only the owner frees it.
Uint8List _renderInIsolate(
  int address,
  Uint8List reportJson,
  double scale,
  int mode,
  int theme,
) {
  final result = NativeLibrary.open(ReportPicture.libraryName);
  final library = result.valueOrNull;
  if (library == null) throw StateError(result.failureOrNull!.message);
  return EqReportPic.fromAddress(
    EqReportPicBindings(library),
    address,
  ).renderPng(
    reportJson,
    scale: scale,
    mode: EqMapMode.values[mode],
    theme: EqTheme.values[theme],
  );
}

final class _NativeReportPictureRenderer implements ReportPictureRenderer {
  _NativeReportPictureRenderer(this._bindings, this._address);

  final EqReportPicBindings _bindings;
  int? _address;

  @override
  Future<Result<Uint8List>> render(
    Uint8List reportJson, {
    double scale = 1.0,
    ReportPictureMode mode = ReportPictureMode.cluster,
    ReportPictureTheme theme = ReportPictureTheme.light,
  }) async {
    final address = _address;
    if (address == null) {
      return const Err(
        ReportPictureFailure(
          ReportPictureFailureReason.renderFailed,
          'The report picture renderer has been disposed',
        ),
      );
    }

    try {
      final png = await Isolate.run(
        () => _renderInIsolate(
          address,
          reportJson,
          scale.clamp(1.0, 4.0).toDouble(),
          mode.index,
          theme.index,
        ),
      );
      return Ok(png);
    } catch (error) {
      // The ABI turns a panic into an error code and an `eqr_last_error` on
      // the isolate that hit it, so the message arrives here as the exception
      // text. Keep it: "invalid report" and "renderer bug" look identical
      // otherwise.
      Log.warning('report picture: render failed: $error');
      return Err(
        ReportPictureFailure(
          ReportPictureFailureReason.renderFailed,
          'The report picture could not be rendered: $error',
        ),
      );
    }
  }

  @override
  void dispose() {
    final address = _address;
    if (address == null) return;
    _address = null;
    try {
      _bindings.freeRenderer(address);
    } catch (error) {
      // Losing the free leaks one renderer, which the process gets back on
      // exit; throwing here would take down the caller for a bookkeeping slip.
      Log.warning('report picture: freeing the renderer failed: $error');
    }
  }
}
