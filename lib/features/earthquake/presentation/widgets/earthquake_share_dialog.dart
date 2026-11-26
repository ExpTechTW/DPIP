import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/system_settings.dart';
import 'package:dpip/core/platform/image_clipboard.dart';
import 'package:dpip/core/platform/image_saver.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:dpip/features/earthquake/presentation/widgets/report_image_save_feedback.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum _ShareIssue { language, report, renderer, incompatible, timeout, failed }

enum _ExportFeedback { saved, copied, copyFailed, shareFailed }

enum _ExportAction { save, copy, share }

/// Displays and exports the current PNG rendered for one report.
class _ShareOptions {
  const _ShareOptions(this.format, this.mode, this.theme);

  final EqShareFormat format;
  final EqMapMode mode;
  final EqTheme theme;

  bool get showsMap => format != EqShareFormat.information4By5;

  String get fileSuffix => switch (format) {
    EqShareFormat.information4By5 => '${theme.name}-4x5',
    EqShareFormat.landscape16By9 => '${theme.name}-16x9-${mode.name}',
    EqShareFormat.story9By16 => '${theme.name}-9x16-${mode.name}',
  };
}

class EarthquakeShareDialog extends StatefulWidget {
  const EarthquakeShareDialog({
    super.key,
    required this.report,
    required this.loadInput,
    required this.saver,
    required this.isReportCurrent,
    this.openRenderer = ReportPicture.open,
    this.share,
    this.renderTimeout = const Duration(seconds: 20),
  });

  final EarthquakeReport report;
  final Future<Result<EarthquakeShareInput>> Function() loadInput;
  final ImageSaver saver;
  final bool Function() isReportCurrent;
  final Future<Result<ReportPicture>> Function() openRenderer;
  final Future<ShareResult> Function(ShareParams)? share;
  final Duration renderTimeout;

  @override
  State<EarthquakeShareDialog> createState() => _EarthquakeShareDialogState();
}

class _EarthquakeShareDialogState extends State<EarthquakeShareDialog> {
  EqShareFormat _format = EqShareFormat.information4By5;
  EqMapMode _mode = EqMapMode.cluster;

  _ShareOptions get _options => _ShareOptions(
    _format,
    _format == EqShareFormat.information4By5 ? EqMapMode.cluster : _mode,
    _theme,
  );

