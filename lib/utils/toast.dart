import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(BuildContext context, ToastWidget toast) {
  final fToast = FToast();
  fToast.init(context);
  fToast.showToast(
      child: toast,
      toastDuration: const Duration(seconds: 3),
      fadeDuration: Durations.short4,
      gravity: ToastGravity.BOTTOM,
      isDismissible: true,
  );
}

class ToastWidget extends StatelessWidget {
  final List<Widget> children;
  const ToastWidget({super.key, required this.children});

  ToastWidget.text(String text, {super.key, Widget? icon})
      : children = [
        if (icon != null) icon,
        if (icon != null) const SizedBox(width: 4),
    Flexible(child: Text(text, textAlign: TextAlign.center)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        color: context.colors.surfaceContainer,
        border: Border.all(color: context.colors.outlineVariant),
        boxShadow: kElevationToShadow[8],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
