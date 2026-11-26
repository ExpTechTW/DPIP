import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'report_picture_fixture.dart';

/// Separate QA entry point. The ordinary app has no dependency on this harness.
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final status = ValueNotifier('RUNNING');
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: status,
          builder: (_, value, _) => Text('REPORT_PICTURE_MATRIX $value'),
        ),
      ),
    ),
  );
  await binding.endOfFrame;
  try {
    final count = await _renderMatrix();
    status.value = 'PASS $count';
  } catch (error) {
    status.value = 'FAIL $error';
    rethrow;
  }
}

Future<int> _renderMatrix() async {
  if (!reportPictureStoryQa) throw StateError('Story QA flavor required');
  final fixture = ReportPictureFixtures.loadVerified();
  final input = fixture.verifiedInput();
  final sandbox = await getApplicationDocumentsDirectory();
  final directory = await Directory('${sandbox.path}/report-picture-matrix')
      .create(recursive: true);
  final stopwatch = Stopwatch()..start();
  final opened = await ReportPicture.open();
  final renderer = opened.valueOrNull ?? (throw opened.failureOrNull!);
  final openUs = stopwatch.elapsedMicroseconds;
  final outputs = <Map<String, Object>>[];
  try {
    for (final format in EqShareFormat.values) {
      final modes = format == EqShareFormat.information4By5
          ? const [EqMapMode.cluster]
          : EqMapMode.values;
      for (final mode in modes) {
        for (final theme in EqTheme.values) {
          stopwatch.reset();
          final response = await renderer.renderSharePngV2(
            input.bytes,
            format: format,
            mode: mode,
            theme: theme,
          );
          final bytes = response.valueOrNull ?? (throw response.failureOrNull!);
          final renderUs = stopwatch.elapsedMicroseconds;
          final codec = await ui.instantiateImageCodec(bytes);
          try {
            final frame = await codec.getNextFrame();
            try {
              if (frame.image.width != format.width ||
                  frame.image.height != format.height) {
                throw StateError('Unexpected dimensions for ${format.name}');
              }
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
          }
          final name = '${format.nativeId}-${mode.name}-${theme.name}.png';
          await File('${directory.path}/$name').writeAsBytes(bytes);
          outputs.add({
            'file': name,
            'format': format.name,
            'mode': mode.name,
            'theme': theme.name,
            'width': format.width,
            'height': format.height,
            'sha256': sha256.convert(bytes).toString(),
            'render_us': renderUs,
            'rss_bytes': ProcessInfo.currentRss,
          });
        }
      }
    }
  } finally {
    await renderer.dispose();
  }
  if (outputs.length != 14 ||
      outputs.map((row) => row['sha256']).toSet().length != 14) {
    throw StateError('Expected 14 distinct rendered PNGs');
  }
  final output = File('${directory.path}/matrix.json');
  await output.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'report_id': fixture.snapshot.report.id,
      'source_sha256': fixture.snapshot.bodySha256,
      'input_sha256': sha256.convert(input.bytes).toString(),
      'open_us': openUs,
      'peak_rss_bytes': ProcessInfo.maxRss,
      'outputs': outputs,
    }),
    flush: true,
  );
  return outputs.length;
}
