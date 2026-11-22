import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/shared/seismic/report_picture/eq_report_pic_bindings.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtureDir = String.fromEnvironment('DPIP_EQR_FFI_FIXTURES');

DynamicLibrary _library(String name) {
  final extension = Platform.isMacOS ? 'dylib' : 'so';
  return DynamicLibrary.open('$_fixtureDir/$name.$extension');
}

Uint8List _render(EqReportPic renderer, List<int> bytes) =>
    renderer.renderSharePngV2(
      Uint8List.fromList(bytes),
      mode: EqMapMode.stations,
      theme: EqTheme.dark,
    );

final class _FailingAllocator implements Allocator {
  _FailingAllocator(this.failAt);

  final int failAt;
  final outstanding = <Pointer<NativeType>>{};
  var allocations = 0;

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    if (++allocations == failAt) throw StateError('fixture allocation failure');
    final pointer = malloc.allocate<T>(byteCount, alignment: alignment);
    outstanding.add(pointer);
    return pointer;
  }

  @override
  void free(Pointer<NativeType> pointer) {
    expect(outstanding.remove(pointer), isTrue);
    malloc.free(pointer);
  }
}

void main() {
  group(
    'report-picture C ABI test double',
    skip: _fixtureDir.isEmpty
        ? 'Run tool/dev/test_report_picture.sh to build the C fixtures.'
        : null,
    () {
      for (final (variant, diagnostic) in [
        ('missing-abi', 'Missing eqr_abi_info'),
        ('old-abi', 'Unsupported native ABI 1.1'),
        ('incompatible-major', 'Unsupported native ABI 2.2'),
        ('missing-v2-capability', 'EQR_CAP_SHARE_INPUT_V2'),
        ('missing-16-9-capability', 'EQR_CAP_PRODUCTION_16_9'),
        ('missing-render', 'Missing eqr_render_share_png_v2'),
      ]) {
        test('rejects $variant when opening the runtime', () {
          final result = probeReportPictureBindings(
            Ok(_library(variant)),
            fromProcess: false,
          );
          expect(
            result.failureOrNull,
            isA<ReportPictureFailure>()
                .having(
                  (failure) => failure.reason,
                  'reason',
                  ReportPictureFailureReason.unsupportedAbi,
                )
                .having(
                  (failure) => failure.message,
                  'diagnostic',
                  contains(diagnostic),
                ),
          );
        });
      }

      test('frees temporary fonts after partial initialization fails', () {
        final bindings = EqReportPicBindings(_library('supported'));
        final fonts = [
          Uint8List.fromList([7]),
          Uint8List.fromList([8]),
        ];
        for (final failAt in [2, 4]) {
          final allocator = _FailingAllocator(failAt);
          addTearDown(() {
            for (final pointer in allocator.outstanding) {
              malloc.free(pointer);
            }
          });
          expect(
            () => EqReportPic.create(bindings, fonts, fontAllocator: allocator),
            throwsStateError,
          );
          expect(allocator.allocations, failAt);
          expect(allocator.outstanding, isEmpty);
        }
      });

      test('copies output, frees once, and releases failed copies and owned handles', () {
        final lib = _library('supported');
        final bindings = probeReportPictureBindings(
          Ok(lib),
          fromProcess: false,
        ).valueOrNull!;
        final frees = lib.lookupFunction<Uint32 Function(), int Function()>(
          'fixture_buffer_frees',
        );
        final live = lib.lookupFunction<Uint32 Function(), int Function()>(
          'fixture_live_renderers',
        );
        final outstanding = lib
            .lookupFunction<Uint32 Function(), int Function()>(
              'fixture_outstanding_buffers',
            );
        final startFrees = frees();
        List<int>? firstPng;
        for (var i = 0; i < 2; i++) {
          final owner = EqReportPic.create(bindings, [
            Uint8List.fromList([7]),
          ]);
          try {
            expect(live(), 1);
            final borrowed = EqReportPic.fromAddress(bindings, owner.address);
            final png = _render(borrowed, [2 + i]);
            borrowed.dispose();
            expect(live(), 1);
            expect(png, [2 + i, 1, 1]);
            firstPng ??= png;
            expect(frees(), startFrees + 1 + 3 * i);

            expect(() => _render(owner, [1]), throwsA(isA<ArgumentError>()));
            expect(frees(), startFrees + 2 + 3 * i);
            expect(
              () => _render(owner, [255]),
              throwsA(
                isA<EqReportPicException>().having(
                  (error) => error.message,
                  'diagnostic',
                  contains('empty PNG buffer'),
                ),
              ),
            );
            expect(
              () => _render(owner, [0]),
              throwsA(
                isA<EqReportPicException>().having(
                  (error) => error.message,
                  'diagnostic',
                  contains('without a PNG buffer'),
                ),
              ),
            );
            expect(
              () => _render(owner, []),
              throwsA(
                isA<EqShareRenderException>()
                    .having(
                      (error) => error.reason,
                      'reason',
                      EqShareRenderError.invalidArgument,
                    )
                    .having((error) => error.nativeStatus, 'status', -1)
                    .having(
                      (error) => error.message,
                      'diagnostic',
                      'fixture render error',
                    ),
              ),
            );
            expect(frees(), startFrees + 3 + 3 * i);
          } finally {
            owner.dispose();
          }
          owner.dispose();
          expect(live(), 0);
          expect(firstPng, [2, 1, 1]);
          expect(outstanding(), 0);
        }
      });
    },
  );
}
