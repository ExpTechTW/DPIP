/// The tones of a caution that is not an error.
library;

import 'package:material_ui/material_ui.dart';

/// A yellow container and its ink, for a notice that something is off but
/// nothing is wrong — text shown in another language than the reader's, for
/// one.
///
/// Material 3 has no such role: `error` is red and alarming, and `tertiary`
/// follows the app's seed, so it reads as decoration rather than a caution.
/// The pair is derived from one amber seed per brightness the way the scheme
/// derives its own roles ([DynamicSchemeVariant.fidelity] keeps the yellow
/// saturated), so its contrast holds in light and dark like every other role.
abstract final class AppCaution {
  static const Color _seed = Color(0xFFFFC107);

  static final ColorScheme _light = ColorScheme.fromSeed(
    seedColor: _seed,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  static final ColorScheme _dark = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );

  static ColorScheme _of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// The caution's fill.
  static Color container(BuildContext context) => _of(context).primaryContainer;

  /// Text and icons drawn on [container].
  static Color onContainer(BuildContext context) =>
      _of(context).onPrimaryContainer;
}
