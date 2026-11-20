import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/system_settings.dart';
import 'package:dpip/core/platform/image_saver.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_camera_fit.dart';
import 'package:dpip/features/earthquake/presentation/story_map_snapshot.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_card.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_story_card.dart';
import 'package:dpip/features/earthquake/presentation/widgets/report_image_save_feedback.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum _SharePhase {
  preparing,
  capturing,
  composing,
  ready,
  exporting,
  layoutUnavailable,
  captureFailed,
  exportFailed,
  closed,
}

typedef _StoryCapture = ({StoryMapSnapshot map, Map<String, Uint8List> icons});

extension on ShareCardFormat {
  Size get canvas => switch (this) {
    ShareCardFormat.post => EarthquakeShareCard.canvas,
    ShareCardFormat.story => StoryMapSnapshot.canvas,
  };

  String get filePrefix => switch (this) {
    ShareCardFormat.post => 'dpip-card',
    ShareCardFormat.story => 'dpip-story',
  };
}

/// Owns one dialog's report, selected format and export state.
class EarthquakeShareDialog extends StatefulWidget {
  const EarthquakeShareDialog({
    super.key,
    required this.report,
    required this.saver,
    required this.isReportCurrent,
    this.useD75Compact = const bool.fromEnvironment('DPIP_STORY_D75_COMPACT'),
  });

  final EarthquakeReport report;
  final ImageSaver saver;
  final bool Function() isReportCurrent;
  final bool useD75Compact;

  @override
  State<EarthquakeShareDialog> createState() => _EarthquakeShareDialogState();
}

class _EarthquakeShareDialogState extends State<EarthquakeShareDialog> {
  // Task 5A's Android 1,200 ms latency run had a complete preview within
  // about 14 s including UI automation. Budget 20 s end-to-end to give HUD
  // layout, asset decoding and 3x rasterization headroom on either platform.
  static const _captureBudget = Duration(seconds: 20);
  static const _exportPixelRatio = 3.0;

  GlobalKey _boundaryKey = GlobalKey();
  ShareCardFormat _format = ShareCardFormat.post;
  _SharePhase _phase = _SharePhase.preparing;
  ModalRoute<dynamic>? _route;
  Object? _compositionInputs;
  int _generation = 0;
  Timer? _deadline;
  StoryCameraLayout? _layout;
  _StoryCapture? _capture;
  ({ShareCardFormat format, Uint8List png})? _artwork;
  // A Post depends only on the report and inherited artwork inputs. Story
  // still takes a fresh Snapshot each time it is selected.
  Uint8List? _completedPost;
  ImageSaveFailureReason? _saveFailure;
  bool _openingSettings = false;
  bool _settingsFailed = false;
  bool _saving = false;

  bool get _isActive =>
      mounted &&
      _phase != _SharePhase.closed &&
      _route?.isActive == true &&
      widget.isReportCurrent();

  bool _isCurrent(int generation) => _isActive && generation == _generation;

