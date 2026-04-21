/// 首頁上方天氣卡片
library;

import 'dart:math';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/symbols.dart';

class HeroWeather extends StatelessWidget {
  /// The current weather data, or `null` when unavailable.
  final RealtimeWeather? weather;

  /// When `true`, shows a loading placeholder instead of weather data.
  final bool isLoading;

  /// When `true`, renders a shorter banner form.
  final bool compact;

  /// Creates a [HeroWeather] widget.
  const HeroWeather({
    super.key,
    this.weather,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.dimension.height;
    final statusBarHeight = context.padding.top;

    return SizedBox(
      height: compact ? statusBarHeight + 160 : screenHeight * 0.5,
      child: Padding(
        padding: EdgeInsets.only(
          top: statusBarHeight + 80,
          left: 32,
          right: 32,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: isLoading
              ? _buildLoadingState(context)
              : weather != null
              ? _buildWeatherContent(context)
              : _buildEmptyState(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final double tempHeight = compact ? 40 : 72;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: tempHeight,
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
        data.humidity / 100 * 6.105 * exp(17.27 * data.temperature / (data.temperature + 237.3));
    final feelsLike = data.temperature + 0.33 * e - 0.7 * data.wind.speed - 4.0;

    final tempText = Text(
      '${data.temperature.round()}°',
      style: context.texts.displayLarge?.copyWith(
        fontSize: compact ? 40 : 72,
        fontWeight: FontWeight.w300,
        color: Colors.white,
        height: 1,
        letterSpacing: compact ? -1 : -2,
        shadows: _textShadows(),
      ),
    );

    final conditionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getWeatherIcon(data.weatherCode),
          size: compact ? 18 : 24,
          color: Colors.white,
          shadows: _textShadows(small: true),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            data.weather,
            style: (compact ? context.texts.bodyMedium : context.texts.titleMedium)?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              shadows: _textShadows(small: true),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final feelsLikeText = Text(
      '體感 {feelsLike}°'.i18n.args({'feelsLike': feelsLike.round()}),
      style: context.texts.bodyMedium?.copyWith(
        color: Colors.white,
        shadows: _textShadows(small: true),
      ),
    );

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          tempText,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                conditionRow,
                const SizedBox(height: 4),
                feelsLikeText,
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tempText,
        const SizedBox(height: 8),
        conditionRow,
        const SizedBox(height: 4),
        feelsLikeText,
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
            fontSize: compact ? 40 : 72,
            fontWeight: FontWeight.w300,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1,
            letterSpacing: compact ? -1 : -2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.cloud_off_rounded,
              size: compact ? 18 : 24,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              '無天氣資料'.i18n,
              style: (compact ? context.texts.bodyMedium : context.texts.titleMedium)?.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Shadow> _textShadows({bool small = false}) {
    return [
      Shadow(
        color: Colors.black.withValues(alpha: small ? 0.3 : 0.4),
        blurRadius: small ? 4 : 8,
        offset: Offset(0, small ? 1 : 2),
      ),
    ];
  }

  /// Returns the appropriate [IconData] for the given CWA weather [code].
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
