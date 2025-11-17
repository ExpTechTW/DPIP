import 'dart:convert';

import 'package:flutter/services.dart';

/// Extension on [AssetBundle] that provides convenient utilities for loading asset files.
///
/// This extension adds helpful methods to simplify loading and parsing asset files, particularly JSON files that are
/// commonly used for configuration data and static content.
extension AssetBundleExtension on AssetBundle {
  /// Loads a JSON file from the asset bundle and parses it as a map.
  ///
  /// The [path] parameter specifies the asset path relative to the `assets` directory in `pubspec.yaml`. The file is
  /// loaded as a string, then parsed using `jsonDecode` and cast to `Map<String, dynamic>`.
  ///
  /// Example:
  /// ```dart
  /// final data = await rootBundle.loadJson('assets/config.json');
  /// final value = data['key'];
  /// ```
  ///
  /// Throws an exception if the file cannot be loaded or if the JSON is invalid.
  Future<Map<String, dynamic>> loadJson(String path) async {
    final json = await loadString(path);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
