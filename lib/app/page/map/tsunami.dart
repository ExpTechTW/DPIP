import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TsunamiMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const sheetInitialSize = 0.2;
    final decorationTween = DecorationTween(
      begin: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: context.colors.surface,
      ),
      end: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: context.colors.surface,
      ),
    ).chain(CurveTween(curve: Curves.linear));
    return Positioned.fill(
      child: DraggableScrollableSheet(
        initialChildSize: sheetInitialSize,
        minChildSize: sheetInitialSize,
        snap: true,
        builder: (context, scrollController) {
          return Container(
            color: context.colors.surface.withOpacity(0.7),
            child: ListView(
              controller: scrollController,
              children: [
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
