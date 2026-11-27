import 'dart:async';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/native_library.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'report_picture_fixture.dart';
import 'report_picture_native_info.dart';

void main() => runApp(const MaterialApp(home: ReportPicturePreview()));

enum PreviewScenario {
  verified('臺東縣近海 · 已查證'),
  missingEvidence('臺東縣近海 · 缺少身分證據'),
  historical('美濃歷史報告 · 缺少適用身分');

  const PreviewScenario(this.label);

  final String label;
}

typedef PreviewImage = ({
  Uint8List png,
  int width,
  int height,
  String sha256,
  int abi,
  int capabilities,
});

Future<PreviewImage> _generate(
  PreviewScenario scenario,
  EqTheme theme,
  EqShareFormat format,
) async {
  final input = switch (scenario) {
    PreviewScenario.verified =>
      ReportPictureFixtures.loadVerified().verifiedInput(),
    PreviewScenario.missingEvidence =>
      ReportPictureFixtures.loadVerified().withoutIdentities(),
    PreviewScenario.historical =>
      ReportPictureFixtures.historicalWithoutIdentities(),
  };
  if (input is UnsupportedEarthquakeShareInput) throw input;
  if (scenario != PreviewScenario.verified) {
    throw StateError('預期轉接器拒絕此樣本，但驗證通過。');
  }

  final png = await renderPreviewPng(
    (input as EarthquakeShareInputV2).bytes,
    theme,
    format: format,
  );
  final library = NativeLibrary.open(ReportPicture.libraryName);
  final (abi, capabilities) = readReportPictureAbi(
    library.valueOrNull ?? (throw library.failureOrNull!),
  );
  final hash = await compute(_hashPng, png);
  final codec = await ui.instantiateImageCodec(png);
  try {
    final frame = await codec.getNextFrame();
    try {
      if (frame.image.width != format.width ||
          frame.image.height != format.height) {
        throw StateError('原生 PNG 尺寸與所選格式不符。');
      }
      return (
        png: png,
        width: frame.image.width,
        height: frame.image.height,
        sha256: hash,
        abi: abi,
        capabilities: capabilities,
      );
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

String _hashPng(Uint8List png) => sha256.convert(png).toString();

@visibleForTesting
Future<Uint8List> renderPreviewPng(
  Uint8List input,
  EqTheme theme, {
  EqShareFormat format = EqShareFormat.landscape16By9,
  Future<Result<ReportPicture>> Function() open = ReportPicture.openLegacyV2,
}) async {
  final opened = await open();
  final renderer = opened.valueOrNull ?? (throw opened.failureOrNull!);
  // This request owns the handle even if the screen is disposed mid-render.
  try {
    final output = await renderer.renderSharePngV2(
      input,
      theme: theme,
      format: format,
    );
    return output.valueOrNull ?? (throw output.failureOrNull!);
  } finally {
    await renderer.dispose();
  }
}

class ReportPicturePreview extends StatefulWidget {
  const ReportPicturePreview({super.key, this.generate = _generate});

  final Future<PreviewImage> Function(PreviewScenario, EqTheme, EqShareFormat)
  generate;

  @override
  State<ReportPicturePreview> createState() => _ReportPicturePreviewState();
}

class _ReportPicturePreviewState extends State<ReportPicturePreview> {
  final _previousHashes = <(EqShareFormat, EqTheme), String>{};
  var _format = EqShareFormat.landscape16By9;
  var _theme = EqTheme.light;
  var _scenario = PreviewScenario.verified;
  var _busy = false;
  PreviewImage? _image;
  Object? _error;
  bool? _matchesPrevious;

  Future<void> _render() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _resetResult();
    });
    try {
      final key = (_format, _theme);
      final image = await widget.generate(_scenario, _theme, _format);
      if (!mounted) return;
      final previous = _previousHashes[key];
      setState(() {
        _image = image;
        _matchesPrevious = previous == null ? null : previous == image.sha256;
        _previousHashes[key] = image.sha256;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _evictImage() {
    final image = _image;
    if (image != null) unawaited(MemoryImage(image.png).evict());
  }

  @override
  void dispose() {
    _evictImage();
    super.dispose();
  }

  void _resetResult() {
    _evictImage();
    _image = null;
    _error = null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final error = _error;
    final historical = _scenario == PreviewScenario.historical;
    return Scaffold(
      appBar: AppBar(title: const Text('地震分享圖 QA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('離線樣本', style: Theme.of(context).textTheme.titleLarge),
                  DropdownButton<PreviewScenario>(
                    isExpanded: true,
                    value: _scenario,
                    items: [
                      for (final scenario in PreviewScenario.values)
                        DropdownMenuItem(
                          value: scenario,
                          child: Text(scenario.label),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (scenario) {
                            if (scenario == null) return;
                            setState(() {
                              _scenario = scenario;
                              _resetResult();
                            });
                          },
                  ),
                  SelectableText(
                    historical
                        ? '報告 ${ReportPictureFixtures.historicalId}'
                        : '報告 ${ReportPictureFixtures.reportId}\n'
                              'ML 3.9 · 深度 43.5 km · 臺東縣 2、花蓮縣 1 · 5 筆測站\n'
                              '來源 SHA-256 ${ReportPictureFixtures.sourceHash}',
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SegmentedButton<EqShareFormat>(
                        segments: const [
                          ButtonSegment(
                            value: EqShareFormat.landscape16By9,
                            label: Text('16:9'),
                          ),
                          ButtonSegment(
                            value: EqShareFormat.information4By5,
                            label: Text('4:5'),
                          ),
                        ],
                        selected: {_format},
                        onSelectionChanged: _busy
                            ? null
                            : (formats) {
                                setState(() {
                                  _format = formats.single;
                                  _resetResult();
                                });
                              },
                      ),
                      SegmentedButton<EqTheme>(
                        segments: const [
                          ButtonSegment(
                            value: EqTheme.light,
                            label: Text('淺色'),
                          ),
                          ButtonSegment(value: EqTheme.dark, label: Text('深色')),
                        ],
                        selected: {_theme},
                        onSelectionChanged: _busy
                            ? null
                            : (themes) {
                                setState(() {
                                  _theme = themes.single;
                                  _resetResult();
                                });
                              },
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _render,
                        child: Text(
                          _busy
                              ? '產圖中…'
                              : error != null
                              ? '重試'
                              : image == null
                              ? '產生 PNG'
                              : '重新產生 PNG',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _busy
                          ? '處理中…'
                          : error != null
                          ? '產圖失敗'
                          : image == null
                          ? '等待產圖'
                          : '產圖成功',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (error != null) SelectableText(_describeError(error)),
                  if (image != null) ...[
                    SelectableText(
                      '${image.width} × ${image.height} px · ${image.png.length} bytes\n'
                      'ABI ${image.abi >> 16}.${image.abi & 0xffff} · '
                      'Capabilities 0x${image.capabilities.toRadixString(16)}\n'
                      'PNG SHA-256 ${image.sha256}\n'
                      '${switch (_matchesPrevious) {
                        null => '此格式與主題首次產圖',
                        true => '與上一次同格式與主題的 SHA-256 相同',
                        false => '與上一次同格式與主題的 SHA-256 不同',
                      }}',
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: image.width / image.height,
                      child: InteractiveViewer(
                        maxScale: 6,
                        child: Image.memory(
                          image.png,
                          semanticLabel: '原生 PNG 預覽',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _describeError(Object error) => switch (error) {
  UnsupportedEarthquakeShareInput() =>
    '轉接器 · ${error.code.name}\nJSON Pointer ${error.path.isEmpty ? '(root)' : error.path}\n${error.detail}',
  EarthquakeReportSourceException() =>
    '來源解析 · ${error.code.name}\nJSON Pointer ${error.path.isEmpty ? '(root)' : error.path}\n${error.message}',
  ReportPictureFailure() =>
    '原生渲染 · ${error.reason.name}'
        '${error.nativeStatus == null ? '' : '\nNative status ${error.nativeStatus}'}\n'
        '${error.message}'
        '${error.reason == ReportPictureFailureReason.unavailable ? '\n請依 QA 指南建置原生產物，再重新啟動。' : ''}',
  Failure() => '${error.runtimeType}\n${error.message}',
  _ => '${error.runtimeType}\n$error',
};
