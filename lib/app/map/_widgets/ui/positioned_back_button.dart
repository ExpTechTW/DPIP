/// A back-navigation button positioned in the top-left corner of the map.
library;

import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A blurred icon button fixed at the top-left of the map that triggers
/// [onPressed] when tapped.
class PositionedBackButton extends StatelessWidget {
  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// Creates a [PositionedBackButton] with an optional [onPressed] callback.
  const PositionedBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      left: 24,
      child: SafeArea(
        child: BlurredIconButton(
          icon: const Icon(Symbols.arrow_back_rounded),
          onPressed: onPressed,
          elevation: 2,
        ),
      ),
    );
  }
}
