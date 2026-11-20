import 'dart:math' as math;
import 'dart:ui';

/// The rendered boxes relative to the marker's placement point.
///
/// Use the envelope for canvas containment and the individual components for
/// collisions, so the empty corners of the envelope don't displace markers.
final class StoryMarkerFootprint {
  StoryMarkerFootprint({required Size icon, Size? badge})
    : components = List.unmodifiable(_components(icon, badge));

  static List<Rect> _components(Size icon, Size? badge) {
    const gap = 1.0;
    final iconBox = Rect.fromCenter(
      // Center grouped markers as a whole. The geographic placement point
      // stays inside the intensity icon for the Story's small count badge.
      center: badge == null
          ? Offset.zero
          : Offset(0, -(badge.height + gap) / 2),
      width: icon.width,
      height: icon.height,
    );
    return [
      iconBox,
      if (badge != null)
        Offset(iconBox.right + 8 - badge.width, iconBox.bottom + gap) & badge,
    ];
  }

  final List<Rect> components;

  Rect get envelope => components.reduce((a, b) => a.expandToInclude(b));

  List<Rect> at(Offset center) => [
    for (final component in components) component.shift(center),
  ];
}

typedef StoryMarkerAnchor = ({Offset anchor, StoryMarkerFootprint footprint});

final class StoryConnector {
  const StoryConnector(this.from, this.to);

  final Offset from;
  final Offset to;
  static const strokeWidth = 1.5;

  /// Clip the segment's parameter range against both axes of the box.
  bool intersects(Rect bounds) {
    final rect = bounds.inflate(strokeWidth / 2);
    var entry = 0.0;
    var exit = 1.0;
    for (final (start, end, min, max) in [
      (from.dx, to.dx, rect.left, rect.right),
      (from.dy, to.dy, rect.top, rect.bottom),
    ]) {
      final delta = end - start;
      if (delta == 0) {
        if (start < min || start > max) return false;
        continue;
      }
      final a = (min - start) / delta;
      final b = (max - start) / delta;
      entry = math.max(entry, math.min(a, b));
      exit = math.min(exit, math.max(a, b));
      if (entry > exit) return false;
    }
    return true;
  }

  /// Count interior crossings or a shared stretch of collinear line.
  /// Segments that merely touch at an endpoint don't count as crossings.
  bool crosses(StoryConnector other) {
    double cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;
    final direction = to - from;
    final otherDirection = other.to - other.from;
    final between = other.from - from;
    final determinant = cross(direction, otherDirection);
    if (determinant != 0) {
      final t = cross(between, otherDirection) / determinant;
      final u = cross(between, direction) / determinant;
      return t > 0 && t < 1 && u > 0 && u < 1;
    }
    if (cross(between, direction) != 0) return false;
    final useX = direction.dx.abs() >= direction.dy.abs();
    double axis(Offset p) => useX ? p.dx : p.dy;
    final a = axis(from);
    final b = axis(to);
    final c = axis(other.from);
    final d = axis(other.to);
    return math.max(math.min(a, b), math.min(c, d)) <
        math.min(math.max(a, b), math.max(c, d));
  }
}

// The Task 4A fixtures used 48 px offsets and one ~65 px diagonal. Search up
// to the smaller limit in any direction, with 2 px rings to resolve the small
// badge overlaps without a full marker-width jump.
const storyMarkerDisplacementLimit = 48.0;
const _ringStep = 2.0;
const _directionCount = 16;
final _directions = [
  for (var i = 0; i < _directionCount; i++)
    Offset.fromDirection(i * 2 * math.pi / _directionCount),
];

