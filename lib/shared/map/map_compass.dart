/// The map's north indicator, drawn by Flutter so it can never be covered.
///
/// MapLibre's native compass lives *inside* the platform view, so any Flutter
/// overlay (typhoon forecast callouts, sheets, chrome) paints over it. This
/// replacement sits at the top of the scaffold's stack — the topmost map
/// chrome — and counter-rotates its needle against the camera bearing so it
/// keeps pointing north while the map turns.
library;

import 'dart:math' as math;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A circular, frosted north button driven by the camera [bearing].
///
/// Hidden while north-up, matching the native compass, so a north-facing map
/// doesn't float an idle needle. [bearing] is listened to — only the compass
/// rebuilds while the map rotates, not the whole scaffold.
class MapCompass extends StatelessWidget {
  const MapCompass({super.key, required this.bearing, required this.onPressed});

  /// Camera heading in degrees clockwise from north.
  final ValueListenable<double> bearing;

  /// Resets the camera to north-up.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: bearing,
      builder: (context, value, _) {
        // Native compasses hide when the map faces north; match that.
        if (value.abs() < 0.5) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        return Tooltip(
          message: AppLocalizations.of(context).mapResetNorth,
          child: FrostedSurface(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onPressed,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    // A north-up map has bearing 0; turning the camera east by
                    // `bearing` means north now sits `-bearing` clockwise from
                    // the screen top, so the needle rotates by `-bearing`.
                    child: Transform.rotate(
                      angle: -value * math.pi / 180,
                      child: Icon(
                        Icons.navigation,
                        size: 22,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
