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
  return 2 * (log(pga) / log(10)) + 0.7;
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

String int_to_str_en(level) {
  return (level == 5)
      ? "5⁻"
      : (level == 6)
          ? "5⁺"
          : (level == 7)
              ? "6⁻"
              : (level == 8)
                  ? "6⁺"
                  : (level == 9)
                      ? "7"
                      : level.toString();
}

String int_to_str_zh(level) {
  return (level == 5)
      ? "5弱"
      : (level == 6)
          ? "5強"
          : (level == 7)
              ? "6弱"
              : (level == 8)
                  ? "6強"
                  : (level == 9)
                      ? "7級"
                      : "$level級";
}

Map<String, double> speed(double depth, double distance) {
  final double Za = 1 * depth;
  double G0, G;
  final double Xb = distance;
  if (depth <= 40) {
    G0 = 5.10298;
    G = 0.06659;
  } else {
    G0 = 7.804799;
    G = 0.004573;
  }
  final double Zc = -1 * (G0 / G);
  final double Xc = (pow(Xb, 2) - 2 * (G0 / G) * Za - pow(Za, 2)) / (2 * Xb);
  double Theta_A = atan((Za - Zc) / Xc);
  if (Theta_A < 0) {
    Theta_A = Theta_A + pi;
  }
  Theta_A = pi - Theta_A;
  final double Theta_B = atan(-1 * Zc / (Xb - Xc));
  double Ptime = (1 / G) * log(tan((Theta_A / 2)) / tan((Theta_B / 2)));
  final double G0_ = G0 / sqrt(3);
  final double G_ = G / sqrt(3);
  final double Zc_ = -1 * (G0_ / G_);
  final double Xc_ = (pow(Xb, 2) - 2 * (G0_ / G_) * Za - pow(Za, 2)) / (2 * Xb);
  double Theta_A_ = atan((Za - Zc_) / Xc_);
  if (Theta_A_ < 0) {
    Theta_A_ = Theta_A_ + pi;
  }
  Theta_A_ = pi - Theta_A_;
  final double Theta_B_ = atan(-1 * Zc_ / (Xb - Xc_));
  double Stime = (1 / G_) * log(tan(Theta_A_ / 2) / tan(Theta_B_ / 2));
  if (distance / Ptime > 7) {
    Ptime = distance / 7;
  }
  if (distance / Stime > 4) {
    Stime = distance / 4;
  }
  return {'Ptime': Ptime, 'Stime': Stime};
}