/// Places existing clusters in priority order, highest intensity first.
/// Returns a position for every anchor, even if some collisions are insoluble.
List<Offset> layoutStoryMarkers({
  required List<StoryMarkerAnchor> markers,
  required Rect canvas,
  required Rect? epicenter,
  required Rect hud,
}) {
  final centers = <Offset>[];
  final components = [
    for (final marker in markers) marker.footprint.at(marker.anchor),
  ];
  final exclusions = [?epicenter, hud];
  final connectors = <StoryConnector>[];
  for (final (index, marker) in markers.indexed) {
    final envelope = marker.footprint.envelope;
    final legalCenters = Rect.fromLTRB(
      canvas.left - envelope.left,
      canvas.top - envelope.top,
      canvas.right - envelope.right,
      canvas.bottom - envelope.bottom,
    );
    final anchor = marker.anchor;
    final origin = Offset(
      _fitAxis(anchor.dx, legalCenters.left, legalCenters.right),
      _fitAxis(anchor.dy, legalCenters.top, legalCenters.bottom),
    );
    var best = origin;
    final original = marker.footprint.at(origin);
    final needsSearch =
        origin != anchor ||
        (epicenter != null && original.any(epicenter.overlaps)) ||
        original.any(hud.overlaps) ||
        components
            .take(index)
            .any((other) => _overlapArea(original, other) > 0);
    if (needsSearch) {
      List<num> score(Offset center) {
        final boxes = marker.footprint.at(center);
        final connector = center == anchor
            ? null
            : StoryConnector(anchor, center);
        var higherCollisions = 0;
        var higherArea = 0.0;
        var lowerCollisions = 0;
        var markerIntersections = 0;
        for (final (otherIndex, other) in components.indexed) {
          if (otherIndex == index) continue;
          final area = _overlapArea(boxes, other);
          if (area > 0) {
            if (otherIndex < index) {
              higherCollisions++;
              higherArea += area;
            } else {
              lowerCollisions++;
            }
          }
          if (connector != null && other.any(connector.intersects)) {
            markerIntersections++;
          }
        }
        return [
          if (epicenter != null) _overlapArea(boxes, [epicenter]),
          _overlapArea(boxes, [hud]),
          higherCollisions,
          higherArea,
          lowerCollisions,
          markerIntersections +
              connectors.where((line) => boxes.any(line.intersects)).length,
          if (connector != null) ...[
            exclusions
                .where(
                  (box) => !box.contains(anchor) && connector.intersects(box),
                )
                .length,
            connectors.where(connector.crosses).length,
          ] else ...[
            0,
            0,
          ],
          (center - anchor).distanceSquared,
        ];
      }

      var bestScore = score(origin);
      // Canvas containment can force a larger correction for an off-canvas
      // anchor. Don't add to that distance if it already exceeds the budget.
      final limit = math.max(
        storyMarkerDisplacementLimit,
        (origin - anchor).distance,
      );
      for (
        var radius = _ringStep;
        radius <= storyMarkerDisplacementLimit;
        radius += _ringStep
      ) {
        for (final direction in _directions) {
          final candidate = origin + direction * radius;
          if (candidate.dx < legalCenters.left ||
              candidate.dx > legalCenters.right ||
              candidate.dy < legalCenters.top ||
              candidate.dy > legalCenters.bottom ||
              (candidate - anchor).distanceSquared > limit * limit) {
            continue;
          }
          final candidateScore = score(candidate);
          if (_isBetter(candidateScore, bestScore)) {
            best = candidate;
            bestScore = candidateScore;
          }
        }
      }
    }
    centers.add(best);
    components[index] = marker.footprint.at(best);
    if (best != anchor) connectors.add(StoryConnector(anchor, best));
  }
  return centers;
}

/// Finds the topmost, then leftmost, unobstructed position for the measured
/// legend. Observations and their connectors keep their existing placement.
/// Returns null when the legend cannot fit among the reserved rectangles.
Rect? layoutStoryLegend({
  required Size legend,
  required Rect safeRegion,
  required List<Rect> occupied,
  required Iterable<Offset> observations,
  required List<StoryConnector> connectors,
}) {
  if (legend.width > safeRegion.width || legend.height > safeRegion.height) {
    return null;
  }

  const observationClearance = 4.0;
  const connectorClearance = StoryConnector.strokeWidth / 2 + 0.5;
  final blockers = [
    ...occupied,
    for (final position in observations)
      Rect.fromCircle(center: position, radius: observationClearance),
    for (final line in connectors)
      Rect.fromPoints(line.from, line.to).inflate(connectorClearance),
  ]..removeWhere((box) => !box.overlaps(safeRegion));
  blockers.sort((a, b) => a.left.compareTo(b.left));

  // A new horizontal gap can only open at a blocker's bottom edge. Check
  // those rows and the safe top, instead of searching pixel by pixel.
  final rows = {
    safeRegion.top,
    for (final box in blockers)
      if (box.bottom + legend.height <= safeRegion.bottom) box.bottom,
  }.toList()..sort();
  for (final top in rows) {
    final bottom = top + legend.height;
    var left = safeRegion.left;
    for (final box in blockers) {
      if (box.bottom <= top || box.top >= bottom || box.right <= left) continue;
      if (left + legend.width <= box.left) break;
      left = box.right;
      if (left + legend.width > safeRegion.right) break;
    }
    if (left + legend.width <= safeRegion.right) {
      return Offset(left, top) & legend;
    }
  }
  return null;
}

double _fitAxis(double value, double low, double high) =>
    low <= high ? value.clamp(low, high) : (low + high) / 2;

double _overlapArea(List<Rect> first, List<Rect> second) {
  var area = 0.0;
  for (final a in first) {
    for (final b in second) {
      final intersection = a.intersect(b);
      if (!intersection.isEmpty) {
        area += intersection.width * intersection.height;
      }
    }
  }
  return area;
}

bool _isBetter(List<num> candidate, List<num> best) {
  for (var i = 0; i < candidate.length; i++) {
    final difference = candidate[i] - best[i];
    // Equivalent distances at different angles can differ by roundoff.
    if (difference.abs() > 1e-9) return difference < 0;
  }
  return false;
}
