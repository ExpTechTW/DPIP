import 'dart:math';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HeroWeather extends StatelessWidget {
  final RealtimeWeather? weather;
  final bool isLoading;

  const HeroWeather({
    super.key,
    this.weather,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: screenHeight * 0.5,
      child: Stack(
        children: [
          Positioned(
            top: statusBarHeight + 80,
            left: 32,
            right: 32,
            child: isLoading
                ? _buildLoadingState(context)
                : weather != null
                ? _buildWeatherContent(context)
                : _buildEmptyState(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContent(BuildContext context) {
    final data = weather!.data;
    final e =
        data.humidity /
        100 *
        6.105 *
        exp(17.27 * data.temperature / (data.temperature + 237.3));
    final feelsLike = data.temperature + 0.33 * e - 0.7 * data.wind.speed - 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${data.temperature.round()}°',
          style: context.texts.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            height: 1,
            letterSpacing: -2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getWeatherIcon(data.weatherCode),
              size: 24,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              data.weather,
              style: context.texts.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w400,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '體感 ${feelsLike.round()}°'.i18n,
          style: context.texts.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '--°',
          style: context.texts.displayLarge?.copyWith(
            fontSize: 72,
            fontWeight: FontWeight.w300,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.cloud_off_rounded,
              size: 24,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              '無天氣資料'.i18n,
              style: context.texts.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code >= 1 && code <= 3) return Symbols.clear_day_rounded;
    if (code >= 4 && code <= 7) return Symbols.partly_cloudy_day_rounded;
    if (code >= 8 && code <= 14) return Symbols.cloud_rounded;
    if (code >= 15 && code <= 22) return Symbols.rainy_rounded;
    if (code >= 23 && code <= 28) return Symbols.rainy_heavy_rounded;
    if (code >= 29 && code <= 35) return Symbols.thunderstorm_rounded;
    if (code >= 36 && code <= 41) return Symbols.weather_snowy_rounded;
    if (code >= 42) return Symbols.foggy_rounded;

    return Symbols.cloud_rounded;
  }
}
