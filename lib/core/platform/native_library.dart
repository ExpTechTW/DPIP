import 'dart:ffi';
import 'dart:io';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';

/// A platform whose packaging rules decide how a native library is opened.
enum NativeLibraryHost { android, ios, macos, windows, linux, fuchsia }

/// The file [name] is packaged as on [host], or null when there is no file.
///
/// Null is the iOS case: the library is linked into the app as a static
/// library, so its symbols live in the process and are opened with
/// `DynamicLibrary.process`. Every other target ships a file the build copies
/// next to the app.
String? nativeLibraryFileName(String name, NativeLibraryHost host) =>
    switch (host) {
      NativeLibraryHost.ios => null,
      NativeLibraryHost.android ||
      NativeLibraryHost.linux ||
      NativeLibraryHost.fuchsia => 'lib$name.so',
      NativeLibraryHost.macos => 'lib$name.dylib',
      NativeLibraryHost.windows => '$name.dll',
    };

/// Opens the native libraries this app ships over FFI.
///
/// The app's C ABI lives in a separate repository (`ExpTechTW/eq-report-pic`)
/// and is compiled per platform rather than built by Flutter. That makes
/// "the library is missing" a normal state — a build that has not run the
/// native step, or an ABI the store stripped — so opening one is a [Result],
/// never a throw. A screen that cannot draw its share image still alerts
/// people about an earthquake.
///
/// [openFile] and [openProcess] exist for tests, which run on a host that has
/// no native artifact; production callers omit them.
abstract final class NativeLibrary {
  /// Opens [name] for this device.
  ///
  /// [host] overrides the detected platform for tests. On iOS the symbols are
  /// already in the process, so [openProcess] is used and [openFile] is not
  /// called; elsewhere [openFile] receives the packaged file name.
  static Result<DynamicLibrary> open(
    String name, {
    NativeLibraryHost? host,
    DynamicLibrary Function(String fileName)? openFile,
    DynamicLibrary Function()? openProcess,
  }) {
    final resolvedHost = host ?? _host();
    if (resolvedHost == null) {
      return Err(
        UnexpectedFailure('FFI is not wired for ${Platform.operatingSystem}'),
      );
    }

    final fileName = nativeLibraryFileName(name, resolvedHost);
    try {
      final library = fileName == null
          ? (openProcess ?? DynamicLibrary.process)()
          : (openFile ?? DynamicLibrary.open)(fileName);
      Log.debug('ffi: opened $name from ${fileName ?? 'the process'}');
      return Ok(library);
    } catch (error) {
      // The OS message names the file and the reason ("image not found",
      // "cannot open shared object file"); keep it, it is the only clue a
      // build step is missing.
      Log.warning('ffi: $name unavailable on ${resolvedHost.name}: $error');
      return Err(
        UnexpectedFailure('Native library "$name" is not available: $error'),
      );
    }
  }

  /// This device's host, or null when FFI has no mapping for it.
  static NativeLibraryHost? _host() => switch (Platform.operatingSystem) {
    'android' => NativeLibraryHost.android,
    'ios' => NativeLibraryHost.ios,
    'macos' => NativeLibraryHost.macos,
    'windows' => NativeLibraryHost.windows,
    'linux' => NativeLibraryHost.linux,
    'fuchsia' => NativeLibraryHost.fuchsia,
    _ => null,
  };
}
