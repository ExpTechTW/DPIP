import 'dart:convert';

import 'package:flutter/services.dart';

class DistCodeUtil {
  static Future<Map<String, int>> readJsonFile() async {
    try {
      final String jsonString = await rootBundle.loadString("assets/dist_code.json");
      final Map<String, dynamic> data = jsonDecode(jsonString);

      return data.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error reading JSON file: $e');
      return {};
    }
  }
}
