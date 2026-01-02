import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PositionedBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

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
