import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input_v3.dart';
import 'package:dpip/shared/seismic/report_picture/eq_report_pic_bindings.dart';
import 'package:flutter_test/flutter_test.dart';

const _fixtures = 'test/features/earthquake/domain/fixtures/share_input_v3';

void main() {
  final env = Platform.environment;
  final profile = env['DPIP_EQR_MATRIX_PROFILE'];
  final path = env['DPIP_EQR_MATRIX_LIBRARY'];
  final reference = env['DPIP_EQR_MATRIX_REFERENCE'];
  if (profile == null) {
    test(
      'approved v3 renderer matrix',
      () {},
      skip: 'Set DPIP_EQR_MATRIX_PROFILE, DPIP_EQR_MATRIX_LIBRARY and DPIP_EQR_MATRIX_REFERENCE.',
    );
    return;
  }
  final qa = profile == 'qa';

  group('approved v3 renderer matrix ($profile)', () {
    late EqReportPic renderer;
    setUpAll(() {
      expect(profile, anyOf('production', 'qa'));
      expect(path, isNotNull, reason: 'Set DPIP_EQR_MATRIX_LIBRARY.');
      expect(reference, isNotNull, reason: 'Set DPIP_EQR_MATRIX_REFERENCE.');
      // Run the two profiles in separate test processes.
      final bindings = EqReportPicBindings(
        DynamicLibrary.open(path!),
        storyQa: qa,
      );
      expect(bindings.sharePngV3Unavailable(), isNull);
      renderer = EqReportPic.create(bindings, [
        for (final font in [
          'mplus-2p-bold.ttf',
          'GenShinGothic-Bold.ttf',
          'NotoSansTC-Black.ttf',
        ])
          File('assets/fonts/report/$font').readAsBytesSync(),
      ]);
    });
    tearDownAll(() => renderer.dispose());

    final corpus = (jsonDecode(
      File('$_fixtures/corpus.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    for (final entry in corpus) {
      final id = entry['report_id'] as String;
      CoreEarthquakeReportSnapshot snapshot() =>
          CoreEarthquakeReportSnapshot.decode(
            File('$_fixtures/raw/$id.json').readAsBytesSync(),
            requestedReportId: id,
          );
      if (entry['eligible'] != true) {
        test('$id is ineligible', () {
          expect(
            () => adaptEarthquakeShareSnapshotV3(snapshot()),
            throwsA(
              isA<EarthquakeReportSourceException>().having(
                (error) => error.code,
                'code',
                EarthquakeReportSourceError.unsupportedProfile,
              ),
            ),
          );
        });
        continue;
      }

      late final input = adaptEarthquakeShareSnapshotV3(snapshot());
      for (final (format, layout) in [
        (EqShareFormat.landscape16By9, '16x9'),
        (EqShareFormat.information4By5, '4x5'),
        if (qa) (EqShareFormat.story9By16, '9x16'),
      ]) {
        final modes = format == EqShareFormat.information4By5
            ? const [EqMapMode.cluster]
            : EqMapMode.values;
        for (final mode in modes) {
          for (final theme in EqTheme.values) {
            final name = '$id-$layout-${mode.name}-${theme.name}';
            test('$name matches approved PNG bytes', () {
              final png = renderer.renderSharePngV3(
                input.bytes,
                mode: mode,
                theme: theme,
                format: format,
              );
              final approved = File('$reference/$name.png').readAsBytesSync();
              expect(sha256.convert(png), sha256.convert(approved));
            });
          }
        }
      }
    }
  });
}
