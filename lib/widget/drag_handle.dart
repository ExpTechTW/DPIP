import 'dart:io';

import 'package:dpip/util/extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DragHandleDecoration extends StatelessWidget {
  const DragHandleDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          height: 4,
          width: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Platform.isAndroid
                ? CupertinoColors.secondarySystemFill.resolveFrom(context)
                : context.colors.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
