import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

Future<dynamic> get(String uri) async {
  try {
    var response =
        await http.get(Uri.parse(uri)).timeout(const Duration(seconds: 2));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return false;
    }
  } catch (err) {
    return false;
  }
}

Future<dynamic> post(String uri, Map<String, dynamic> body) async {
  try {
    final headers = {'Content-Type': 'application/json'};
    String jsonBody = json.encode(body);
    final encoding = Encoding.getByName('utf-8');
    var response = await http
        .post(Uri.parse(uri),
            headers: headers, body: jsonBody, encoding: encoding)
        .timeout(const Duration(seconds: 2));
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

Map<String, dynamic> eewIntensity(
    Map<String, dynamic> data, Map<String, dynamic> region) {
  Map<String, dynamic> json = {};
  double eewMaxPga = 0;

  region.forEach((city, cityData) {
    cityData.forEach((town, info) {
      double distSurface = sqrt(pow((data['lat'] - info['lat']) * 111, 2) +
          pow((data['lon'] - info['lon']) * 101, 2));
      double dist = sqrt(pow(distSurface, 2) + pow(data['depth'], 2));
      double pga = 1.657 *
          pow(exp(1), (1.533 * data['mag'])) *
          pow(dist, -1.607) *
          (info['site'] ?? 1);
      if (pga > eewMaxPga) {
        eewMaxPga = pga;
      }
      json['$city $town'] = {
        'dist': dist,
        'pga': pga,
      };
    });
  });

  json['max_pga'] = eewMaxPga;
  return json;
}

double pgaToFloat(double pga) {
  return 2 * log(pga) + 0.7;
}

int pgaToIntensity(double pga) {
  return intensityFloatToInt(pgaToFloat(pga));
}

int intensityFloatToInt(double floatValue) {
  if (floatValue < 0) {
    return 0;
  } else if (floatValue < 4.5) {
    return floatValue.round();
  } else if (floatValue < 5) {
    return 5;
  } else if (floatValue < 5.5) {
    return 6;
  } else if (floatValue < 6) {
    return 7;
  } else if (floatValue < 6.5) {
    return 8;
  } else {
    return 9;
  }
}
