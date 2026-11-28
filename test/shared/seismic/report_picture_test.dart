import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/shared/seismic/report_picture/eq_report_pic_bindings.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher _failure(ReportPictureFailureReason reason, {int? nativeStatus}) =>
    isA<ReportPictureFailure>()
        .having((failure) => failure.reason, 'reason', reason)
        .having(
          (failure) => failure.nativeStatus,
          'native status',
          nativeStatus,
        );

void main() {
  test('distinguishes loader failure from an incompatible loaded image', () {
    final missing = probeReportPictureBindings(
      const Err(UnexpectedFailure('image not found')),
      fromProcess: false,
    );
    expect(
      missing.failureOrNull,
      _failure(ReportPictureFailureReason.unavailable),
    );
    expect(missing.failureOrNull!.message, contains('image not found'));

    final noExports = Ok(DynamicLibrary.process());
    expect(
      probeReportPictureBindings(noExports, fromProcess: true).failureOrNull,
      _failure(ReportPictureFailureReason.unavailable),
    );
    expect(
      probeReportPictureBindings(noExports, fromProcess: false).failureOrNull,
      _failure(ReportPictureFailureReason.unsupportedAbi),
    );
  });

  test(
    'queues concurrent callers, snapshots inputs and drains on disposal',
    () async {
      final firstStarted = Completer<void>();
      final firstOutput = Completer<Uint8List>();
      final recoveredStarted = Completer<void>();
      final recoveredOutput = Completer<Uint8List>();
      final requests = <(int, EqMapMode, EqTheme)>[];
      var releases = 0;
      final picture = ReportPicture.forTesting((input, mode, theme, format) {
        expect(format, EqShareFormat.landscape16By9);
        requests.add((input.single, mode, theme));
        switch (input.single) {
          case 1:
            firstStarted.complete();
            return firstOutput.future;
          case 2:
            throw EqShareRenderException(
              'bad input',
              EqShareRenderError.invalidArgument,
              nativeStatus: -1,
            );
          case 3:
            recoveredStarted.complete();
            return recoveredOutput.future;
          default:
            throw StateError('unexpected input');
        }
      }, () => releases++);

      final first = picture.renderSharePngV2(Uint8List.fromList([1]));
      final invalid = picture.renderSharePngV2(Uint8List.fromList([2]));
      final buffer = Uint8List.fromList([3]);
      final recovered = picture.renderSharePngV2(
        buffer,
        mode: EqMapMode.stations,
        theme: EqTheme.dark,
      );
      buffer[0] = 0;
      await firstStarted.future;
      expect(requests, [(1, EqMapMode.cluster, EqTheme.light)]);

      final disposal = picture.dispose();
      expect(picture.dispose(), same(disposal));
      expect(
        (await picture.renderSharePngV2(buffer)).failureOrNull,
        _failure(ReportPictureFailureReason.disposed),
      );
      expect(releases, 0);

      firstOutput.complete(Uint8List.fromList([11]));
      expect((await first).valueOrNull, [11]);
      expect(
        (await invalid).failureOrNull,
        _failure(ReportPictureFailureReason.invalidInput, nativeStatus: -1),
      );
      await recoveredStarted.future;
      expect(requests, [
        (1, EqMapMode.cluster, EqTheme.light),
        (2, EqMapMode.cluster, EqTheme.light),
        (3, EqMapMode.stations, EqTheme.dark),
      ]);
      expect(releases, 0);
      recoveredOutput.complete(Uint8List.fromList([33]));
      expect((await recovered).valueOrNull, [33]);
      await disposal;
      expect(releases, 1);
      expect(
        (await picture.renderSharePngV2(buffer)).failureOrNull,
        _failure(ReportPictureFailureReason.disposed),
      );
    },
  );

  test(
    'normalizes a failed render Future and allows a later request',
    () async {
      var renders = 0;
      final picture = ReportPicture.forTesting((input, _, _, _) async {
        if (++renders == 1) throw StateError('background render failed');
        return input;
      }, () {});
      addTearDown(picture.dispose);

      final skipped = await picture.renderSharePngV2(
        Uint8List(1024 * 1024 + 1),
      );
      expect(
        skipped.failureOrNull,
        _failure(ReportPictureFailureReason.limitExceeded),
      );
      expect(renders, 0);

      final failure = await picture.renderSharePngV2(Uint8List(0));
      expect(
        failure.failureOrNull,
        _failure(ReportPictureFailureReason.renderFailed),
      );
      expect(
        failure.failureOrNull!.message,
        contains('background render failed'),
      );
      expect(
        (await picture.renderSharePngV2(Uint8List.fromList([1]))).valueOrNull,
        [1],
      );
    },
  );
}
