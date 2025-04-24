import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/widgets/sheet/bottom_sheet_drag_handle.dart";
import "package:flutter/material.dart";

class EewDraggableSheet extends StatelessWidget {
  final List<Widget> child;

  const EewDraggableSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2125,
      minChildSize: 0.2125,
      snapSizes: const [0.2125, 0.3725, 1],
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainer,
            boxShadow: kElevationToShadow[4],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView(controller: scrollController, children: [const BottomSheetDragHandle(), ...child]),
        );
      },
    );
  }
}