  late EqTheme _theme;
  Locale? _locale;
  ModalRoute<dynamic>? _route;
  late Future<Uint8List> _preview;
  Future<void> _renderTail = Future.value();
  int _generation = 0;
  bool _exporting = false;
  Object? _feedback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final locale = Localizations.localeOf(context);
    if (_locale == null) {
      _theme = Theme.of(context).brightness == Brightness.dark
          ? EqTheme.dark
          : EqTheme.light;
    }
    if (locale != _locale) {
      _locale = locale;
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant EarthquakeShareDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.report != oldWidget.report) _start();
  }

  bool _isCurrent(int generation) =>
      mounted &&
      generation == _generation &&
      _route?.isCurrent == true &&
      widget.isReportCurrent();

  void _start() {
    final generation = ++_generation;
    _feedback = null;
    _preview = _generate(generation, _options).timeout(
      widget.renderTimeout,
      onTimeout: () {
        if (generation == _generation) ++_generation;
        throw _ShareIssue.timeout;
      },
    );
  }

  Future<Uint8List> _generate(int generation, _ShareOptions options) async {
    if (_locale != kHomeLocale) throw _ShareIssue.language;
    final loaded = await widget.loadInput();
    if (loaded.failureOrNull case final failure?) throw failure;
    final input = loaded.valueOrNull;
    if (input is! EarthquakeShareInputV2) throw _ShareIssue.report;

    // Skip superseded work before allocating native state. A synchronous FFI
    // call already in progress is allowed to finish and release its handle.
    final render = _renderTail.then((_) async {
      if (!_isCurrent(generation)) throw _ShareIssue.report;
      final opened = await widget.openRenderer();
      final renderer = opened.valueOrNull ?? (throw opened.failureOrNull!);
      try {
        if (!_isCurrent(generation)) throw _ShareIssue.report;
        final response = await renderer.renderSharePngV2(
          input.bytes,
          mode: options.mode,
          theme: options.theme,
          format: options.format,
        );
        final png = response.valueOrNull ?? (throw response.failureOrNull!);
        if (!_isCurrent(generation)) throw _ShareIssue.report;
        await _validatePreview(png, options.format);
        return png.asUnmodifiableView();
      } finally {
        await renderer.dispose();
      }
    });
    _renderTail = render.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return render;
  }

  Future<void> _validatePreview(Uint8List png, EqShareFormat format) async {
    final codec = await ui.instantiateImageCodec(png);
    try {
      final frame = await codec.getNextFrame();
      try {
        if (frame.image.width != format.width ||
            frame.image.height != format.height) {
          throw const FormatException('Unexpected report PNG dimensions');
        }
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<void> _export(
    int generation,
    Uint8List png,
    _ExportAction action, {
    Rect? shareOrigin,
  }) async {
    if (_exporting || !_isCurrent(generation)) return;
    setState(() {
      _exporting = true;
      _feedback = null;
    });
    final fileName =
        'dpip-earthquake-${widget.report.id}-${_options.fileSuffix}.png';
    Object? feedback;
    try {
      switch (action) {
        case _ExportAction.share:
          final result = await _sharePng(
            generation,
            png,
            fileName,
            shareOrigin!,
          );
          if (result?.status == ShareResultStatus.unavailable) {
            feedback = _ExportFeedback.shareFailed;
          }
        case _ExportAction.save:
          final result = await widget.saver.saveToGalleryIfCurrent(
            bytes: png,
            fileName: fileName,
            isCurrent: () => _isCurrent(generation),
          );
          feedback = result?.when(
            ok: (_) => _ExportFeedback.saved,
            err: imageSaveFailureReason,
          );
        case _ExportAction.copy:
          if (await copyPngToClipboard(png)) feedback = _ExportFeedback.copied;
      }
    } catch (error, stackTrace) {
      Log.handle(
        error,
        stackTrace,
        'Exporting the earthquake share image failed',
      );
      feedback = switch (action) {
        _ExportAction.save => ImageSaveFailureReason.failed,
        _ExportAction.copy => _ExportFeedback.copyFailed,
        _ExportAction.share => _ExportFeedback.shareFailed,
      };
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          if (_isCurrent(generation)) _feedback = feedback;
        });
      }
    }
  }

  Future<ShareResult?> _sharePng(
    int generation,
    Uint8List bytes,
    String fileName,
    Rect origin,
  ) async {
    if (widget.share case final share?) {
      return share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: [fileName],
          sharePositionOrigin: origin,
        ),
      );
    }

    final cache = await getTemporaryDirectory();
    final directory = await cache.createTemp('dpip-earthquake-share-');
    try {
      final file = File.fromUri(directory.uri.resolve(fileName));
      await file.writeAsBytes(bytes);
      if (!_isCurrent(generation)) return null;
      return await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      // Android's chooser uses Share Plus's separate shared cache. On iOS
      // the activity controller has completed before the future returns.
      try {
        await directory.delete(recursive: true);
      } on FileSystemException catch (error) {
        Log.warning('Could not remove temporary earthquake image: $error');
      }
    }
  }

  _ShareIssue _issueFor(Object error) => switch (error) {
    _ShareIssue issue => issue,
    ReportPictureFailure(reason: ReportPictureFailureReason.unavailable) =>
      _ShareIssue.renderer,
    ReportPictureFailure(
      reason: ReportPictureFailureReason.unsupportedAbi ||
          ReportPictureFailureReason.unsupportedFeature,
    ) =>
      _ShareIssue.incompatible,
    ReportPictureFailure(
      reason: ReportPictureFailureReason.invalidInput ||
          ReportPictureFailureReason.unsupportedVersion ||
          ReportPictureFailureReason.limitExceeded,
    ) =>
      _ShareIssue.report,
    _ => _ShareIssue.failed,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: _preview,
      builder: (context, snapshot) {
        final generation = _generation;
        final done = snapshot.connectionState == ConnectionState.done;
        final error = done ? snapshot.error : null;
        final issue = error == null ? null : _issueFor(error);
        final png = done && widget.isReportCurrent() ? snapshot.data : null;
        final message = switch (issue) {
          _ShareIssue.language => l10n.reportShareUnsupportedLanguage,
          _ShareIssue.report => l10n.reportShareUnsupportedReport,
          _ShareIssue.renderer => l10n.reportShareRendererUnavailable,
          _ShareIssue.incompatible => l10n.reportShareRendererIncompatible,
          _ShareIssue.timeout => l10n.reportShareTimeout,
          _ShareIssue.failed => l10n.reportShareRenderFailed,
          null =>
            done && png == null ? l10n.reportShareUnsupportedReport : null,
        };
        final canRetry =
            issue == _ShareIssue.failed || issue == _ShareIssue.timeout;
        return AlertDialog(
          // The preview and map controls change height as options are tapped.
          // Keep the format row in place while those changes settle.
          alignment: Alignment.topCenter,
          scrollable: true,
          title: Text(l10n.reportShareTitle),
          content: SizedBox(
            width: 364,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (issue != _ShareIssue.language &&
                    issue != _ShareIssue.report &&
                    issue != _ShareIssue.renderer) ...[
                  _ShareChoices<EqShareFormat>(
                    label: l10n.reportShareFormat,
                    options: {
                      EqShareFormat.landscape16By9: '16:9',
                      EqShareFormat.information4By5: '4:5',
                      if (reportPictureStoryQa)
                        EqShareFormat.story9By16: '9:16',
                    },
                    value: _format,
                    onChanged: _exporting
                        ? null
                        : (format) => setState(() {
                            _format = format;
                            _start();
                          }),
                  ),
                  if (_options.showsMap) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ShareChoices<EqMapMode>(
                      label: l10n.reportShareMapMode,
                      options: {
                        EqMapMode.cluster: l10n.reportShareCluster,
                        EqMapMode.stations: l10n.reportShareStations,
                        EqMapMode.towns: l10n.reportShareTowns,
                      },
                      value: _mode,
                      onChanged: _exporting
                          ? null
                          : (mode) => setState(() {
                              _mode = mode;
                              _start();
                            }),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _ShareChoices<EqTheme>(
                    label: l10n.reportShareTheme,
                    options: {
                      EqTheme.light: l10n.themeLight,
                      EqTheme.dark: l10n.themeDark,
                    },
                    value: _theme,
                    onChanged: _exporting
                        ? null
                        : (theme) => setState(() {
                            _theme = theme;
                            _start();
                          }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (message != null)
                  Semantics(liveRegion: true, child: Text(message))
                else if (png == null)
                  Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: l10n.commonLoading,
                    ),
                  )
                else
                  _PngPreview(bytes: png, label: l10n.reportSharePreview),
                if (_feedback case final feedback?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(switch (feedback) {
                      _ExportFeedback.saved => l10n.reportDetailImageSaved,
                      _ExportFeedback.copied => l10n.reportShareCopied,
                      _ExportFeedback.copyFailed => l10n.reportShareCopyFailed,
                      ImageSaveFailureReason reason => reason.message(l10n),
                      _ => l10n.reportShareExportFailed,
                    }),
                  ),
                  if (feedback ==
                      ImageSaveFailureReason.permissionSettingsRequired)
                    TextButton(
                      onPressed: openAppSettingsPage,
                      child: Text(l10n.permissionOpenSettings),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(done ? l10n.commonClose : l10n.commonCancel),
            ),
            if (canRetry)
              FilledButton(
                onPressed: () => setState(_start),
                child: Text(l10n.commonRetry),
              ),
            if (png != null) ...[
              TextButton(
                onPressed: _exporting
                    ? null
                    : () => _export(generation, png, _ExportAction.save),
                child: Text(l10n.reportDetailImageSave),
              ),
              TextButton(
                onPressed: _exporting
                    ? null
                    : () => _export(generation, png, _ExportAction.copy),
                child: Text(l10n.reportShareCopy),
              ),
              Builder(
                builder: (buttonContext) => FilledButton(
                  onPressed: _exporting
                      ? null
                      : () {
                          final box =
                              buttonContext.findRenderObject()! as RenderBox;
                          _export(
                            generation,
                            png,
                            _ExportAction.share,
                            shareOrigin:
                                box.localToGlobal(Offset.zero) & box.size,
                          );
                        },
                  child: Text(l10n.reportShareSend),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ShareChoices<T> extends StatelessWidget {
  const _ShareChoices({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Map<T, String> options;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final entry in options.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: value == entry.key,
              onSelected: onChanged == null
                  ? null
                  : (selected) {
                      if (selected) onChanged!(entry.key);
                    },
            ),
        ],
      ),
    ],
  );
}

class _PngPreview extends StatefulWidget {
  const _PngPreview({required this.bytes, required this.label});

  final Uint8List bytes;
  final String label;

  @override
  State<_PngPreview> createState() => _PngPreviewState();
}

class _PngPreviewState extends State<_PngPreview> {
  @override
  void didUpdateWidget(covariant _PngPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      unawaited(MemoryImage(oldWidget.bytes).evict());
    }
  }

  @override
  void dispose() {
    unawaited(MemoryImage(widget.bytes).evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .38,
    ),
    child: Image.memory(
      widget.bytes,
      fit: BoxFit.contain,
      semanticLabel: widget.label,
    ),
  );
}
