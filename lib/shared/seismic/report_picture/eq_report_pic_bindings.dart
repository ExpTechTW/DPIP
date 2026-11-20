/// Dart binding for the eq_report_pic C ABI (`include/eq_report_pic.h`).
///
/// Copied from ExpTechTW/eq-report-pic `dart/lib/eq_report_pic.dart` at
/// c6d3420, so the app and the library's own CLI read the ABI the same way.
/// Keep it in step with that file; the two local changes are both marked
/// "DPIP:" below.
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

final class _EqrRenderer extends Opaque {}

typedef _NewC = Pointer<_EqrRenderer> Function(
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
  Size,
);
typedef _NewDart = Pointer<_EqrRenderer> Function(
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
  int,
);
typedef _FreeC = Void Function(Pointer<_EqrRenderer>);
typedef _FreeDart = void Function(Pointer<_EqrRenderer>);
typedef _RenderC = Int32 Function(
  Pointer<_EqrRenderer>,
  Pointer<Uint8>,
  Size,
  Float,
  Uint32,
  Uint32,
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
);
typedef _RenderDart = int Function(
  Pointer<_EqrRenderer>,
  Pointer<Uint8>,
  int,
  double,
  int,
  int,
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
);
typedef _BytesFreeC = Void Function(Pointer<Uint8>, Size);
typedef _BytesFreeDart = void Function(Pointer<Uint8>, int);
typedef _StrC = Pointer<Utf8> Function();

/// How stations are drawn on the map. The index is the C ABI value.
enum EqMapMode {
  /// Squares: the strongest station of each group plus the group's size.
  cluster,

  /// Every station as a circle, strongest on top.
  stations,

  /// Townships coloured by their strongest station.
  towns,
}

/// Colour theme. The index is the C ABI value.
enum EqTheme { light, dark }

/// Thrown when the native library reports a failure.
class EqReportPicException implements Exception {
  EqReportPicException(this.message);
  final String message;
  @override
  String toString() => 'EqReportPicException: $message';
}

/// The library's functions. Opening is cheap; a [DynamicLibrary] cannot be
/// sent to another isolate, so open it again inside each isolate.
class EqReportPicBindings {
  EqReportPicBindings(DynamicLibrary lib)
    : _new = lib.lookupFunction<_NewC, _NewDart>('eqr_renderer_new'),
      _free = lib.lookupFunction<_FreeC, _FreeDart>('eqr_renderer_free'),
      _render = lib.lookupFunction<_RenderC, _RenderDart>('eqr_render_png'),
      _bytesFree = lib.lookupFunction<_BytesFreeC, _BytesFreeDart>(
        'eqr_bytes_free',
      ),
      _lastError = lib.lookupFunction<_StrC, _StrC>('eqr_last_error'),
      _version = lib.lookupFunction<_StrC, _StrC>('eqr_version');

  // DPIP: the upstream `open()` factory is gone. `NativeLibrary` in
  // `core/platform/native_library.dart` owns the platform-to-file mapping and
  // reports a missing library as a `Result` instead of throwing here.

  final _NewDart _new;
  final _FreeDart _free;
  final _RenderDart _render;
  final _BytesFreeDart _bytesFree;
  final Pointer<Utf8> Function() _lastError;
  final Pointer<Utf8> Function() _version;

  // DPIP: a renderer is created inside the render isolate, but the handle is
  // owned by the caller's isolate. This frees it from there; the ABI has no
  // isolate affinity, only the `DynamicLibrary` does.
  void freeRenderer(int address) =>
      _free(Pointer<_EqrRenderer>.fromAddress(address));

  String get version => _version().toDartString();

  String _error(String fallback) {
    final p = _lastError();
    return p == nullptr ? fallback : p.toDartString();
  }
}

/// A native renderer. Create it once (fonts are parsed and the basemap is
/// decoded here), render many times, [dispose] when done.
///
/// The native renderer is thread-safe: pass [address] to another isolate and
/// rebuild it there with [EqReportPic.fromAddress]. Only the owner may
/// [dispose], and only after every isolate is done with it.
class EqReportPic {
  EqReportPic._(this._b, this._handle, this._owner);

  /// [fonts]: TTF bytes in fallback order —
  /// mplus-2p-bold, GenShinGothic-Bold, NotoSansTC-Black. The bytes are copied.
  factory EqReportPic.create(EqReportPicBindings b, List<Uint8List> fonts) {
    final ptrs = malloc<Pointer<Uint8>>(fonts.length);
    final lens = malloc<Size>(fonts.length);
    final buffers = <Pointer<Uint8>>[];
    try {
      for (var i = 0; i < fonts.length; i++) {
        final buf = malloc<Uint8>(fonts[i].length);
        buffers.add(buf);
        buf.asTypedList(fonts[i].length).setAll(0, fonts[i]);
        ptrs[i] = buf;
        lens[i] = fonts[i].length;
      }
      final handle = b._new(ptrs, lens, fonts.length);
      if (handle == nullptr) {
        throw EqReportPicException(b._error('eqr_renderer_new failed'));
      }
      return EqReportPic._(b, handle, true);
    } finally {
      for (final buf in buffers) {
        malloc.free(buf);
      }
      malloc.free(ptrs);
      malloc.free(lens);
    }
  }

  /// A non-owning view of a renderer created elsewhere (e.g. in the main
  /// isolate); [dispose] on it does nothing.
  factory EqReportPic.fromAddress(EqReportPicBindings b, int address) =>
      EqReportPic._(b, Pointer<_EqrRenderer>.fromAddress(address), false);

  final EqReportPicBindings _b;
  Pointer<_EqrRenderer> _handle;
  final bool _owner;

  int get address => _handle.address;

  /// [json]: the body of `/api/v2/eq/report/{id}`. [scale] 1.0 = 1920x1080.
  Uint8List renderPng(
    Uint8List json, {
    double scale = 1.0,
    EqMapMode mode = EqMapMode.cluster,
    EqTheme theme = EqTheme.light,
  }) {
    if (_handle == nullptr) throw EqReportPicException('renderer disposed');
    final input = malloc<Uint8>(json.isEmpty ? 1 : json.length);
    final outPtr = malloc<Pointer<Uint8>>();
    final outLen = malloc<Size>();
    try {
      input.asTypedList(json.length).setAll(0, json);
      final rc = _b._render(
        _handle,
        input,
        json.length,
        scale,
        mode.index,
        theme.index,
        outPtr,
        outLen,
      );
      if (rc != 0) {
        throw EqReportPicException(_b._error('eqr_render_png failed'));
      }
      final png = Uint8List.fromList(outPtr.value.asTypedList(outLen.value));
      _b._bytesFree(outPtr.value, outLen.value);
      return png;
    } finally {
      malloc.free(input);
      malloc.free(outPtr);
      malloc.free(outLen);
    }
  }

  void dispose() {
    if (_owner && _handle != nullptr) _b._free(_handle);
    _handle = nullptr;
  }
}
