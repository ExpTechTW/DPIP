import 'dart:typed_data';

import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/radar_repository.dart';
import 'package:dpip/shared/map/map_snapshot.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Static map backdrop for the home page: an off-screen snapshot of the ExpTech
/// vector map plus the latest radar echo.
///
/// A live map can't be used here — it fights the draggable sheet for gestures
/// and platform-view maps can't be captured on-screen — so this renders the map
/// to an image via [MapSnapshot] and paints that. Shows a solid colour until the
/// snapshot is ready.
class HomeMapBackdrop extends StatefulWidget {
  const HomeMapBackdrop({super.key});

  @override
  State<HomeMapBackdrop> createState() => _HomeMapBackdropState();
}

class _HomeMapBackdropState extends State<HomeMapBackdrop> {
  Uint8List? _image;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load();
  }

  Future<void> _load() async {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final radar = context.read<RadarRepository>();

    // Radar is optional; on failure still snapshot the base map without it.
    final frames = (await radar.frames()).valueOrNull;
    final radarUrl = (frames != null && frames.isNotEmpty)
        ? radar.tileUrl(frames.first)
        : null;

    final style = exptechVectorStyle(
      sea: colors.surface.toHexRgb(),
      land: colors.surfaceContainer.toHexRgb(),
      countyTown: colors.surfaceContainerHigh.toHexRgb(),
      outline: colors.outline.toHexRgb(),
      radarTileUrl: radarUrl,
    );
    Uint8List? bytes;
    for (var attempt = 0; attempt < 2 && bytes == null && mounted; attempt++) {
      if (attempt > 0) await Future.delayed(const Duration(seconds: 2));
      bytes = await const MapSnapshot().capture(
        style: style,
        latitude: taiwanLat,
        longitude: taiwanLng,
        zoom: taiwanZoom,
        width: media.size.width,
        height: media.size.height,
        pixelRatio: media.devicePixelRatio,
      );
    }
    if (mounted) setState(() => _image = bytes);
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
