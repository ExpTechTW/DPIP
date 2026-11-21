/// Dart binding for the eq_report_pic C ABI (`include/eq_report_pic.h`).
///
/// Vendored from eq-report-pic b135d02bd1ba5103cd3d116a951b1b63a710a312.
/// DPIP uses NativeLibrary to load it and owns renderer handles in ReportPicture.
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
typedef _AbiInfoC = Uint32 Function(Pointer<Uint64>);
typedef _AbiInfoDart = int Function(Pointer<Uint64>);
typedef _RenderV2C = Int32 Function(
  Pointer<_EqrRenderer>,
  Pointer<Uint8>,
  Size,
  Uint32,
  Uint32,
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
);
typedef _RenderV2Dart = int Function(
  Pointer<_EqrRenderer>,
  Pointer<Uint8>,
  int,
  int,
  int,
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
);
typedef _RenderCall = int Function(
  Pointer<Uint8>,
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

/// A machine-readable reason for a v2 share rendering failure.
enum EqShareRenderError {
  invalidArgument,
  unsupportedVersion,
  unsupportedFeature,
  limitExceeded,
  internal,
  unknown,
}

/// A v2 rendering failure. Also catchable as [EqReportPicException].
class EqShareRenderException extends EqReportPicException {
  EqShareRenderException(super.message, this.reason, {this.nativeStatus});

  final EqShareRenderError reason;

  /// The exact status from the native render call, if one was made.
  ///
  /// A missing capability or symbol reports [EqShareRenderError.unsupportedFeature]
  /// with a null status; an unsupported input locale reports native status -3.
  final int? nativeStatus;
}

/// The library's functions. Opening is cheap; a [DynamicLibrary] cannot be
/// sent to another isolate, so open it again inside each isolate.
class EqReportPicBindings {
  EqReportPicBindings(DynamicLibrary lib)
    : _lib = lib,
      _new = lib.lookupFunction<_NewC, _NewDart>('eqr_renderer_new'),
      _free = lib.lookupFunction<_FreeC, _FreeDart>('eqr_renderer_free'),
      _render = lib.lookupFunction<_RenderC, _RenderDart>('eqr_render_png'),
      _bytesFree = lib.lookupFunction<_BytesFreeC, _BytesFreeDart>(
        'eqr_bytes_free',
      ),
      _lastError = lib.lookupFunction<_StrC, _StrC>('eqr_last_error'),
      _version = lib.lookupFunction<_StrC, _StrC>('eqr_version');

  final DynamicLibrary _lib;
  final _NewDart _new;
  final _FreeDart _free;
  final _RenderDart _render;
  final _BytesFreeDart _bytesFree;
  final Pointer<Utf8> Function() _lastError;
  final Pointer<Utf8> Function() _version;

  late final _shareV2 = _discoverShareV2();

  /// An unavailable v2 renderer has a diagnostic and a null function.
  String? get sharePngV2Unavailable => _shareV2.unavailable;

  /// Releases an owned handle after all background calls have returned.
  void freeRenderer(int address) =>
      _free(Pointer<_EqrRenderer>.fromAddress(address));

  ({_RenderV2Dart? render, String? unavailable}) _discoverShareV2() {
    const abiSymbol = 'eqr_abi_info';
    const renderSymbol = 'eqr_render_share_png_v2';
    const shareInputV2 = 1 << 4;
    const production16By9 = 1 << 8;
    const requiredCapabilities = shareInputV2 | production16By9;

    if (!_lib.providesSymbol(abiSymbol)) {
      return (render: null, unavailable: 'Missing $abiSymbol');
    }
    final abiInfo = _lib.lookupFunction<_AbiInfoC, _AbiInfoDart>(abiSymbol);
    final (abi, capabilities) = using((arena) {
      final bits = arena<Uint64>();
      final abi = abiInfo(bits);
      return (abi, bits.value);
    });
    final major = abi >> 16;
    final minor = abi & 0xffff;
    if (major != 1 || minor < 2) {
      return (
        render: null,
        unavailable: 'Unsupported native ABI $major.$minor',
      );
    }
    if ((capabilities & requiredCapabilities) != requiredCapabilities) {
      return (
        render: null,
        unavailable:
            'Native ABI needs EQR_CAP_SHARE_INPUT_V2 and '
            'EQR_CAP_PRODUCTION_16_9',
      );
    }
    if (!_lib.providesSymbol(renderSymbol)) {
      return (render: null, unavailable: 'Missing $renderSymbol');
    }
    return (
      render: _lib.lookupFunction<_RenderV2C, _RenderV2Dart>(renderSymbol),
      unavailable: null,
    );
  }

  EqShareRenderException _shareV2Error(int status) {
    // Copy the thread-local diagnostic before making another eqr_* call.
    final message = _error('eqr_render_share_png_v2 failed ($status)');
    final reason = switch (status) {
      -1 => EqShareRenderError.invalidArgument,
      -2 => EqShareRenderError.unsupportedVersion,
      -3 => EqShareRenderError.unsupportedFeature,
      -4 => EqShareRenderError.limitExceeded,
      -5 => EqShareRenderError.internal,
      _ => EqShareRenderError.unknown,
    };
    return EqShareRenderException(message, reason, nativeStatus: status);
  }

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
    return _renderAndCopy(
      json,
      (input, length, outPtr, outLen) => _b._render(
        _handle,
        input,
        length,
        scale,
        mode.index,
        theme.index,
        outPtr,
        outLen,
      ),
      (_) => EqReportPicException(_b._error('eqr_render_png failed')),
    );
  }

  /// Renders original UTF-8 Share Render Input v2 [jsonBytes] to a
  /// Dart-owned 1920×1080 PNG. The native library validates the input.
  ///
  /// Throws [EqShareRenderException] for unsupported native libraries and
  /// native rendering failures. There is no synthetic or legacy fallback.
  Uint8List renderSharePngV2(
    Uint8List jsonBytes, {
    required EqMapMode mode,
    required EqTheme theme,
  }) {
    if (_handle == nullptr) {
      throw EqShareRenderException(
        'renderer disposed',
        EqShareRenderError.invalidArgument,
      );
    }
    final (:render, :unavailable) = _b._shareV2;
    if (render == null) {
      throw EqShareRenderException(
        unavailable!,
        EqShareRenderError.unsupportedFeature,
      );
    }
    return _renderAndCopy(
      jsonBytes,
      (input, length, outPtr, outLen) => render(
        _handle,
        input,
        length,
        mode.index,
        theme.index,
        outPtr,
        outLen,
      ),
      _b._shareV2Error,
    );
  }

  Uint8List _renderAndCopy(
    Uint8List json,
    _RenderCall render,
    EqReportPicException Function(int) error,
  ) => using((arena) {
    final input = arena<Uint8>(json.isEmpty ? 1 : json.length);
    final outPtr = arena<Pointer<Uint8>>();
    final outLen = arena<Size>();
    input.asTypedList(json.length).setAll(0, json);
    final status = render(input, json.length, outPtr, outLen);
    if (status != 0) throw error(status);

    final png = outPtr.value;
    final pngLength = outLen.value;
    try {
      return Uint8List.fromList(png.asTypedList(pngLength));
    } finally {
      _b._bytesFree(png, pngLength);
    }
  });

  void dispose() {
    if (_owner && _handle != nullptr) _b._free(_handle);
    _handle = nullptr;
  }
}
