import "package:dpip/utils/extensions/build_context.dart";
import "package:dpip/utils/extensions/color_scheme.dart";
import "package:flutter/material.dart";

class ForecastWeatherCard extends StatelessWidget {
  final String time;
  final int maxTemperature;
  final int minTemperature;
  final int rain;
  final IconData icon;

  const ForecastWeatherCard({
    super.key,
    required this.time,
    required this.maxTemperature,
    required this.minTemperature,
    required this.rain,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      surfaceTintColor: context.colors.surfaceTint,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time, style: TextStyle(fontSize: 16, color: context.colors.primary)),
            Row(
              children: [
                Text(
                  "$maxTemperature°",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: context.colors.onSurface),
                ),
                Text(
                  "/$minTemperature°",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
            Text("$rain%", style: TextStyle(fontSize: 16, color: context.theme.extendedColors.blue)),
            const SizedBox(height: 8),
            Icon(icon, fill: 1, size: 36, color: context.colors.onPrimaryContainer.withOpacity(0.75)),
          ],
        ),
      ),
    );
  }
}
