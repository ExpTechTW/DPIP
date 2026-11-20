import 'dart:ui' show Offset;

import 'package:dpip/core/models/lat_lng.dart';

/// Local D75-compact validation value, pending earthquake-data approval.
const storyD75MaxDiameterMetres = 75000.0;

final class StoryStationMarker {
  const StoryStationMarker({
    required this.sourceId,
    required this.latitude,
    required this.longitude,
    required this.position,
    required this.intensity,
  });

  /// The original report's area and station keys, encoded as a pair.
  final String sourceId;
  final double latitude;
  final double longitude;

  /// Native projection of the geographic coordinates onto the logical canvas.
  final Offset position;

  /// Raw report intensity. The report date determines its display label.
  final int intensity;
}

final class StoryMarkerCluster {
  StoryMarkerCluster._(List<StoryStationMarker> members)
    : members = List.unmodifiable(members);

  final List<StoryStationMarker> members;

  /// An original highest-intensity observation with its geographic coordinates
  /// and projected position. The widget may displace the display position
  /// independently and draw a connector back to this projected anchor.
  StoryStationMarker get anchor => members.first;
  int get maxIntensity => anchor.intensity;
  int get count => members.length;
}

/// Greedily assigns observations to the closest existing anchor within 40
/// logical pixels. Within an intensity, priority goes east to west, then north
/// to south, then by source ID. Each source ID is unique within a report.
///
/// When [maxDiameterMetres] is supplied, the great-circle distance to every
/// existing member must be at most that many metres. Both limits include the
/// boundary. Omit the geographic limit to reproduce the screen-only baseline.
List<StoryMarkerCluster> clusterStoryObservations(
  Iterable<StoryStationMarker> markers, {
  double? maxDiameterMetres,
}) {
  if (maxDiameterMetres != null &&
      (!maxDiameterMetres.isFinite || maxDiameterMetres < 0)) {
    throw ArgumentError.value(maxDiameterMetres, 'maxDiameterMetres');
  }
  const radiusSquared = 40.0 * 40.0;
  final ordered = markers.where((marker) => marker.position.isFinite).toList()
    ..sort((a, b) {
      final intensity = b.intensity.compareTo(a.intensity);
      return intensity != 0 ? intensity : _compareGeography(a, b);
    });

  final groups = <List<StoryStationMarker>>[];
  for (final marker in ordered) {
    final coordinate = LatLng(marker.latitude, marker.longitude);
    List<StoryStationMarker>? nearest;
    var nearestDistanceSquared = double.infinity;
    for (final group in groups) {
      final distanceSquared =
          (marker.position - group.first.position).distanceSquared;
      // Equal distances favor the anchor with the earlier canonical priority.
      // Groups are visited in that order because the sorted input seeds them.
      if (distanceSquared <= radiusSquared &&
          distanceSquared < nearestDistanceSquared &&
          (maxDiameterMetres == null ||
              group.every(
                (member) =>
                    coordinate.distanceTo(
                      LatLng(member.latitude, member.longitude),
                    ) <=
                    maxDiameterMetres,
              ))) {
        nearest = group;
        nearestDistanceSquared = distanceSquared;
      }
    }
    if (nearest == null) {
      groups.add([marker]);
    } else {
      nearest.add(marker);
    }
  }

  // Weaker groups draw first. Equal-strength groups use the same geographic
  // priority for both displacement and painting.
  return groups.map(StoryMarkerCluster._).toList()..sort((a, b) {
    final intensity = a.maxIntensity.compareTo(b.maxIntensity);
    return intensity != 0 ? intensity : _compareGeography(a.anchor, b.anchor);
  });
}

int _compareGeography(StoryStationMarker a, StoryStationMarker b) {
  final longitude = b.longitude.compareTo(a.longitude);
  if (longitude != 0) return longitude;
  final latitude = b.latitude.compareTo(a.latitude);
  if (latitude != 0) return latitude;
  return a.sourceId.compareTo(b.sourceId);
}
