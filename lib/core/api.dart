import 'dart:convert';

import 'package:http/http.dart' as http;

Future<dynamic> get(String uri) async {
  var response = await http.get(Uri.parse(uri));
  try {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return false;
    }
  } catch (err) {
    return false;
  }
}