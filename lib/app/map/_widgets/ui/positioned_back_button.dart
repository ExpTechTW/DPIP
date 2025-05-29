import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PositionedBackButton extends StatelessWidget {
  const PositionedBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      left: 24,
      child: SafeArea(
        child: BlurredIconButton(
          icon: const Icon(Symbols.arrow_back_rounded),
          onPressed: context.pop,
          backgroundColor: context.colors.surface.withValues(alpha: 0.75),
          elevation: 2,
        ),
      ),
    );
  }
}
