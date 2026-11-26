import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_png_cache.dart';
import 'package:dpip/features/earthquake/presentation/widgets/report_image_save_feedback.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/report_picture/report_picture.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _previewMaxWidth = 364.0;

enum _ShareIssue { language, report, renderer, incompatible, timeout, failed }

enum _ExportFeedback { saved, copied, copyFailed, shareFailed }

enum _ExportAction { save, copy, share }

typedef _SnapshotKey = ({
  String reportId,
  String bodySha256,
  String renderSha256,
});

typedef _RenderKey = ({
  _SnapshotKey snapshot,
  EqShareFormat format,
  EqMapMode mode,
  EqTheme theme,
  Locale locale,
});

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

class _EarthquakeShareDialogState extends State<EarthquakeShareDialog>
    with WidgetsBindingObserver {
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
  ui.Image? _visiblePreview;
  Uint8List? _readyPng;
  _ShareIssue? _issue;
  bool _rendering = false;
  Timer? _previewTimer;
  final _cache = EarthquakeSharePngCache<_RenderKey>();
  final _inFlight = <_RenderKey, Future<Uint8List>>{};
  Future<void> _renderTail = Future.value();
  _SnapshotKey? _snapshot;
  _RenderKey? _requested;
  int _cacheEpoch = 0;
  int _generation = 0;
  bool _exporting = false;
  Object? _feedback;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didHaveMemoryPressure() {
    ++_cacheEpoch;
    _cache.clear();
  }

  void _invalidateSnapshot() {
    _snapshot = null;
    _requested = null;
    _inFlight.clear();
    ++_cacheEpoch;
    _cache.clear();
    _replacePreview(null);
  }

  void _replacePreview(ui.Image? image) {
    _visiblePreview?.dispose();
    _visiblePreview = image;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewTimer?.cancel();
    _invalidateSnapshot();
    super.dispose();
  }

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
      _replacePreview(null);
      _locale = locale;
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant EarthquakeShareDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.report != oldWidget.report) {
      _invalidateSnapshot();
      _start();
    }
  }

  bool _isActive(int generation) =>
      mounted && generation == _generation && _route?.isCurrent == true;

  bool _isCurrent(int generation) =>
      _isActive(generation) && widget.isReportCurrent();

  void _start() {
    final generation = ++_generation;
    _feedback = null;
    _requested = null;
    _issue = null;
    _readyPng = null;
    _rendering = false;
    _previewTimer?.cancel();
    _previewTimer = Timer(widget.renderTimeout, () {
      if (!_isActive(generation)) return;
      setState(() {
        // FFI must finish, but retry must not join the timed-out request.
        _inFlight.remove(_requested);
        _requested = null;
        ++_generation;
        _issue = _ShareIssue.timeout;
        _replacePreview(null);
      });
    });
    unawaited(_preparePreview(generation, _options));
  }

  Future<void> _preparePreview(int generation, _ShareOptions options) async {
    try {
      final png = await _generate(generation, options);
      if (!_isActive(generation)) return;
      if (!widget.isReportCurrent()) throw _ShareIssue.report;
      // The PNG cache stores compressed bytes. Keep the displayed frame
      // until the selected PNG has decoded, including on a cache hit.
      final image = await _decodePreview(
        png,
        options.format,
        targetWidth: math.min(
          options.format.width,
          (1440 * options.format.width / options.format.height).round(),
        ),
      );
      if (!_isCurrent(generation)) {
        image.dispose();
        if (_isActive(generation)) throw _ShareIssue.report;
        return;
      }
      setState(() {
        _replacePreview(image);
        _readyPng = png;
      });
    } catch (error) {
      if (!_isActive(generation)) return;
      setState(() {
        _issue = _issueFor(error);
        _replacePreview(null);
      });
    } finally {
      if (generation == _generation) _previewTimer?.cancel();
    }
  }

  Future<Uint8List> _generate(int generation, _ShareOptions options) async {
    final locale = _locale!;
    if (locale != kHomeLocale) throw _ShareIssue.language;
    final loaded = await widget.loadInput();
    if (!_isCurrent(generation)) throw _ShareIssue.report;
    if (loaded.failureOrNull case final failure?) {
      _invalidateSnapshot();
      throw failure;
    }
    final input = loaded.valueOrNull;
    if (input is! EarthquakeShareInputV2) {
      _invalidateSnapshot();
      throw _ShareIssue.report;
    }
    final verified = input.verifiedSnapshot;
    if (verified == null || verified.reportId != widget.report.id) {
      _invalidateSnapshot();
      throw _ShareIssue.report;
    }

    final snapshot = (
      reportId: verified.reportId,
      bodySha256: verified.bodySha256,
      renderSha256: input.renderSha256,
    );
    if (_snapshot != snapshot) {
      setState(() {
        _invalidateSnapshot();
        _snapshot = snapshot;
      });
    }
    final key = (
      snapshot: snapshot,
      format: options.format,
      mode: options.mode,
      theme: options.theme,
      locale: locale,
    );
    _requested = key;
    final cached = _cache.lookup(key);
    if (cached != null) return cached;
    setState(() => _rendering = true);
    return _inFlight[key] ?? _scheduleRender(key, input.bytes);
  }

  Future<Uint8List> _scheduleRender(_RenderKey key, Uint8List input) {
    late final Future<Uint8List> render;
    bool isPending() =>
        mounted &&
        _route?.isCurrent == true &&
        widget.isReportCurrent() &&
        identical(_inFlight[key], render);

    render = _renderTail
        .then((_) async {
          // Only start queued work for the selection the user landed on.
          if (!isPending() || _requested != key) throw _ShareIssue.report;
          final cacheEpoch = _cacheEpoch;
          final opened = await widget.openRenderer();
          final renderer = opened.valueOrNull ?? (throw opened.failureOrNull!);
          final Uint8List png;
          try {
            if (!isPending() || _requested != key) throw _ShareIssue.report;
            final response = await renderer.renderSharePngV2(
              input,
              mode: key.mode,
              theme: key.theme,
              format: key.format,
            );
            png = (response.valueOrNull ?? (throw response.failureOrNull!))
                .asUnmodifiableView();
            if (!isPending()) throw _ShareIssue.report;
            final validation = await _decodePreview(
              png,
              key.format,
              targetWidth: 256,
            );
            validation.dispose();
          } finally {
            await renderer.dispose();
          }

          // A completed render can be useful on a later selection. Preview
          // publication still depends on the current selection's generation.
          if (isPending() && cacheEpoch == _cacheEpoch) _cache.store(key, png);
          return png;
        })
        .whenComplete(() {
          if (identical(_inFlight[key], render)) _inFlight.remove(key);
        });
    _inFlight[key] = render;
    _renderTail = render.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return render;
  }

  Future<ui.Image> _decodePreview(
    Uint8List png,
    EqShareFormat format, {
    required int targetWidth,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(png);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width != format.width ||
            descriptor.height != format.height) {
          throw const FormatException('Unexpected report PNG dimensions');
        }
        final codec = await descriptor.instantiateCodec(
          targetWidth: targetWidth,
        );
        try {
          return (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
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
    final generation = _generation;
    final current = widget.isReportCurrent();
    final issue = current ? _issue : _ShareIssue.report;
    final png = current ? _readyPng : null;
    final message = switch (issue) {
      _ShareIssue.language => l10n.reportShareUnsupportedLanguage,
      _ShareIssue.report => l10n.reportShareUnsupportedReport,
      _ShareIssue.renderer => l10n.reportShareRendererUnavailable,
      _ShareIssue.incompatible => l10n.reportShareRendererIncompatible,
      _ShareIssue.timeout => l10n.reportShareTimeout,
      _ShareIssue.failed => l10n.reportShareRenderFailed,
      null => null,
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
        width: _previewMaxWidth,
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
                  if (reportPictureStoryQa) EqShareFormat.story9By16: '9:16',
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
            else if (_visiblePreview case final image?)
              _PngPreview(image: image, label: l10n.reportSharePreview)
            else if (_snapshot == null || _rendering)
              Center(
                child: CircularProgressIndicator(
                  semanticsLabel: l10n.commonLoading,
                ),
              ),
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
              if (feedback == ImageSaveFailureReason.permissionSettingsRequired)
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
          child: Text(l10n.commonClose),
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
                        shareOrigin: box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
              child: Text(l10n.reportShareSend),
            ),
          ),
        ],
      ],
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

class _PngPreview extends StatelessWidget {
  const _PngPreview({required this.image, required this.label});

  final ui.Image image;
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .38,
    ),
    child: Semantics(
      image: true,
      label: label,
      child: RawImage(image: image, fit: BoxFit.contain),
    ),
  );
}
