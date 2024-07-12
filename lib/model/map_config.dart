import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_config.freezed.dart';
part 'map_config.g.dart';

@freezed
class MapConfig with _$MapConfig {
  const factory MapConfig({
    @Default(0.8) double minScale,
    @Default(20) double maxScale,
    required MapColorScheme colorScheme,
  }) = _MapConfig;

  factory MapConfig.fromJson(Map<String, dynamic> json) => _$MapConfigFromJson(json);
}

String colorToJson(Color color) => '#${color.value.toRadixString(16)}';
Color colorFromJson(String color) => Color(int.parse(color.substring(1), radix: 16));

@freezed
class MapColorScheme with _$MapColorScheme {
  const factory MapColorScheme({
    @JsonKey(fromJson: colorFromJson, toJson: colorToJson) required Color backgroundColor,
    @JsonKey(fromJson: colorFromJson, toJson: colorToJson) required Color worldLandColor,
    @JsonKey(fromJson: colorFromJson, toJson: colorToJson) required Color worldLineColor,
    @JsonKey(fromJson: colorFromJson, toJson: colorToJson) required Color japanLandColor,
    @JsonKey(fromJson: colorFromJson, toJson: colorToJson) required Color japanLineColor,
  }) = _MapColorScheme;

  factory MapColorScheme.fromJson(Map<String, dynamic> json) => _$MapColorSchemeFromJson(json);

  factory MapColorScheme.light({required ColorScheme colorScheme}) => MapColorScheme(
        backgroundColor: colorScheme.surface,
        worldLandColor: colorScheme.surfaceContainerLowest,
        worldLineColor: colorScheme.onSurfaceVariant,
        japanLandColor: colorScheme.surfaceContainerLowest,
        japanLineColor: colorScheme.onSurfaceVariant,
      );

  factory MapColorScheme.dark({required ColorScheme colorScheme}) => MapColorScheme(
        backgroundColor: Color.lerp(
          colorScheme.surfaceContainerLowest,
          Colors.blue.shade900,
          0.1,
        )!,
        worldLandColor: colorScheme.surfaceContainerHighest,
        worldLineColor: colorScheme.onSurfaceVariant,
        japanLandColor: colorScheme.surfaceContainerHighest,
        japanLineColor: colorScheme.onSurface,
      );
}