  bool get _canSave =>
      _isActive &&
      _route?.isCurrent == true &&
      !_saving &&
      !_openingSettings &&
      _saveFailure != ImageSaveFailureReason.unavailable &&
      _saveFailure != ImageSaveFailureReason.permissionRestricted &&
      _artwork?.format == _format &&
      (_phase == _SharePhase.ready || _phase == _SharePhase.exportFailed);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final textStyle = DefaultTextStyle.of(context);
    final inputs = (
      MediaQuery.boldTextOf(context),
      MediaQuery.devicePixelRatioOf(context),
      Localizations.localeOf(context),
      Directionality.of(context),
      DefaultAssetBundle.of(context),
      textStyle.style,
      textStyle.textHeightBehavior,
      textStyle.maxLines,
      textStyle.overflow,
      textStyle.softWrap,
      textStyle.textWidthBasis,
      Theme.of(context),
    );
    if (_compositionInputs != inputs) {
      _compositionInputs = inputs;
      _completedPost = null;
      if (_isActive) _beginAttempt();
    }
  }

  @override
  void didUpdateWidget(covariant EarthquakeShareDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.report != oldWidget.report) {
      _completedPost = null;
      if (_isActive) _beginAttempt();
    } else if (_format == ShareCardFormat.story &&
        widget.useD75Compact != oldWidget.useD75Compact &&
        _isActive) {
      _beginAttempt();
    }
  }

  @override
  void dispose() {
    _invalidate();
    _phase = _SharePhase.closed;
    super.dispose();
  }

  void _invalidate() {
    _generation++;
    _boundaryKey = GlobalKey();
    _deadline?.cancel();
    _deadline = null;
    _capture = null;
    _artwork = null;
    _saveFailure = null;
    _settingsFailed = false;
  }

  void _selectFormat(Set<ShareCardFormat> selection) {
    final format = selection.single;
    if (_saving || format == _format) return;
    setState(() {
      _format = format;
      _beginAttempt();
    });
  }

  void _beginAttempt() {
    _invalidate();
    _layout = null;
    final generation = _generation;
    final format = _format;
    if (format == ShareCardFormat.post && _completedPost != null) {
      _artwork = (format: format, png: _completedPost!);
      _phase = _SharePhase.ready;
      return;
    }

    _phase = _SharePhase.preparing;
    _deadline = Timer(_captureBudget, () {
      _failCapture(
        generation,
        TimeoutException('Share composition deadline exceeded', _captureBudget),
        StackTrace.current,
      );
    });
    if (format == ShareCardFormat.post) {
      _phase = _SharePhase.composing;
      unawaited(_composePost(generation));
    }
  }

  Future<void> _composePost(int generation) async {
    try {
      await _decode(EarthquakeShareCard.brandImage);
      await _encodeArtwork(generation, ShareCardFormat.post);
    } catch (error, stackTrace) {
      _failCapture(generation, error, stackTrace);
    }
  }

  void _retryCapture(int generation) {
    if (!_isCurrent(generation) || _phase != _SharePhase.captureFailed) return;
    setState(_beginAttempt);
  }

  void _updateLayout(int generation, StoryCameraLayout layout) {
    if (!_isCurrent(generation) || layout == _layout) return;
    // A failed attempt stays failed until Retry or a fresh format selection.
    if (_phase == _SharePhase.captureFailed) return;
    if (layout.anchorRegion.isEmpty) {
      _markLayoutUnavailable(generation);
      return;
    }
    setState(() {
      if (_phase != _SharePhase.preparing) _beginAttempt();
      _layout = layout;
      _phase = _SharePhase.capturing;
    });
    unawaited(_captureAndCompose(_generation, layout));
  }

  void _markLayoutUnavailable(int generation) {
    if (!_isCurrent(generation)) return;
    setState(() {
      _invalidate();
      _phase = _SharePhase.layoutUnavailable;
    });
  }

  void _failCapture(int generation, Object error, StackTrace stackTrace) {
    if (!_isCurrent(generation)) return;
    Log.handle(
      error,
      stackTrace,
      'Earthquake share capture or composition failed',
    );
    setState(() {
      _invalidate();
      _phase = _SharePhase.captureFailed;
    });
  }

  Future<void> _captureAndCompose(
    int generation,
    StoryCameraLayout layout,
  ) async {
    try {
      final report = widget.report;
      final camera = fitStoryCamera(report, layout);
      final map = await StoryMapSnapshot.capture(
        report: report,
        style: exptechVectorStyle(
          MapColors.light,
          basemapTileUrl: basemapOriginTileUrl,
          glyphsUrl: glyphsOriginUrl,
        ),
        centerLatitude: camera.target.latitude,
        centerLongitude: camera.target.longitude,
        zoom: camera.zoom,
      );
      if (!_isCurrent(generation)) return;

      // Allow two logical pixels of native camera rounding in the symbol gap.
      final anchors = layout.anchorRegion.inflate(2);
      final outside = map.markers
          .where((marker) => !anchors.contains(marker.position))
          .length;
      final epicenterOutside = !anchors.contains(map.epicenter);
      if (outside > 0 || epicenterOutside) {
        Log.warning(
          '[StoryFit] FULL constrained zoom=${camera.zoom} '
          'anchorRegion=${layout.anchorRegion} '
          'observationsOutside=$outside epicenterOutside=$epicenterOutside',
        );
      }
      assert(() {
        debugPrint(
          '[StoryFit] FULL zoom=${camera.zoom} center=${camera.target} '
          'mapRegion=${layout.mapRegion} anchorRegion=${layout.anchorRegion} '
          'observations=${map.markers.length}',
        );
        return true;
      }());

      setState(() => _phase = _SharePhase.composing);
      final icons = await IntensityIconRenderer.renderAll();
      if (!_isCurrent(generation)) return;

      await Future.wait([
        _decode(EarthquakeShareStoryCard.brandImage),
        _decode(MemoryImage(map.png)),
        for (final bytes in icons.values) _decode(MemoryImage(bytes)),
      ], eagerError: true);
      if (!_isCurrent(generation)) return;

      setState(() => _capture = (map: map, icons: icons));
      await _encodeArtwork(generation, ShareCardFormat.story);
    } catch (error, stackTrace) {
      _failCapture(generation, error, stackTrace);
    }
  }

  Future<void> _encodeArtwork(int generation, ShareCardFormat format) async {
    if (!_isCurrent(generation)) return;
    // Let the decoded images and text paint at the fixed artwork dimensions.
    // The FittedBox and all dialog controls sit outside this boundary.
    await WidgetsBinding.instance.endOfFrame;
    if (!_isCurrent(generation)) return;

    final canvas = format.canvas;
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary ||
        !boundary.attached ||
        !boundary.hasSize ||
        boundary.size != canvas) {
      throw StateError('Share composition boundary is unavailable');
    }

    final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
    try {
      if (!_isCurrent(generation)) return;
      if (image.width != canvas.width * _exportPixelRatio ||
          image.height != canvas.height * _exportPixelRatio) {
        throw StateError(
          'Unexpected ${format.name} size: ${image.width}x${image.height}',
        );
      }
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (!_isCurrent(generation)) return;
      if (data == null || data.lengthInBytes == 0) {
        throw StateError('Share PNG encoding failed');
      }

      final png = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      _deadline?.cancel();
      _deadline = null;
      setState(() {
        if (format == ShareCardFormat.post) _completedPost = png;
        _artwork = (format: format, png: png);
        _phase = _SharePhase.ready;
      });
      debugPrint(
        '[${format == ShareCardFormat.story ? 'Story' : 'ShareCard'}Export] '
        'size=${image.width}x${image.height} bytes=${data.lengthInBytes}',
      );
    } finally {
      image.dispose();
    }
  }

  Future<void> _decode(ImageProvider image) async {
    final configuration = createLocalImageConfiguration(context);
    Object? failure;
    StackTrace? trace;
    await precacheImage(
      image,
      context,
      onError: (error, stackTrace) {
        failure = error;
        trace = stackTrace;
      },
    );
    if (failure case final error?) {
      // A failed decode may leave a live completer in Flutter's image cache.
      // Retry must resolve a new image stream instead of replaying that error.
      await image.evict(configuration: configuration);
      Error.throwWithStackTrace(error, trace ?? StackTrace.current);
    }
  }

  Future<void> _save(int generation) async {
    if (!_isCurrent(generation) || !_canSave) return;
    final artwork = _artwork!;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() {
      _saving = true;
      _saveFailure = null;
      _settingsFailed = false;
      _phase = _SharePhase.exporting;
    });

    try {
      final result = await widget.saver.saveToGalleryIfCurrent(
        bytes: artwork.png,
        fileName: '${artwork.format.filePrefix}-${widget.report.id}.png',
        isCurrent: () => _isCurrent(generation) && _route?.isCurrent == true,
      );
      if (!mounted || !_isCurrent(generation)) return;

      switch (result) {
        case Ok():
          setState(() => _phase = _SharePhase.ready);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.reportDetailImageSaved)));
        case Err(:final failure):
          Log.warning('Earthquake share gallery save failed: $failure');
          _markExportFailed(failure);
        case null:
          // Eligibility was lost while waiting for permission. The write
          // never started, even if the user has since returned to this route.
          setState(() => _phase = _SharePhase.ready);
      }
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      Log.handle(error, stackTrace, 'Earthquake share gallery save failed');
      _markExportFailed();
    } finally {
      // A layout update can start a new capture while a gallery request is
      // still in flight. It may become ready but cannot start a second write.
      if (mounted && _route?.isActive == true) {
        setState(() => _saving = false);
      }
    }
  }

  void _markExportFailed([Failure? failure]) {
    setState(() {
      _saveFailure = failure == null
          ? ImageSaveFailureReason.failed
          : imageSaveFailureReason(failure);
      _phase = _SharePhase.exportFailed;
    });
  }

  Future<void> _openGallerySettings(int generation) async {
    if (!_isCurrent(generation) ||
        _route?.isCurrent != true ||
        _openingSettings ||
        _saveFailure != ImageSaveFailureReason.permissionSettingsRequired) {
      return;
    }
    setState(() {
      _openingSettings = true;
      _settingsFailed = false;
    });
    final opened = await openAppSettingsPage();
    if (!mounted || _route?.isActive != true) return;
    setState(() {
      _openingSettings = false;
      _settingsFailed = !opened && _isCurrent(generation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final generation = _generation;
    final layoutUnavailable = _phase == _SharePhase.layoutUnavailable;
    final captureFailed = _phase == _SharePhase.captureFailed;
    final error = switch (_phase) {
      _SharePhase.layoutUnavailable => l10n.reportDetailStoryLayoutUnavailable,
      _SharePhase.captureFailed => l10n.commonFetchFailed,
      _SharePhase.exportFailed => _saveFailure?.message(l10n),
      _ => null,
    };
    final save = FilledButton.icon(
      onPressed: _canSave ? () => _save(generation) : null,
      icon: _saving
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_alt),
      label: Text(l10n.reportDetailImageSave),
    );

    return Dialog(
      child: SizedBox(
        height: screenSize.height * 0.72,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep Save in view. A very short viewport can scroll all controls.
            final pinSave = constraints.maxHeight >= 240;
            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      primary: false,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.sm,
                            children: [
                              SegmentedButton<ShareCardFormat>(
                                segments: const [
                                  ButtonSegment(
                                    value: ShareCardFormat.post,
                                    label: Text('4:5'),
                                  ),
                                  ButtonSegment(
                                    value: ShareCardFormat.story,
                                    label: Text('9:16'),
                                  ),
                                ],
                                selected: {_format},
                                onSelectionChanged: _saving
                                    ? null
                                    : _selectFormat,
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: l10n.commonClose,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (error != null)
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _settingsFailed
                                    ? l10n.reportDetailImageSaveSettingsFailed
                                    : error,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_saveFailure ==
                              ImageSaveFailureReason.permissionSettingsRequired)
                            TextButton(
                              onPressed: _openingSettings
                                  ? null
                                  : () => _openGallerySettings(generation),
                              child: Text(l10n.permissionOpenSettings),
                            ),
                          if (!layoutUnavailable && !captureFailed)
                            _buildPreview(viewport.maxHeight, l10n),
                          if (captureFailed)
                            TextButton(
                              onPressed: () => _retryCapture(generation),
                              child: Text(l10n.commonRetry),
                            ),
                          if (!pinSave) save,
                          _ShareReportDetails(report: widget.report),
                        ],
                      ),
                    ),
                  ),
                ),
                if (pinSave)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: save,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreview(double viewportHeight, AppLocalizations l10n) {
    final story = _format == ShareCardFormat.story;
    final generation = _generation;
    final canvas = _format.canvas;
    final capture = _capture;
    final loading = switch (_phase) {
      _SharePhase.preparing ||
      _SharePhase.capturing ||
      _SharePhase.composing => true,
      _ => false,
    };
    return SizedBox(
      // Leave room for controls on a short viewport. The
      // document can scroll when labels need additional lines.
      height: math.min(viewportHeight * 0.7, canvas.height),
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            excluding: loading,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: canvas.width,
                height: canvas.height,
                child: story
                    ? EarthquakeShareStoryCard(
                        key: ValueKey(generation),
                        report: widget.report,
                        mapPng: capture?.map.png,
                        markerIcons: capture?.icons ?? const {},
                        stationMarkers: capture?.map.markers ?? const [],
                        epicenterPosition: capture?.map.epicenter,
                        useD75Compact: widget.useD75Compact,
                        compositionKey: capture == null ? null : _boundaryKey,
                        onMapLayout: (layout) =>
                            _updateLayout(generation, layout),
                        onLayoutUnavailable: () =>
                            _markLayoutUnavailable(generation),
                      )
                    : RepaintBoundary(
                        key: _boundaryKey,
                        child: EarthquakeShareCard(report: widget.report),
                      ),
              ),
            ),
          ),
          if (loading)
            Semantics(
              liveRegion: true,
              child: CircularProgressIndicator(
                semanticsLabel: l10n.commonLoading,
              ),
            ),
        ],
      ),
    );
  }
}

/// Text equivalent for the report information printed on either artwork.
class _ShareReportDetails extends StatelessWidget {
  const _ShareReportDetails({required this.report});

  final EarthquakeReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = DateFormat('yyyy/MM/dd HH:mm:ss')
        .format(AppTime.taipei(report.originTimeUtc));
    final intensity = Intensity.displayForReport(
      report.maxIntensity,
      report.originTimeUtc,
    );
    return ExpansionTile(
      title: Text(l10n.reportDetailInfo),
      tilePadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      expandedAlignment: AlignmentDirectional.centerStart,
      children: [
        Text(
          report.hasNumber
              ? l10n.reportDetailNumbered(report.number!)
              : l10n.reportDetailLocalFelt,
        ),
        Text(report.location),
        Text('${l10n.reportDetailOriginTime} $time'),
        Text(l10n.reportListMagnitude(report.magnitude.toStringAsFixed(1))),
        Text(l10n.reportDetailMaximumIntensity(intensity.label)),
        Text(
          '${l10n.reportDetailDepth} '
          '${l10n.reportFilterDepthKm(report.depth.toStringAsFixed(1))}',
        ),
      ],
    );
  }
}
