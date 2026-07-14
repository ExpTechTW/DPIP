import 'dart:async';
import 'dart:typed_data';

import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/map_camera.dart';
import 'package:dpip/shared/map/map_snapshot.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Static map backdrop for the home page: an off-screen snapshot of the ExpTech
/// vector map, focused on the selected township (outlined in purple) with the
/// latest radar echo.
///
/// A live map can't be used here — it fights the draggable sheet for gestures
/// and platform-view maps can't be captured on-screen — so this renders the map
/// to an image via [MapSnapshot] and paints that. The snapshot **frames the
/// selected township** (a far smaller area than the whole island, so far fewer
/// vector tiles load — the backdrop appears quickly). The selected township is
/// highlighted purple by filtering the vector `town` layer on its `CODE`
/// (no extra GeoJSON). The base map is painted first for a fast first paint,
/// then re-captured with the radar echo. Re-renders when the selected area
/// changes, and refreshes the radar to the latest frame whenever the home tab
/// is re-opened or the app resumes.
class HomeMapBackdrop extends StatefulWidget {
  const HomeMapBackdrop({super.key});

  @override
  State<HomeMapBackdrop> createState() => _HomeMapBackdropState();
}

class _HomeMapBackdropState extends State<HomeMapBackdrop>
    with WidgetsBindingObserver {
  Uint8List? _image;
  RegionStore? _regions;
  HomeResetSignal? _resetSignal;
  int _requestId = 0;
  String? _renderedKey;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final regions = context.read<RegionStore>();
    if (regions != _regions) {
      _regions?.removeListener(_scheduleRefresh);
      _regions = regions..addListener(_scheduleRefresh);
    }
    final reset = context.read<HomeResetSignal>();
    if (reset != _resetSignal) {
      _resetSignal?.removeListener(_forceRefresh);
      _resetSignal = reset..addListener(_forceRefresh);
    }
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _forceRefresh();
  }

  /// Debounces area switches so a fast swipe through several areas only renders
  /// the one it settles on — each snapshot is an expensive native render.
  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) _refresh();
    });
  }

  /// Re-renders even for the same area — used on return to the home tab / app
  /// resume so the radar echo is refreshed to the latest frame.
  void _forceRefresh() {
    _renderedKey = null;
    _scheduleRefresh();
  }

  /// The selected township code, or null for the nationwide (whole-island) view.
  String? get _selectedCode => switch (_regions?.selected) {
    SavedArea(:final code) => code,
    CurrentArea(:final code) => code,
    _ => null,
  };

  Future<void> _refresh() async {
    if (!mounted) return;
    // Read every context-bound dependency before the first await.
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final boundariesFuture = context.read<Future<TownBoundaries>>();
    final radar = context.read<RadarRepository>();
    final code = _selectedCode;
    final townCode = code == null ? null : int.tryParse(code);

    final key = '${code ?? 'tw'}@${media.size.width}x${media.size.height}';
    if (key == _renderedKey && _image != null) return;
    _renderedKey = key;
    final id = ++_requestId;

    // Focus on the selected township (if any); else the whole island.
    var latitude = taiwanLat;
    var longitude = taiwanLng;
    var zoom = taiwanZoom;
    if (code != null) {
      final boundaries = await boundariesFuture;
      if (id != _requestId || !mounted) return;
      final bounds = boundaries.boundsFor(code);
      if (bounds != null) {
        final camera = fitBoundsCamera(
          bounds,
          width: media.size.width,
          height: media.size.height,
        );
        latitude = camera.latitude;
        longitude = camera.longitude;
        zoom = camera.zoom;
      }
    }

    // Base first (no radar) — the fast first paint.
    final base = await _capture(
      colors,
      media,
      latitude,
      longitude,
      zoom,
      townCode,
    );
    if (id != _requestId || !mounted) return;
    if (base != null) setState(() => _image = base);

    // Radar echo — re-capture with the latest frame (all views). If it fails,
    // the base map already shown stays.
    final frames = (await radar.frames()).valueOrNull;
    if (id != _requestId || !mounted || frames == null || frames.isEmpty) {
      return;
    }
    final withRadar = await _capture(
      colors,
      media,
      latitude,
      longitude,
      zoom,
      townCode,
      radarUrl: radar.tileUrl(frames.first),
    );
    if (id != _requestId || !mounted) return;
    if (withRadar != null) setState(() => _image = withRadar);
  }

  Future<Uint8List?> _capture(
    ColorScheme colors,
    MediaQueryData media,
    double latitude,
    double longitude,
    double zoom,
    int? selectedTownCode, {
    String? radarUrl,
  }) {
    final style = exptechVectorStyle(
      sea: colors.surface.toHexRgb(),
      land: colors.surfaceContainer.toHexRgb(),
      countyTown: colors.surfaceContainerHigh.toHexRgb(),
      outline: colors.outline.toHexRgb(),
      radarTileUrl: radarUrl,
      selectedTownCode: selectedTownCode,
    );
    return const MapSnapshot().capture(
      style: style,
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      width: media.size.width,
      height: media.size.height,
      pixelRatio: media.devicePixelRatio,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _regions?.removeListener(_scheduleRefresh);
    _resetSignal?.removeListener(_forceRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    }
    return Image.memory(image, fit: BoxFit.cover, gaplessPlayback: true);
  }
}
