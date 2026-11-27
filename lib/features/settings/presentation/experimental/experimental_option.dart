/// The shape of one entry on the Experimental features page, and the rule that
/// turns the registry into the page's sections.
///
/// The registry itself is `experimental_options.dart`; this file only says
/// what an entry is, so a new option never has to touch it.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// A group on the Experimental features page.
///
/// **Declaration order is page order.** A category with nothing to offer on
/// this device is left out entirely, so adding one here costs nothing until an
/// option lands in it.
enum ExperimentalCategory {
  /// Alert sounds and their volume.
  sound,

  /// Animation and rendering.
  graphics,

  /// Extra tools the app can surface.
  tools;

  /// The section header shown above this category's options.
  String label(AppLocalizations l10n) => switch (this) {
    ExperimentalCategory.sound => l10n.experimentalCategorySound,
    ExperimentalCategory.graphics => l10n.experimentalCategoryGraphics,
    ExperimentalCategory.tools => l10n.experimentalCategoryTools,
  };
}

/// Every [TargetPlatform], for an option nothing ties to one OS.
///
/// Spelled out because a `const` set cannot be built from
/// `TargetPlatform.values`; a test holds it to that list, so a platform
/// Flutter adds later is not silently left without these options.
const Set<TargetPlatform> everyPlatform = {
  TargetPlatform.android,
  TargetPlatform.fuchsia,
  TargetPlatform.iOS,
  TargetPlatform.linux,
  TargetPlatform.macOS,
  TargetPlatform.windows,
};

/// What the page hands each option's tile: the inputs only the router can
/// wire, because one feature may not import another's internals.
class ExperimentalHost {
  const ExperimentalHost({required this.watchWeatherCode});

  /// Watches the live weather code from the caller's context (the home feed).
  final int? Function(BuildContext context) watchWeatherCode;
}

/// Builds one option's tile. A top-level function, so a registry entry stays a
/// `const` one-liner.
typedef ExperimentalTileBuilder = Widget Function(
  BuildContext context,
  ExperimentalHost host,
);

/// One option on the Experimental features page.
class ExperimentalOption {
  const ExperimentalOption({
    required this.category,
    required this.platforms,
    required this.build,
    this.requiresUnlock = false,
  });

  /// The section it is listed under.
  final ExperimentalCategory category;

  /// The platforms it is offered on — [everyPlatform], or the ones its
  /// behaviour exists on.
  final Set<TargetPlatform> platforms;

  /// Whether it stays hidden until the Developer page's version-row unlock
  /// (`ExperimentalSettings.unlocked`).
  final bool requiresUnlock;

  /// Builds its tile.
  final ExperimentalTileBuilder build;

  /// Whether the page lists it on [platform], given the unlock state.
  bool isOffered(TargetPlatform platform, {required bool unlocked}) =>
      platforms.contains(platform) && (unlocked || !requiresUnlock);
}

/// The page's sections, in [ExperimentalCategory] order: each category with
/// the [options] offered on [platform] (an unlock-only one only once
/// [unlocked]), registry order kept within it. A category left with nothing is
/// dropped, so no header ever sits over an empty group.
List<(ExperimentalCategory, List<ExperimentalOption>)> experimentalSections(
  Iterable<ExperimentalOption> options, {
  required TargetPlatform platform,
  required bool unlocked,
}) {
  final sections = <(ExperimentalCategory, List<ExperimentalOption>)>[];
  for (final category in ExperimentalCategory.values) {
    final offered = [
      for (final option in options)
        if (option.category == category &&
            option.isOffered(platform, unlocked: unlocked))
          option,
    ];
    if (offered.isNotEmpty) sections.add((category, offered));
  }
  return sections;
}
