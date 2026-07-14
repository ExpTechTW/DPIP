import 'dart:typed_data';

import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
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
/// vector tiles load — the backdrop appears quickly) and draws its boundary as a
/// purple outline. The base map is captured first for a fast first paint; the
/// radar overlay is added in a follow-up capture. Re-renders when the selected
/// area changes; falls back to the whole island for the nationwide view.
class HomeMapBackdrop extends StatefulWidget {
  const HomeMapBackdrop({super.key});

  @override
  State<HomeMapBackdrop> createState() => _HomeMapBackdropState();
}

class _HomeMapBackdropState extends State<HomeMapBackdrop> {
  Uint8List? _image;
  RegionStore? _regions;
  int _requestId = 0;
  String? _renderedKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final regions = context.read<RegionStore>();
    if (regions != _regions) {
      _regions?.removeListener(_refresh);
      _regions = regions..addListener(_refresh);
    }
    _refresh();
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

    final key = '${code ?? 'tw'}@${media.size.width}x${media.size.height}';
    if (key == _renderedKey && _image != null) return;
    _renderedKey = key;
    final id = ++_requestId;

    // Focus on the selected township (if any); else the whole island.
    var latitude = taiwanLat;
    var longitude = taiwanLng;
    var zoom = taiwanZoom;
    String? geoJson;
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
        geoJson = boundaries.geometryJsonFor(code);
      }
    }

    // Base first (no radar) — the fast first paint.
    final base = await _capture(
      colors,
      media,
      latitude,
      longitude,
      zoom,
      geoJson,
    );
    if (id != _requestId || !mounted) return;
    if (base != null) setState(() => _image = base);

    // Radar enhancement — re-capture with the latest echo if it resolves.
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
      geoJson,
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
    String? selectedTownGeoJson, {
    String? radarUrl,
  }) {
    final style = exptechVectorStyle(
      sea: colors.surface.toHexRgb(),
      land: colors.surfaceContainer.toHexRgb(),
      countyTown: colors.surfaceContainerHigh.toHexRgb(),
      outline: colors.outline.toHexRgb(),
      radarTileUrl: radarUrl,
      selectedTownGeoJson: selectedTownGeoJson,
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
    _regions?.removeListener(_refresh);
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
