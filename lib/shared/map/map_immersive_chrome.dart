/// Shared immersive-mode chrome for the app's full-screen map surfaces.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_immersive.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';

/// Fades and nudges a block of map chrome as immersive mode toggles.
///
/// Blocks stay mounted: the map's timeline carries a [GlobalKey] for
/// measurement, and swapping it out and back mid-transition could duplicate
/// that key on a fast double-tap. Hidden therefore means opacity 0 plus no hit
/// testing, semantics or focus — not absence.
class MapImmersiveChrome extends StatelessWidget {
  const MapImmersiveChrome({
    super.key,
    required this.hidden,
    required this.child,
    this.slide = const Offset(0, -0.08),
  });

  /// Whether the chrome is on its way out (or already gone).
  final bool hidden;

  final Widget child;

  /// Where the block drifts as it fades, as a fraction of its own size. The
  /// timeline passes a downward offset; top-edge chrome takes the default lift.
  final Offset slide;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: hidden,
      child: ExcludeSemantics(
        excluding: hidden,
        child: ExcludeFocus(
          excluding: hidden,
          child: AnimatedSlide(
            duration: mapImmersiveTransition,
            curve: mapImmersiveCurve,
            offset: hidden ? slide : Offset.zero,
            child: AnimatedOpacity(
              duration: mapImmersiveTransition,
              curve: mapImmersiveCurve,
              opacity: hidden ? 0 : 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The one control immersive mode leaves on screen: the way back out.
///
/// Callers paint it above the layer's own sheet — a detail sheet dragged to
/// full height must not bury the only control left, because iOS has no system
/// back gesture to fall back on.
class MapImmersiveExitChip extends StatelessWidget {
  const MapImmersiveExitChip({
    super.key,
    required this.immersive,
    required this.onExit,
  });

  final bool immersive;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: mapImmersiveTransition,
      switchInCurve: mapImmersiveCurve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: immersive
          ? MapChipButton(
              key: const ValueKey('map-immersive-exit'),
              icon: Icons.fullscreen_exit,
              tooltip: AppLocalizations.of(context).mapImmersiveExit,
              active: false,
              onTap: onExit,
            )
          : const SizedBox.shrink(key: ValueKey('map-immersive-exit-hidden')),
    );
  }
}
