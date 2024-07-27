import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/cupertino.dart';

class EewDraggableSheet extends StatefulWidget {
  final List<Widget> eewUI;

  const EewDraggableSheet({Key? key, required this.eewUI}) : super(key: key);

  @override
  _EewDraggableSheetState createState() => _EewDraggableSheetState();
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
      initialChildSize: 0.2,
      minChildSize: 0.2,
      controller: _controller,
      builder: (context, scrollController) {
        return Container(
          color: context.colors.surface.withOpacity(0.9),
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
              ...widget.eewUI,
            ],
          ),
        );
      },
    );
  }
}
