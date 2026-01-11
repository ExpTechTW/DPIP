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
      : List.generate(11, (i) => InstrumentalIntensityColor.intensity(7 - i));

  List<String> get _labels => mode == IntensityLegendMode.eew
      ? const ['1', '2', '3', '4', '5⁻', '5⁺', '6⁻', '6⁺', '7']
      : const ['-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildLegendItems(),
    );
  }

  List<Widget> _buildLegendItems() {
    final colors = mode == IntensityLegendMode.eew ? _colors.reversed.toList() : _colors;
    final labels = _labels.reversed.toList();

    if (mode == IntensityLegendMode.eew) {
      return List.generate(colors.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 12,
              width: 8,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(index == 0 ? 4 : 0),
                  bottom: Radius.circular(index == colors.length - 1 ? 4 : 0),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              labels[index],
              style: const TextStyle(fontSize: 10, height: 1),
            ),
          ],
        );
      });
    } else {
      final labelWidgets = labels.map((label) {
        return Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, height: 1),
            textAlign: TextAlign.left,
          ),
        );
      }).toList();

      return [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12.0 * colors.length,
              width: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 12.0 * colors.length,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: labelWidgets,
              ),
            ),
          ],
        ),
      ];
    }
  }
}
