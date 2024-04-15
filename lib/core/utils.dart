import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<dynamic> get(String uri) async {
  try {
    var response = await http.get(Uri.parse(uri)).timeout(const Duration(seconds: 2));
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
        .post(Uri.parse(uri), headers: headers, body: jsonBody, encoding: encoding)
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

Map<String, dynamic> eewAreaPga(double lat, double lon, double depth, double mag, Map<String, dynamic> region) {
  Map<String, dynamic> json = {};
  double eewMaxI = 0.0;

  region.forEach((city, towns) {
    towns.forEach((town, info) {
      double distSurface = distance(lat, lon, info['lat'], info['lon']);
      double dist = sqrt(pow(distSurface, 2) + pow(depth, 2));
      double pga = 1.657 * exp(1.533 * mag) * pow(dist, -1.607);
      double i = pgaToFloat(pga);
      if (i >= 4.5) {
        i = eewAreaPgv([lat, lon], [info['lat'], info['lon']], depth, mag);
      }
      if (i > eewMaxI) {
        eewMaxI = i;
      }
      json['$city $town'] = {'dist': dist, 'i': i};
    });
  });

  json['max_i'] = eewMaxI;
  return json;
}

double eewAreaPgv(List<double> epicenterLocation, List<double> pointLocation, double depth, double magW) {
  double long = pow(10, 0.5 * magW - 1.85) / 2;
  double epicenterDistance = distance(epicenterLocation[0], epicenterLocation[1], pointLocation[0], pointLocation[1]);
  double hypocenterDistance = sqrt(pow(depth, 2) + pow(epicenterDistance, 2)) - long;
  double x = max(hypocenterDistance, 3);
  num gpv600 = pow(10, 0.58 * magW + 0.0038 * depth - 1.29 - log(x + 0.0028 * pow(10, 0.5 * magW)) - 0.002 * x);
  double pgv400 = gpv600 * 1.31;
  double pgv = pgv400 * 1.0;
  return 2.68 + 1.72 * log(pgv) / ln10;
}

double distance(double latA, double lngA, double latB, double lngB) {
  latA = latA * pi / 180;
  lngA = lngA * pi / 180;
  latB = latB * pi / 180;
  lngB = lngB * pi / 180;

  double sinLatA = sin(atan(tan(latA)));
  double sinLatB = sin(atan(tan(latB)));
  double cosLatA = cos(atan(tan(latA)));
  double cosLatB = cos(atan(tan(latB)));

  return acos(sinLatA * sinLatB + cosLatA * cosLatB * cos(lngA - lngB)) * 6371.008;
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

String intensityToNumberString(int level) {
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

String intensityToString(level) {
  return (level == 5)
      ? "5 弱"
      : (level == 6)
          ? "5 強"
          : (level == 7)
              ? "6 弱"
              : (level == 8)
                  ? "6 強"
                  : (level == 9)
                      ? "7 級"
                      : "$level 級";
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

String safeBase64Encode(String input) {
  String encoded = base64Encode(utf8.encode(input));
  return encoded.replaceAll('+', '_').replaceAll('/', '-').replaceAll('=', '');
}

String formatToUTC(TimeOfDay time) {
  final now = DateTime.now().toUtc().add(const Duration(hours: 8)); // Current time in UTC+8
  DateTime dateWithTime = DateTime(
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (time.hour * 60 + time.minute > now.hour * 60 + now.minute) {
    dateWithTime = dateWithTime.subtract(const Duration(days: 1));
  }
  final utcDate = dateWithTime.toUtc();
  return '${utcDate.year}${utcDate.month.toString().padLeft(2, '0')}${utcDate.day.toString().padLeft(2, '0')}${utcDate.hour.toString().padLeft(2, '0')}${utcDate.minute.toString().padLeft(2, '0')}';
}

TimeOfDay adjustTime(TimeOfDay time, int offset) {
  int adjustedMinute = (time.minute ~/ 10) * 10 - offset;
  int hour = time.hour;
  if (adjustedMinute < 0) {
    adjustedMinute += 60;
    hour--;
  }
  if (hour < 0) {
    hour += 24;
  }
  return TimeOfDay(hour: hour, minute: adjustedMinute);
}
