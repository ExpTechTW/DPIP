/// A card widget that shows a contextual weather hint message.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// Displays a time- and weather-aware hint message.
///
/// Generates a contextual greeting and temperature comment based on the current
/// hour and the latest weather data. Rebuilds only when the temperature or
/// weather description changes.
class AssistantHint extends StatelessWidget {
  /// Creates an [AssistantHint] widget.
  const AssistantHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, (double, String)?>(
      selector: (_, m) {
        final d = m.weather?.data;
        return d != null ? (d.temperature, d.weather) : null;
      },
      builder: (context, data, _) {
        final text = data != null ? _buildHintText(data.$1, data.$2) : '載入天氣資料中…';

        return Padding(
          padding: const .symmetric(horizontal: 12, vertical: 8),
          child: Card(
            child: Padding(
              padding: const .all(12),
              child: Row(
                spacing: 8,
                crossAxisAlignment: .start,
                children: [
                  Icon(
                    Symbols.auto_awesome_rounded,
                    fill: 1,
                    color: context.colors.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 16, color: context.colors.onSurfaceVariant),
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _buildHintText(double temperature, String weather) {
  final hour = DateTime.now().hour;

  final greeting = switch (hour) {
    < 6 => '夜深了',
    < 12 => '早安',
    < 18 => '午安',
    _ => '晚安',
  };

  final tempComment = switch (temperature) {
    < 10 => '天氣寒冷，注意保暖。',
    < 20 => '氣溫涼爽，適合外出。',
    < 26 => '氣溫舒適，天氣宜人。',
    < 30 => '氣溫偏高，多補充水分。',
    _ => '高溫注意，避免長時間戶外活動。',
  };

  return '$greeting，目前$weather，氣溫 ${temperature.toStringAsFixed(1)}°C。$tempComment';
}
