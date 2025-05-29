import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/home/_widgets/blurred_button.dart';

class PositionedBackButton extends StatelessWidget {
  const PositionedBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      left: 24,
      child: SafeArea(
        child: BlurredIconButton(icon: const Icon(Symbols.arrow_back_rounded), onPressed: context.pop, elevation: 2),
      ),
    );
  }
}
