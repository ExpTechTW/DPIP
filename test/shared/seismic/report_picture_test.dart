import 'dart:ffi';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fonts', () {
    test('every font the renderer is given is bundled and non-empty', () async {
      expect(ReportPicture.fontAssets, hasLength(3));
      for (final asset in ReportPicture.fontAssets) {
        final data = await rootBundle.load(asset);
        expect(
          data.lengthInBytes,
          greaterThan(100 * 1024),
          reason: '$asset looks truncated',
        );
      }
    });
  });

  group('ReportPicture.open', () {
    test('an unavailable library is a Result, not a throw', () async {
      final result = await ReportPicture.open(
        openLibrary: (_) => const Err(UnexpectedFailure('missing')),
      );

      final failure = result.failureOrNull;
      expect(failure, isA<ReportPictureFailure>());
      expect(
        (failure! as ReportPictureFailure).reason,
        ReportPictureFailureReason.unavailable,
      );
      expect(failure.message, contains('missing'));
    });

    test('a library without the ABI fails at open, not mid-render', () async {
      // The host process has no `eqr_*` symbols, so the lookup in the bindings
      // is the same thing an older ABI would trigger on a real library.
      final result = await ReportPicture.open(
        openLibrary: (_) => Ok(DynamicLibrary.process()),
      );

      final failure = result.failureOrNull;
      expect(failure, isA<ReportPictureFailure>());
      expect(
        (failure! as ReportPictureFailure).reason,
        ReportPictureFailureReason.unavailable,
      );
      expect(failure.message, contains('symbols'));
    });
  });
}
