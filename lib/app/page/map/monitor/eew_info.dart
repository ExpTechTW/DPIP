import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/sheet/bottom_sheet_drag_handle.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class EewDraggableSheet extends StatefulWidget {
  final List<Widget> eewUI;

  const EewDraggableSheet({super.key, required this.eewUI});

  @override
  State<EewDraggableSheet> createState() => _EewDraggableSheetState();
}

class _EewDraggableSheetState extends State<EewDraggableSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2125,
      minChildSize: 0.2125,
      snapSizes: const [0.2125, 0.3725, 1],
      snap: true,
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            boxShadow: kElevationToShadow[4],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              const BottomSheetDragHandle(),
              ...widget.eewUI,
            ],
          ),
        );
      },
    );
  }
}
