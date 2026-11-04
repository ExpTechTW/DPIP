/// The map surface's immersive view mode — chrome hidden, map edge to edge.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// How long the map chrome and the shell's navigation bar take to clear or
/// return. One choreography for both surfaces: the bar and the chrome have to
/// move together or the mode reads as two separate changes.
const Duration mapImmersiveTransition = AppMotion.medium;

/// The easing both surfaces use for that transition.
const Curve mapImmersiveCurve = Curves.easeOutCubic;

/// Whether a map surface is in immersive mode.
///
/// The map tab's instance is installed app-wide rather than held by the
/// scaffold because two widgets on opposite sides of the tree have to agree:
/// the scaffold hides the map chrome, and `MainShell` slides the bottom
/// navigation away so the map really does fill the screen. A [ValueNotifier] so
/// only those two listeners rebuild when it flips, not the platform-view map
/// underneath them. A full-screen map that owns its own chrome (the earthquake
/// replay) holds a page-scoped instance instead — it has no shell nav bar to
/// move, and must not leave the map tab's mode behind when it pops.
///
/// Deliberately not persisted. Immersive is a way of looking at the map right
/// now, not a preference: a launch that restored it would greet the user with
/// a chrome-less map and no visible way out of it.
class MapImmersiveController extends ValueNotifier<bool> {
  MapImmersiveController() : super(false);

  /// Hides the map chrome and the shell's navigation bar.
  void enter() => value = true;

  /// Brings the controls back.
  void exit() => value = false;
}
