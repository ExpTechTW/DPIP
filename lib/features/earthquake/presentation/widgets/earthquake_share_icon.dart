import 'package:flutter/widgets.dart';

/// The DPIP app icon as it appears in earthquake share artwork.
class EarthquakeShareIcon extends StatelessWidget {
  const EarthquakeShareIcon({
    super.key,
    required this.size,
    this.excludeFromSemantics = false,
    this.errorBuilder,
  });

  static const image = AssetImage('assets/DPIP.png');

  final double size;
  final bool excludeFromSemantics;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: excludeFromSemantics,
        errorBuilder: errorBuilder,
      ),
    );
  }
}
