import 'dart:convert';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/story_observation_clustering.dart';
import 'package:flutter/services.dart';

bool isStoryMapCoordinate(double latitude, double longitude) =>
    latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

/// The map and overlay anchors from one completed native Story capture.
final class StoryMapSnapshot {
  StoryMapSnapshot._(this.png, this.epicenter, this.markers);

  static const canvas = Size(360, 640);
  static const _channel = MethodChannel('com.exptech.dpip/map_snapshot');
  static const _epicenterId = 'epicenter';

  final Uint8List png;
  final Offset epicenter;
  final List<StoryStationMarker> markers;

  static Future<StoryMapSnapshot> capture({
    required EarthquakeReport report,
    required String style,
    required double centerLatitude,
    required double centerLongitude,
    required double zoom,
    double pixelRatio = 2,
  }) async {
    if (!isStoryMapCoordinate(report.latitude, report.longitude)) {
      throw const FormatException('Invalid Story epicenter coordinates');
    }
    final observations = {
      for (final area in report.list.entries)
        for (final station in area.value.town.entries)
          jsonEncode([area.key, station.key]): station.value,
    };
    final total = observations.length;
    observations.removeWhere(
      (_, station) =>
          !isStoryMapCoordinate(station.latitude, station.longitude),
    );
    if (observations.length != total) {
      Log.warning(
        '[StoryMap] invalidObservationCoordinates=${total - observations.length} '
        'validObservations=${observations.length}',
      );
    }
    final points = {
      _epicenterId: (report.latitude, report.longitude),
      for (final observation in observations.entries)
        observation.key: (
          observation.value.latitude,
          observation.value.longitude,
        ),
    };
    final response = await _channel.invokeMapMethod<Object?, Object?>(
      'captureWithProjection',
      {
        'style': style,
        'latitude': centerLatitude,
        'longitude': centerLongitude,
        'zoom': zoom,
        'width': canvas.width,
        'height': canvas.height,
        'pixelRatio': pixelRatio,
        'showLogo': false,
        'points': [
          for (final point in points.entries)
            {
              'id': point.key,
              'latitude': point.value.$1,
              'longitude': point.value.$2,
            },
        ],
      },
    );
    final png = response?['png'];
    final pngWidth = response?['pngWidth'];
    final pngHeight = response?['pngHeight'];
    if (response?['logicalWidth'] != canvas.width ||
        response?['logicalHeight'] != canvas.height ||
        pngWidth is! int ||
        pngHeight is! int ||
        pngWidth != canvas.width * pixelRatio ||
        pngHeight != canvas.height * pixelRatio ||
        png is! Uint8List ||
        !_matchesPngHeader(png, pngWidth, pngHeight)) {
      throw const FormatException('Invalid Story snapshot PNG dimensions');
    }

    final rawPoints = response?['points'];
    if (rawPoints is! Map || rawPoints.length != points.length) {
      throw const FormatException('Missing or inconsistent Story projections');
    }
    final projected = <String, Offset>{};
    for (final id in points.keys) {
      final pair = rawPoints[id];
      if (pair is! List ||
          pair.length != 2 ||
          pair[0] is! num ||
          pair[1] is! num) {
        throw const FormatException(
          'Missing or invalid Story projection point',
        );
      }
      final position = Offset(
        (pair[0] as num).toDouble(),
        (pair[1] as num).toDouble(),
      );
      if (!position.isFinite) {
        throw const FormatException('Non-finite Story projection point');
      }
      projected[id] = position;
    }

    final markers = [
      for (final observation in observations.entries)
        StoryStationMarker(
          sourceId: observation.key,
          latitude: observation.value.latitude,
          longitude: observation.value.longitude,
          position: projected[observation.key]!,
          intensity: observation.value.intensity,
        ),
    ];
    return StoryMapSnapshot._(
      png,
      projected[_epicenterId]!,
      List.unmodifiable(markers),
    );
  }

  static bool _matchesPngHeader(Uint8List png, int width, int height) {
    if (png.length < 24) return false;
    final header = ByteData.sublistView(png);
    return header.getUint32(0) == 0x89504E47 &&
        header.getUint32(4) == 0x0D0A1A0A &&
        header.getUint32(8) == 13 &&
        header.getUint32(12) == 0x49484452 && // IHDR
        header.getUint32(16) == width &&
        header.getUint32(20) == height;
  }
}
