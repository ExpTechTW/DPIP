import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class CustomSheet extends StatefulWidget {
  final List<Widget> children;
  final double? initialSize;

  const CustomSheet({super.key, required this.children, this.initialSize});

  @override
  State<CustomSheet> createState() => _CustomSheetState();
}

class _CustomSheetState extends State<CustomSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.screen.height;
    final defaultInitialSize = (context.bottomSheetConstraints.maxHeight * 0.4) / screenHeight;

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
                color: context.theme.colorScheme.surface,
                surfaceTintColor: context.theme.colorScheme.surfaceTint,
                elevation: 1,
                clipBehavior: Clip.hardEdge,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: ListView(controller: scrollController, shrinkWrap: true, children: widget.children),
              ),
            ),
          );
        },
      ),
    );
  }
}
