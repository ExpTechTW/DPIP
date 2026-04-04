/// A generic draggable bottom sheet used on the map page.
library;

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// A [DraggableScrollableSheet] that fills the screen and constrains its
/// content to the standard bottom-sheet width.
///
/// Pass [initialSize] as a fraction of the screen height to control how far
/// the sheet is open on first render.
class CustomSheet extends StatefulWidget {
  /// The widgets displayed inside the scrollable sheet.
  final List<Widget> children;

  /// The initial fractional height of the sheet relative to the screen.
  ///
  /// Defaults to 40 % of the bottom-sheet max height when `null`.
  final double? initialSize;

  /// Creates a [CustomSheet] with the given [children].
  const CustomSheet({super.key, required this.children, this.initialSize});

  @override
  State<CustomSheet> createState() => _CustomSheetState();
}

class _CustomSheetState extends State<CustomSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.dimension.height;
    final defaultInitialSize =
        (context.bottomSheetConstraints.maxHeight * 0.4) / screenHeight;

    return Positioned.fill(
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: widget.initialSize ?? defaultInitialSize,
        minChildSize: 64 / screenHeight,
        maxChildSize: context.bottomSheetConstraints.maxHeight / screenHeight,
        snap: true,
        snapSizes: const [0.25],
        builder: (context, scrollController) {
          return Center(
            child: ConstrainedBox(
              constraints: context.bottomSheetConstraints,
              child: Material(
                color: context.colors.surface,
                surfaceTintColor: context.colors.surfaceTint,
                elevation: 1,
                clipBehavior: Clip.hardEdge,
                shape: const RoundedRectangleBorder(
                  borderRadius: .vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  children: widget.children,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
