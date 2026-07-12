import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Renders a MapLibre style to a PNG **off-screen** via the native
/// `MLNMapSnapshotter` (see `ios/Runner/MapSnapshotPlugin.swift`).
///
/// Flutter can't capture an on-screen platform-view map, and a live map on the
/// home page fights the draggable sheet for gestures, so the home backdrop is a
/// static snapshot instead. Returns `null` on failure or unsupported platforms.
class MapSnapshot {
  const MapSnapshot();

  static const MethodChannel _channel = MethodChannel(
    'com.exptech.dpip/map_snapshot',
  );

  /// Renders [style] centred on ([latitude], [longitude]) at [zoom] into a
  /// [width]×[height] (logical px) PNG at [pixelRatio] density. Returns the
  /// encoded bytes.
  Future<Uint8List?> capture({
    required String style,
    required double latitude,
    required double longitude,
    required double zoom,
    required double width,
    required double height,
    double pixelRatio = 1.0,
  }) async {
    try {
      return await _channel.invokeMethod<Uint8List>('capture', {
        'style': style,
        'latitude': latitude,
        'longitude': longitude,
        'zoom': zoom,
        'width': width,
        'height': height,
        'pixelRatio': pixelRatio,
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Map snapshot failed');
      return null;
    }
  }
}
