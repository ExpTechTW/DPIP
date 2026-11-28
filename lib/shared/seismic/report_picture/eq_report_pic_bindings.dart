/// Dart binding for the eq_report_pic C ABI (`include/eq_report_pic.h`).
///
/// Based on the C headers at the eq-report-pic revision pinned by DPIP.
/// DPIP uses NativeLibrary to load it and owns renderer handles in ReportPicture.
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Story's separate ABI is reachable only in the development flavor.
const reportPictureStoryQa =
    kDebugMode &&
    String.fromEnvironment('FLUTTER_APP_FLAVOR') == 'storyqa' &&
    bool.fromEnvironment('DPIP_EQR_STORY_QA');

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

final class _EqrShareRenderOptions extends Struct {
  @Uint32()
  external int size;

  @Uint32()
  external int format;

  @Uint32()
  external int theme;

  @Uint32()
  external int mode;
}

typedef _RenderWithOptionsC = Int32 Function(
  Pointer<_EqrRenderer>,
  Pointer<Uint8>,
  Size,
  Pointer<_EqrShareRenderOptions>,
  Pointer<Pointer<Uint8>>,
  Pointer<Size>,
);
typedef _RenderWithOptionsDart = int Function(
  Pointer<_EqrRenderer>,
  Pointer<Uint8>,
  int,
  Pointer<_EqrShareRenderOptions>,
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

/// Native Share Render Input output formats.
enum EqShareFormat {
  landscape16By9(1, 1920, 1080),
  information4By5(2, 1080, 1350),
  story9By16(3, 1080, 1920);

  const EqShareFormat(this.nativeId, this.width, this.height);

  final int nativeId;
  final int width;
  final int height;
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

/// A machine-readable reason for a share rendering failure.
enum EqShareRenderError {
  invalidArgument,
  unsupportedVersion,
  unsupportedFeature,
  limitExceeded,
  internal,
  unknown,
}

/// A share rendering failure. Also catchable as [EqReportPicException].
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
  EqReportPicBindings(
    DynamicLibrary lib, {
    this._storyQa = reportPictureStoryQa,
  }) : _lib = lib,
       _new = lib.lookupFunction<_NewC, _NewDart>('eqr_renderer_new'),
       _free = lib.lookupFunction<_FreeC, _FreeDart>('eqr_renderer_free'),
       _render = lib.lookupFunction<_RenderC, _RenderDart>('eqr_render_png'),
       _bytesFree = lib.lookupFunction<_BytesFreeC, _BytesFreeDart>(
         'eqr_bytes_free',
       ),
       _lastError = lib.lookupFunction<_StrC, _StrC>('eqr_last_error'),
       _version = lib.lookupFunction<_StrC, _StrC>('eqr_version');

  final DynamicLibrary _lib;
  final bool _storyQa;
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

  /// Whether the loaded runtime exposes the ABI 1.3 information card.
  bool get supportsInformation4By5 => _shareV2.renderWithOptions != null;

  static const _legacyStorySymbol = 'eqr_qa_render_story_png_v1';
  static const _v3Symbol = 'eqr_render_share_png_v3';
  static const _v3StorySymbol = 'eqr_qa_render_story_png_v2';
  static const _abiSymbol = 'eqr_abi_info';

  late final _abi = _readAbi();
  late final _renderStoryV2 = _storyQa && supportsInformation4By5
      ? _lookupOptions(_legacyStorySymbol)
      : null;
  late final _renderV3 = _lookupOptions(_v3Symbol);
  late final _renderStoryV3 = _storyQa ? _lookupOptions(_v3StorySymbol) : null;

  bool get supportsStoryQa => _renderStoryV2 != null;

  (int, int, int)? _readAbi() {
    if (!_lib.providesSymbol(_abiSymbol)) return null;
    final abiInfo = _lib.lookupFunction<_AbiInfoC, _AbiInfoDart>(_abiSymbol);
    return using((arena) {
      final bits = arena<Uint64>()..value = 0;
      final abi = abiInfo(bits);
      return (abi >> 16, abi & 0xffff, bits.value);
    });
  }

  _RenderWithOptionsDart? _lookupOptions(String symbol) =>
      _lib.providesSymbol(symbol)
      ? _lib.lookupFunction<_RenderWithOptionsC, _RenderWithOptionsDart>(symbol)
      : null;

  /// Verifies the selected profile and, for a render, the required format bit.
  String? sharePngV3Unavailable([EqShareFormat? format]) {
    final abi = _abi;
    if (abi == null) return 'Missing $_abiSymbol';
    final (major, minor, caps) = abi;
    if (major != 1 || minor < 4) return 'Unsupported native ABI $major.$minor';
    if (caps & (1 << 10) != 0) return 'Reserved production Story bit 10 is set';
    if (caps & (1 << 11) == 0) return 'Missing EQR_CAP_SHARE_INPUT_V3';

    final hasStoryBit = caps & (1 << 12) != 0;
    if (_storyQa != hasStoryBit ||
        (!_storyQa &&
            (_lib.providesSymbol(_legacyStorySymbol) ||
                _lib.providesSymbol(_v3StorySymbol)))) {
      return 'Native renderer does not match the selected profile';
    }
    if (_renderV3 == null) return 'Missing $_v3Symbol';
    return switch (format) {
      EqShareFormat.landscape16By9 when caps & (1 << 8) == 0 =>
        'Missing EQR_CAP_PRODUCTION_16_9',
      EqShareFormat.information4By5 when caps & (1 << 9) == 0 =>
        'Missing EQR_CAP_PRODUCTION_4_5',
      EqShareFormat.story9By16 when !_storyQa =>
        'Story rendering requires the development QA renderer',
      EqShareFormat.story9By16 when _renderStoryV3 == null =>
        'Missing $_v3StorySymbol',
      _ => null,
    };
  }

  ({
    _RenderV2Dart? render,
    _RenderWithOptionsDart? renderWithOptions,
    String? unavailable,
  })
  _discoverShareV2() {
    const renderSymbol = 'eqr_render_share_png_v2';
    const shareInputV2 = 1 << 4;
    const production16By9 = 1 << 8;
    const requiredCapabilities = shareInputV2 | production16By9;

    final abi = _abi;
    if (abi == null) {
      return (
        render: null,
        renderWithOptions: null,
        unavailable: 'Missing $_abiSymbol',
      );
    }
    final (major, minor, capabilities) = abi;
    if (major != 1 || minor < 2) {
      return (
        render: null,
        renderWithOptions: null,
        unavailable: 'Unsupported native ABI $major.$minor',
      );
    }
    if ((capabilities & requiredCapabilities) != requiredCapabilities) {
      return (
        render: null,
        renderWithOptions: null,
        unavailable:
            'Native ABI needs EQR_CAP_SHARE_INPUT_V2 and '
            'EQR_CAP_PRODUCTION_16_9',
      );
    }
    if (!_lib.providesSymbol(renderSymbol)) {
      return (
        render: null,
        renderWithOptions: null,
        unavailable: 'Missing $renderSymbol',
      );
    }
    const optionsSymbol = 'eqr_render_share_png_with_options';
    final hasInformationCard =
        minor >= 3 &&
        (capabilities & (1 << 9)) != 0 &&
        _lib.providesSymbol(optionsSymbol);
    return (
      renderWithOptions: hasInformationCard
          ? _lib.lookupFunction<_RenderWithOptionsC, _RenderWithOptionsDart>(
              optionsSymbol,
            )
          : null,
      render: _lib.lookupFunction<_RenderV2C, _RenderV2Dart>(renderSymbol),
      unavailable: null,
    );
  }

  EqShareRenderException _shareError(
    int status, [
    String symbol = 'eqr_render_share_png_v2',
  ]) {
    // Copy the thread-local diagnostic before making another eqr_* call.
    final message = _error('$symbol failed ($status)');
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
  /// [fontAllocator] supplies temporary storage for those copies.
  factory EqReportPic.create(
    EqReportPicBindings b,
    List<Uint8List> fonts, {
    Allocator fontAllocator = malloc,
  }) => using((arena) {
    final ptrs = arena<Pointer<Uint8>>(fonts.length);
    final lens = arena<Size>(fonts.length);
    for (var i = 0; i < fonts.length; i++) {
      final font = fonts[i];
      final buffer = arena<Uint8>(font.length);
      buffer.asTypedList(font.length).setAll(0, font);
      ptrs[i] = buffer;
      lens[i] = font.length;
    }
    final handle = b._new(ptrs, lens, fonts.length);
    if (handle == nullptr) {
      throw EqReportPicException(b._error('eqr_renderer_new failed'));
    }
    return EqReportPic._(b, handle, true);
  }, fontAllocator);

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
  /// Dart-owned PNG. The native library validates the input.
  ///
  /// Throws [EqShareRenderException] for unsupported native libraries and
  /// native rendering failures. There is no synthetic or legacy fallback.
  Uint8List renderSharePngV2(
    Uint8List jsonBytes, {
    required EqMapMode mode,
    required EqTheme theme,
    EqShareFormat format = EqShareFormat.landscape16By9,
  }) {
    if (_handle == nullptr) {
      throw EqShareRenderException(
        'renderer disposed',
        EqShareRenderError.invalidArgument,
      );
    }
    if (format != EqShareFormat.landscape16By9) {
      final isStory = format == EqShareFormat.story9By16;
      final render = isStory
          ? _b._renderStoryV2
          : _b._shareV2.renderWithOptions;
      if (render == null) {
        throw EqShareRenderException(
          isStory
              ? 'Story rendering requires the development QA renderer'
              : 'Native 4:5 rendering requires ABI 1.3, EQR_CAP_PRODUCTION_4_5, '
                    'and eqr_render_share_png_with_options',
          EqShareRenderError.unsupportedFeature,
        );
      }
      return _renderWithOptions(
        jsonBytes,
        mode,
        theme,
        format,
        render,
        isStory
            ? EqReportPicBindings._legacyStorySymbol
            : 'eqr_render_share_png_with_options',
      );
    }
    final (:render, :unavailable, renderWithOptions: _) = _b._shareV2;
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
      _b._shareError,
    );
  }

  /// Renders schema 3 with ABI 1.4 and the selected profile's format capability.
  Uint8List renderSharePngV3(
    Uint8List jsonBytes, {
    required EqMapMode mode,
    required EqTheme theme,
    EqShareFormat format = EqShareFormat.landscape16By9,
  }) {
    if (_handle == nullptr) {
      throw EqShareRenderException(
        'renderer disposed',
        EqShareRenderError.invalidArgument,
      );
    }
    if (jsonBytes.lengthInBytes > 1024 * 1024) {
      throw EqShareRenderException(
        'Share Render Input v3 exceeds 1 MiB',
        EqShareRenderError.limitExceeded,
      );
    }
    if (_b.sharePngV3Unavailable(format) case final diagnostic?) {
      throw EqShareRenderException(
        diagnostic,
        EqShareRenderError.unsupportedFeature,
      );
    }
    final story = format == EqShareFormat.story9By16;
    return _renderWithOptions(
      jsonBytes,
      mode,
      theme,
      format,
      (story ? _b._renderStoryV3 : _b._renderV3)!,
      story
          ? EqReportPicBindings._v3StorySymbol
          : EqReportPicBindings._v3Symbol,
    );
  }

  Uint8List _renderWithOptions(
    Uint8List json,
    EqMapMode mode,
    EqTheme theme,
    EqShareFormat format,
    _RenderWithOptionsDart render,
    String symbol,
  ) => using((arena) {
    final options = arena<_EqrShareRenderOptions>()
      ..ref.size = sizeOf<_EqrShareRenderOptions>()
      ..ref.format = format.nativeId
      ..ref.theme = theme.index
      ..ref.mode = mode.index;
    return _renderAndCopy(
      json,
      (input, length, outPtr, outLen) =>
          render(_handle, input, length, options, outPtr, outLen),
      (status) => _b._shareError(status, symbol),
    );
  });

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
    if (png == nullptr) {
      throw EqReportPicException(
        'Native render succeeded without a PNG buffer',
      );
    }
    try {
      if (pngLength == 0) {
        throw EqReportPicException(
          'Native render returned an empty PNG buffer',
        );
      }
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
