import 'package:flutter/material.dart';

extension ThemeModeExtension on ThemeMode {
  String get label => switch (this) {
    .light => '淺色',
    .dark => '深色',
    .system => '跟隨系統',
  };
}
