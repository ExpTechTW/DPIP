import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/system_settings.dart';
import 'package:dpip/core/platform/image_saver.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/earthquake_share_input.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

enum _ShareIssue { language, report, renderer, incompatible, timeout, failed }

enum _ExportFeedback { saved, saveFailed, permissionDenied, shareFailed }

/// A single 4:5 information card. Each attempt owns its renderer until Rust
/// returns, even if the user closes the dialog or changes the theme first.
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
  static const _format = EqShareFormat.information4By5;

  late EqTheme _theme;
  Locale? _locale;
  ModalRoute<dynamic>? _route;
  late Future<Uint8List> _preview;
  Future<void> _renderTail = Future.value();
  int _generation = 0;
  bool _exporting = false;
  _ExportFeedback? _feedback;

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
    _preview = _generate(generation, _theme).timeout(
      widget.renderTimeout,
      onTimeout: () {
        if (generation == _generation) ++_generation;
        throw _ShareIssue.timeout;
      },
    );
  }

  Future<Uint8List> _generate(int generation, EqTheme theme) async {
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
          theme: theme,
          format: _format,
        );
        final png = response.valueOrNull ?? (throw response.failureOrNull!);
        if (!_isCurrent(generation)) throw _ShareIssue.report;
        await _validatePreview(png);
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

  Future<void> _validatePreview(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    try {
      final frame = await codec.getNextFrame();
      try {
        if (frame.image.width != _format.width ||
            frame.image.height != _format.height) {
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
    Uint8List png, {
    Rect? shareOrigin,
  }) async {
    if (_exporting || !_isCurrent(generation)) return;
    setState(() {
      _exporting = true;
      _feedback = null;
    });
    final fileName =
        'dpip-earthquake-${widget.report.id}-${_theme.name}-4x5.png';
    _ExportFeedback? feedback;
    try {
      if (shareOrigin != null) {
        final share = widget.share ?? SharePlus.instance.share;
        final result = await share(
          ShareParams(
            files: [XFile.fromData(png, mimeType: 'image/png')],
            fileNameOverrides: [fileName],
            sharePositionOrigin: shareOrigin,
          ),
        );
        if (result.status == ShareResultStatus.unavailable) {
          feedback = _ExportFeedback.shareFailed;
        }
      } else {
        final result = await widget.saver.saveToGalleryIfCurrent(
          bytes: png,
          fileName: fileName,
          isCurrent: () => _isCurrent(generation),
        );
        feedback = result?.when(
          ok: (_) => _ExportFeedback.saved,
          err: (failure) => switch (failure) {
            ImageSaveFailure(reason: ImageSaveFailureReason.permissionDenied) =>
              _ExportFeedback.permissionDenied,
            _ => _ExportFeedback.saveFailed,
          },
        );
      }
    } catch (error, stackTrace) {
      Log.handle(
        error,
        stackTrace,
        'Exporting the earthquake share image failed',
      );
      feedback = shareOrigin != null
          ? _ExportFeedback.shareFailed
          : _ExportFeedback.saveFailed;
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          if (_isCurrent(generation)) _feedback = feedback;
        });
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
          scrollable: true,
          title: Text(l10n.reportShareTitle),
          content: SizedBox(
            width: 364,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message == null || canRetry) ...[
                  SegmentedButton<EqTheme>(
                    segments: [
                      ButtonSegment(
                        value: EqTheme.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: EqTheme.dark,
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {_theme},
                    onSelectionChanged: _exporting
                        ? null
                        : (selected) {
                            if (selected.single == _theme) return;
                            setState(() {
                              _theme = selected.single;
                              _start();
                            });
                          },
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
                  Image.memory(
                    png,
                    fit: BoxFit.contain,
                    semanticLabel: l10n.reportSharePreview,
                  ),
                if (_feedback case final feedback?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    child: Text(switch (feedback) {
                      _ExportFeedback.saved => l10n.reportDetailImageSaved,
                      _ExportFeedback.saveFailed =>
                        l10n.reportDetailImageSaveFailed,
                      _ExportFeedback.permissionDenied =>
                        l10n.reportDetailImageSavePermissionDenied,
                      _ExportFeedback.shareFailed =>
                        l10n.reportShareExportFailed,
                    }),
                  ),
                  if (feedback == _ExportFeedback.permissionDenied)
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
                onPressed: _exporting ? null : () => _export(generation, png),
                child: Text(l10n.reportDetailImageSave),
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
