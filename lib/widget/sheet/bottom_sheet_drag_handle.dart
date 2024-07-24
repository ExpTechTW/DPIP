import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/widgets.dart';

class BottomSheetDragHandle extends StatelessWidget {
  const BottomSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}
