import 'dart:math';

import 'package:dpip/global.dart';
import 'package:dpip/model/location/location.dart';
import 'package:dpip/model/wave_time.dart';

Map<String, double> psWaveDist(double depth, int time, int now) {
  double pDist = 0;
  double sDist = 0;
  double sT = 0;

  double t = (now - time) / 1000.0;

  var timeTable = Global.timeTable[findClosest(Global.timeTable.keys.map(int.parse).toList(), depth).toString()];
  var prevTable;

  for (var table in timeTable) {
    if (pDist == 0 && table['P'] > t) {
      if (prevTable != null) {
        double tDiff = table['P'].toDouble() - prevTable['P'].toDouble();
        double rDiff = table['R'].toDouble() - prevTable['R'].toDouble();
        double tOffset = t - prevTable['P'].toDouble();
        double rOffset = (tOffset / tDiff) * rDiff;
        pDist = prevTable['R'].toDouble() + rOffset;
      } else {
        pDist = table['R'].toDouble();
      }
    }

    if (sDist == 0 && table['S'] > t) {
      if (prevTable != null) {
        double tDiff = table['S'].toDouble() - prevTable['S'].toDouble();
        double rDiff = table['R'].toDouble() - prevTable['R'].toDouble();
        double tOffset = t - prevTable['S'].toDouble();
        double rOffset = (tOffset / tDiff) * rDiff;
        sDist = prevTable['R'].toDouble() + rOffset;
      } else {
        sDist = table['R'].toDouble();
        sT = table['S'].toDouble();
      }
    }

    if (pDist != 0 && sDist != 0) break;
    prevTable = table;
  }

  return {'p_dist': pDist, 's_dist': sDist, 's_t': sT};
}

int findClosest(List<int> arr, double target) {
  return arr.reduce((prev, curr) => (curr - target).abs() < (prev - target).abs() ? curr : prev);
}

Map<String, dynamic> eewAreaPga(double lat, double lon, double depth, double mag, Map<String, Location> region) {
  Map<String, dynamic> json = {};
  double eewMaxI = 0.0;

  region.forEach((String key, Location info) {
    double distSurface = distance(lat, lon, info.lat, info.lng);
    double dist = sqrt(pow(distSurface, 2) + pow(depth, 2));
    double pga = 1.657 * exp(1.533 * mag) * pow(dist, -1.607);
    double i = pgaToFloat(pga);
    if (i >= 4.5) {
      i = eewAreaPgv([lat, lon], [info.lat, info.lng], depth, mag);
    }
    if (i > eewMaxI) {
      eewMaxI = i;
    }
    json[key] = {'dist': dist, 'i': i};
  });

  json['max_i'] = eewMaxI;
  return json;
}

double eewAreaPgv(List<double> epicenterLocation, List<double> pointLocation, double depth, double magW) {
  double long = pow(10, 0.5 * magW - 1.85).toDouble() / 2;
  double epicenterDistance = distance(epicenterLocation[0], epicenterLocation[1], pointLocation[0], pointLocation[1]);
  double hypocenterDistance = sqrt(pow(depth, 2) + pow(epicenterDistance, 2)) - long;
  double x = max(hypocenterDistance, 3);
  double gpv600 =
      pow(10, 0.58 * magW + 0.0038 * depth - 1.29 - log(x + 0.0028 * pow(10, 0.5 * magW)) / ln10 - 0.002 * x)
          .toDouble();
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

double sWaveTimeByDistance(double depth, double sDist) {
  double sTime = 0.0;

  var timeTable = Global.timeTable[findClosest(Global.timeTable.keys.map(int.parse).toList(), depth).toString()];
  var prevTable;

  for (var table in timeTable) {
    if (sTime == 0 && table['R'].toDouble() >= sDist) {
      if (prevTable != null) {
        double rDiff = table['R'].toDouble() - prevTable['R'].toDouble();
        double tDiff = table['S'].toDouble() - prevTable['S'].toDouble();
        double rOffset = sDist - prevTable['R'].toDouble();
        double tOffset = (rOffset / rDiff) * tDiff;
        sTime = prevTable['S'].toDouble() + tOffset;
      } else {
        sTime = table['S'].toDouble();
      }
    }

    if (sTime != 0) break;
    prevTable = table;
  }

  return sTime * 1000;
}

double pWaveTimeByDistance(double depth, double pDist) {
  double pTime = 0.0;

  var timeTable = Global.timeTable[findClosest(Global.timeTable.keys.map(int.parse).toList(), depth).toString()];
  var prevTable;

  for (var table in timeTable) {
    if (pTime == 0 && table['R'].toDouble() >= pDist) {
      if (prevTable != null) {
        double rDiff = table['R'].toDouble() - prevTable['R'].toDouble();
        double tDiff = table['P'].toDouble() - prevTable['P'].toDouble();
        double rOffset = pDist - prevTable['R'].toDouble();
        double tOffset = (rOffset / rDiff) * tDiff;
        pTime = prevTable['P'].toDouble() + tOffset;
      } else {
        pTime = table['P'].toDouble();
      }
    }

    if (pTime != 0) break;
    prevTable = table;
  }

  return pTime * 1000;
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

WaveTime calculateWaveTime(double depth, double distance) {
  final double za = 1 * depth;
  double g0, G;
  final double xb = distance;
  if (depth <= 40) {
    g0 = 5.10298;
    G = 0.06659;
  } else {
    g0 = 7.804799;
    G = 0.004573;
  }
  final double zc = -1 * (g0 / G);
  final double xc = (pow(xb, 2) - 2 * (g0 / G) * za - pow(za, 2)) / (2 * xb);
  double thetaA = atan((za - zc) / xc);
  if (thetaA < 0) {
    thetaA = thetaA + pi;
  }
  thetaA = pi - thetaA;
  final double thetaB = atan(-1 * zc / (xb - xc));
  double ptime = (1 / G) * log(tan((thetaA / 2)) / tan((thetaB / 2)));
  final double g0_ = g0 / sqrt(3);
  final double g_ = G / sqrt(3);
  final double zc_ = -1 * (g0_ / g_);
  final double xc_ = (pow(xb, 2) - 2 * (g0_ / g_) * za - pow(za, 2)) / (2 * xb);
  double thetaA_ = atan((za - zc_) / xc_);
  if (thetaA_ < 0) {
    thetaA_ = thetaA_ + pi;
  }
  thetaA_ = pi - thetaA_;
  final double thetaB_ = atan(-1 * zc_ / (xb - xc_));
  double stime = (1 / g_) * log(tan(thetaA_ / 2) / tan(thetaB_ / 2));
  if (distance / ptime > 7) {
    ptime = distance / 7;
  }
  if (distance / stime > 4) {
    stime = distance / 4;
  }
  return WaveTime(p: ptime, s: stime);
}

Map<String, dynamic> eewLocationInfo(
    double mag, double depth, double eqLat, double eqLng, double userLat, double userLon) {
  final distSurface = distance(eqLat, eqLng, userLat, userLon);
  final dist = sqrt(pow(distSurface, 2) + pow(depth, 2));
  final pga = 1.657 * exp(1.533 * mag) * pow(dist, -1.607);
  var intensity = pgaToFloat(pga);
  if (intensity > 4.5) {
    intensity = eewAreaPgv([eqLat, eqLng], [userLat, userLon], depth, mag);
  }
  return {
    'dist': dist,
    'i': intensity,
  };
}
