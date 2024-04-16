import 'dart:io';

import 'package:dpip/core/utils.dart';
import 'package:dpip/util/extension.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';

class IntensityCapsule extends StatelessWidget {
  final String townName;
  final int intensity;

  const IntensityCapsule({
    super.key,
    required this.townName,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.intensity(intensity),
        ),
        color: context.colors.intensity(intensity).withOpacity(0.08),
      ),
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: context.colors.intensity(intensity),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                intensityToNumberString(intensity),
                style: TextStyle(
                    color: context.colors.onIntensity(intensity), height: 1, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Text(
              townName,
              style: TextStyle(
                color: Platform.isIOS
                    ? CupertinoColors.label.resolveFrom(context)
                    : context.colors.onSurfaceVariant.harmonizeWith(context.colors.intensity(intensity)),
                height: 1,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
