import 'dart:ffi';

import 'package:ffi/ffi.dart';

const reportPictureAbiSymbols = [
  'eqr_renderer_new',
  'eqr_renderer_free',
  'eqr_render_png',
  'eqr_bytes_free',
  'eqr_last_error',
  'eqr_version',
  'eqr_abi_info',
  'eqr_render_share_png',
  'eqr_render_share_png_v2',
];

const reportPictureOptionsSymbol = 'eqr_render_share_png_with_options';

(int, int) readReportPictureAbi(DynamicLibrary library) {
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
