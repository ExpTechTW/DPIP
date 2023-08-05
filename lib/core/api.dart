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
