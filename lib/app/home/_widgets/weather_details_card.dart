/// 首頁站點觀測卡片
library;

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WeatherDetailsCard extends StatelessWidget {
  final RealtimeWeather? weather;

  const WeatherDetailsCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final w = weather;
    final hasData = w != null;

    final pairs = <_PairData>[
      _PairData(
        icon: Symbols.water_drop_rounded,
        color: Colors.cyan,
        label: '濕度'.i18n,
        value: hasData && w.data.humidity >= 0 ? '${w.data.humidity.round()}%' : null,
      ),
      _PairData(
        icon: Symbols.compress_rounded,
        color: Colors.purple,
        label: '氣壓'.i18n,
        value: hasData && w.data.pressure >= 0 ? '${w.data.pressure.round()} hPa' : null,
      ),
      _PairData(
        icon: Symbols.rainy_rounded,
        color: Colors.blue,
        label: '降雨'.i18n,
        value: hasData && w.data.rain >= 0 ? '${w.data.rain.toStringAsFixed(1)} mm' : null,
      ),
      _PairData(
        icon: Symbols.visibility_rounded,
        color: Colors.amber,
        label: '能見度'.i18n,
        value: hasData && w.data.visibility >= 0 ? '${w.data.visibility.round()} km' : null,
      ),
      _PairData(
        icon: Symbols.wind_power_rounded,
        color: Colors.teal,
        label: '風速'.i18n,
        value: hasData && w.data.wind.speed >= 0
            ? '${w.data.wind.speed.toStringAsFixed(1)} m/s'
            : null,
      ),
      _PairData(
        icon: Symbols.air_rounded,
        color: Colors.orange,
        label: '陣風'.i18n,
        value: hasData && w.data.gust.speed >= 0
            ? '${w.data.gust.speed.toStringAsFixed(1)} m/s'
            : null,
      ),
    ];

    final divider = Divider(
      height: 1,
      thickness: 1,
      color: context.colors.outlineVariant.withValues(alpha: 0.3),
    );

    return ResponsiveContainer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStationHeader(context, w, hasData),
              const SizedBox(height: 8),
              _buildPairRow(pairs[0], pairs[1]),
              divider,
              _buildPairRow(pairs[2], pairs[3]),
              divider,
              _buildPairRow(pairs[4], pairs[5]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationHeader(BuildContext context, RealtimeWeather? w, bool hasData) {
    String timeStr = '--:--';
    if (hasData) {
      final dt = DateTime.fromMillisecondsSinceEpoch(w!.time);
      final hour = dt.hour;
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour < 12 ? '上午'.i18n : '下午'.i18n;
      timeStr =
          '$period ${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    String stationLabel = '--';
    if (hasData) {
      stationLabel = w!.station.name;
      if (w.station.distance >= 0) {
        stationLabel += '・${w.station.distance.toStringAsFixed(1)}km';
      }
    }

    return Row(
      children: [
        Icon(Symbols.pin_drop_rounded, size: 16, color: context.colors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            stationLabel,
            style: context.texts.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          timeStr,
          style: context.texts.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPairRow(_PairData left, _PairData right) {
    return Row(
      children: [
        Expanded(child: _MetricPair(data: left)),
        const SizedBox(width: 12),
        Expanded(child: _MetricPair(data: right)),
      ],
    );
  }
}

class _PairData {
  final IconData icon;
  final Color color;
  final String label;
  final String? value;

  const _PairData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
}

class _MetricPair extends StatelessWidget {
  final _PairData data;

  const _MetricPair({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: data.color),
          const SizedBox(width: 8),
          Text(
            data.label,
            style: context.texts.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            data.value ?? '—',
            style: context.texts.titleMedium?.copyWith(
              color: data.value != null
                  ? context.colors.onSurface
                  : context.colors.onSurfaceVariant.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
