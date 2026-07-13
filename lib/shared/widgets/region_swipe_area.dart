import 'package:dpip/core/settings/region_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Switches the active area ([RegionStore]) on a horizontal fling anywhere
/// within [child] — so the swipe works across the whole page, including over the
/// home sheet. Vertical gestures (sheet drag, list scroll) are untouched; only a
/// deliberate horizontal fling counts.
class RegionSwipeArea extends StatelessWidget {
  const RegionSwipeArea({super.key, required this.child});

  final Widget child;

  /// Minimum horizontal fling speed (px/s) that counts as an area swipe.
  static const double _velocityThreshold = 200;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < _velocityThreshold) return;
        final areas = context.read<RegionStore>();
        if (velocity < 0) {
          areas.next(); // swipe left → next area
        } else {
          areas.previous(); // swipe right → previous area
        }
      },
      child: child,
    );
  }
}
