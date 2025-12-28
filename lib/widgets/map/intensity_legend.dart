import 'package:dpip/utils/instrumental_intensity_color.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:flutter/material.dart';

enum IntensityLegendMode {
  /// EEW mode: shows intensity 1-9
  eew,

  /// RTS mode: shows instrumental intensity -3 to 7
  rts,
}

class IntensityLegend extends StatelessWidget {
  final IntensityLegendMode mode;

  const IntensityLegend({super.key, this.mode = IntensityLegendMode.eew});

  List<Color> get _colors => mode == IntensityLegendMode.eew
      ? List.generate(9, (i) => IntensityColor.intensity(i + 1))
      : List.generate(11, (i) => InstrumentalIntensityColor.intensity(i - 3));

  List<String> get _labels => mode == IntensityLegendMode.eew
      ? const ['1', '2', '3', '4', '5⁻', '5⁺', '6⁻', '6⁺', '7']
      : const ['-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / 2;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildColorBar(width),
          const SizedBox(height: 2),
          _buildLabels(width),
        ],
      ),
    );
  }

  Widget _buildColorBar(double width) {
    if (mode == IntensityLegendMode.eew) {
      // EEW mode: discrete color blocks
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          width: width,
          child: Row(
            children: _colors.map((color) {
              return Expanded(child: Container(color: color));
            }).toList(),
          ),
        ),
      );
    } else {
      // RTS mode: gradient
      return Container(
        height: 8,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(colors: _colors),
        ),
      );
    }
  }

  Widget _buildLabels(double width) {
    if (mode == IntensityLegendMode.eew) {
      // EEW mode: labels centered under each color block
      return SizedBox(
        width: width,
        child: Row(
          children: _labels.map((label) {
            return Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // RTS mode: labels at edges
      return SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _labels.map((label) {
            return Text(
              label,
              style: const TextStyle(fontSize: 9),
            );
          }).toList(),
        ),
      );
    }
  }
}
