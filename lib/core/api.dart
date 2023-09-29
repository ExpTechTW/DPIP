import 'dart:convert';

import 'package:http/http.dart' as http;

Future<dynamic> get(String uri) async {
  try {
    var response =
        await http.get(Uri.parse(uri)).timeout(const Duration(seconds: 3));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return false;
    }
  } catch (err) {
    return false;
  }
}

String formatNumber(int number) {
  return number.toString().padLeft(2, '0');
}

int compareVersion(String version1, String version2) {
  List<String> versionParts1 = version1.split('.');
  List<String> versionParts2 = version2.split('.');
  for (int i = 0; i < 3; i++) {
    String part1 = versionParts1[i].padLeft(2, '0');
    String part2 = versionParts2[i].padLeft(2, '0');
    int comparison = part1.compareTo(part2);
    if (comparison != 0) return comparison;
  }
  return 0;
}
