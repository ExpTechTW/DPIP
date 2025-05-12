import 'dart:convert';

import 'package:flutter/services.dart';

extension AssetBundleExtension on AssetBundle {
  Future<Map<String, dynamic>> loadJson(String path) async {
    final json = await loadString(path);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
