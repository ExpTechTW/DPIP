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

class ShaderConfig {
  final bool showFog;
  final bool showRain;
  final bool showThunderstorm;
  final double fogIntensity;

  const ShaderConfig({
    this.showFog = false,
    this.showRain = false,
    this.showThunderstorm = false,
    this.fogIntensity = 0.0,
  });
}

class ShaderSelector {
  static bool debugForceThunderstormFog = true;

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

  static ShaderConfig selectShaderConfig(RealtimeWeather? weather) {
    if (debugForceThunderstormFog) {
      return const ShaderConfig(
        showFog: true,
        showRain: false,
        showThunderstorm: true,
        fogIntensity: 0.6,
      );
    }

    if (weather == null) {
      return const ShaderConfig();
    }

    final weatherCode = weather.data.weatherCode;
    final rain = weather.data.rain;
    final visibility = parseVisibility(weather.data.visibility);

    final showThunderstorm = _isThunderstormCode(weatherCode);
    final showRain =
        (_isRainCode(weatherCode) || rain > 0) && !showThunderstorm;
    final showFog = visibility < 5.0 || _isFogCode(weatherCode);
    final fogIntensity = showFog ? calculateFogIntensity(visibility) : 0.0;

    return ShaderConfig(
      showFog: showFog,
      showRain: showRain,
      showThunderstorm: showThunderstorm,
      fogIntensity: fogIntensity,
    );
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
    required ShaderConfig config,
    required String imagePath,
    Widget? child,
  }) {
    if (config.showThunderstorm) {
      if (config.showFog) {
        return Stack(
          children: [
            Positioned.fill(
              child: ThunderstormShaderBackground(
                imagePath: imagePath,
                animated: true,
                lightningIntensity: 1.0,
                rainAmount: 0.5,
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: config.fogIntensity * 0.7,
                child: FogShaderBackground(
                  imagePath: imagePath,
                  animated: true,
                  intensity: 1.0,
                  speed: 1.0,
                ),
              ),
            ),
            Positioned.fill(child: child ?? const SizedBox()),
          ],
        );
      }
      return ThunderstormShaderBackground(
        imagePath: imagePath,
        animated: true,
        lightningIntensity: 1.0,
        rainAmount: 0.3,
        child: child,
      );
    }

    if (config.showRain && config.showFog) {
      final fogIntensity = config.fogIntensity * 0.5;
      return Stack(
        children: [
          Positioned.fill(
            child: ThunderstormShaderBackground(
              imagePath: imagePath,
              animated: true,
              lightningIntensity: 0.0,
              rainAmount: 0.3,
            ),
          ),
          Positioned.fill(
            child: FogShaderBackground(
              imagePath: imagePath,
              animated: true,
              intensity: fogIntensity,
              speed: 1.0,
            ),
          ),
          Positioned.fill(child: child ?? const SizedBox()),
        ],
      );
    }

    if (config.showRain) {
      return ThunderstormShaderBackground(
        imagePath: imagePath,
        animated: true,
        lightningIntensity: 0.0,
        rainAmount: 0.3,
        child: child,
      );
    }

    if (config.showFog) {
      return FogShaderBackground(
        imagePath: imagePath,
        animated: true,
        intensity: config.fogIntensity,
        speed: 1.0,
        child: child,
      );
    }

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
