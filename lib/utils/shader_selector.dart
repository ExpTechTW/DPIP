import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/widgets/fog_shader_background.dart';
import 'package:dpip/widgets/thunderstorm_shader_background.dart';
import 'package:flutter/material.dart';

double parseVisibility(dynamic value) {
  if (value == null) return 10.0;

  if (value is num) {
    final numValue = value.toDouble();
    if (numValue < 0) return 10.0;
    return numValue;
  }

  if (value is String) {
    final str = value.trim();

    if (str.isEmpty || str == '無觀測') return 10.0;

    if (str.startsWith('<')) {
      final numStr = str.substring(1).trim();
      final num = double.tryParse(numStr);
      if (num != null) {
        return num * 0.5;
      }
      return 0.5;
    }

    if (str.contains('-')) {
      final parts = str.split('-');
      if (parts.length == 2) {
        final min = double.tryParse(parts[0].trim());
        final max = double.tryParse(parts[1].trim());
        if (min != null && max != null) {
          return (min + max) / 2.0;
        }
        if (min != null) return min;
        if (max != null) return max;
      }
    }

    final num = double.tryParse(str);
    if (num != null) return num;
  }

  return 10.0;
}

enum ShaderType {
  none,
  fog,
  thunderstorm,
}

class ShaderSelector {
  static bool _isThunderstormCode(int code) {
    return code == 103 ||
        code == 104 ||
        (code >= 114 && code <= 119) ||
        code == 203 ||
        code == 204 ||
        (code >= 214 && code <= 219) ||
        code == 303 ||
        code == 304 ||
        (code >= 314 && code <= 319);
  }

  static bool _isRainCode(int code) {
    return code == 106 ||
        code == 111 ||
        code == 206 ||
        code == 211 ||
        code == 306 ||
        code == 311 ||
        code == 107 ||
        code == 112 ||
        code == 207 ||
        code == 212 ||
        code == 307 ||
        code == 312;
  }

  static bool _isFogCode(int code) {
    return code == 105 || code == 205 || code == 305;
  }

  static ShaderType selectShaderType(RealtimeWeather? weather) {
    if (weather == null) return ShaderType.none;

    final weatherCode = weather.data.weatherCode;
    final rain = weather.data.rain;
    final visibility = parseVisibility(weather.data.visibility);

    if (_isThunderstormCode(weatherCode)) {
      return ShaderType.thunderstorm;
    }

    if (_isRainCode(weatherCode) || rain > 0) {
      if (visibility < 5.0) {
        return ShaderType.fog;
      }
    }

    if (visibility < 5.0 || _isFogCode(weatherCode)) {
      return ShaderType.fog;
    }

    return ShaderType.none;
  }

  static double calculateFogIntensity(double visibility) {
    if (visibility < 1.0) {
      return 1.0;
    }
    if (visibility >= 5.0) {
      return 0.0;
    }
    return 1.0 - (visibility - 1.0) / 4.0;
  }

  static Widget buildShaderBackground({
    required ShaderType shaderType,
    required String imagePath,
    required RealtimeWeather? weather,
    Widget? child,
  }) {
    switch (shaderType) {
      case ShaderType.fog:
        final visibility = parseVisibility(weather?.data.visibility);
        final intensity = calculateFogIntensity(visibility);
        return FogShaderBackground(
          imagePath: imagePath,
          animated: true,
          intensity: intensity,
          speed: 1.0,
          child: child,
        );
      case ShaderType.thunderstorm:
        return ThunderstormShaderBackground(
          imagePath: imagePath,
          animated: true,
          lightningIntensity: 1.0,
          rainAmount: 0.3,
          child: child,
        );
      case ShaderType.none:
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
    }
  }
}
