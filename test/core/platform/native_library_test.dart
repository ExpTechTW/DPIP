import 'dart:ffi';

import 'package:dpip/core/platform/native_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nativeLibraryFileName', () {
    test('Android and Linux load the .so by its base name', () {
      expect(
        nativeLibraryFileName('eq_report_pic', NativeLibraryHost.android),
        'libeq_report_pic.so',
      );
      expect(
        nativeLibraryFileName('eq_report_pic', NativeLibraryHost.linux),
        'libeq_report_pic.so',
      );
    });

    test('iOS has no file — the symbols are linked into the app', () {
      expect(
        nativeLibraryFileName('eq_report_pic', NativeLibraryHost.ios),
        isNull,
        reason: 'DynamicLibrary.process is the only way in on iOS',
      );
    });

    test('desktop uses its own extension', () {
      expect(
        nativeLibraryFileName('eq_report_pic', NativeLibraryHost.macos),
        'libeq_report_pic.dylib',
      );
      expect(
        nativeLibraryFileName('eq_report_pic', NativeLibraryHost.windows),
        'eq_report_pic.dll',
      );
    });
  });

  group('NativeLibrary.open', () {
    test('a missing file is a Result, not a throw', () {
      final result = NativeLibrary.open(
        'dpip_no_such_native_library',
        host: NativeLibraryHost.linux,
      );

      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull!.message, contains('not available'));
    });

    test(
      'the OS message survives — it is the only clue a build step is missing',
      () {
        final result = NativeLibrary.open(
          'dpip_no_such_native_library',
          host: NativeLibraryHost.linux,
        );

        expect(
          result.failureOrNull!.message,
          contains('dpip_no_such_native_library'),
        );
      },
    );

    test('iOS reads the process and never opens a file', () {
      var fileOpens = 0;
      final result = NativeLibrary.open(
        'anything',
        host: NativeLibraryHost.ios,
        openFile: (_) {
          fileOpens++;
          return DynamicLibrary.process();
        },
        openProcess: DynamicLibrary.process,
      );

      expect(result.isOk, isTrue);
      expect(fileOpens, 0);
    });

    test('the packaged file name is what the loader is asked to open', () {
      String? opened;
      final result = NativeLibrary.open(
        'eq_report_pic',
        host: NativeLibraryHost.android,
        openFile: (fileName) {
          opened = fileName;
          return DynamicLibrary.process();
        },
      );

      expect(result.isOk, isTrue);
      expect(opened, 'libeq_report_pic.so');
    });

    test('a loader that throws is wrapped, keeping its message', () {
      final result = NativeLibrary.open(
        'eq_report_pic',
        host: NativeLibraryHost.android,
        openFile: (_) => throw ArgumentError('cannot open shared object file'),
      );

      expect(result.isOk, isFalse);
      expect(
        result.failureOrNull!.message,
        contains('cannot open shared object file'),
      );
    });
  });
}
