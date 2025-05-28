import 'package:flutter/material.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class SheetContainer extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Widget child;
  const SheetContainer({super.key, required this.child, this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Row(
                spacing: 8,
                children: [if (icon != null) Icon(icon, size: 28), Text(title, style: context.textTheme.titleLarge)],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
