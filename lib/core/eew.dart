import 'dart:math';

import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/api/model/wave_time.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/extensions/list.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

({double p, double s, double sT}) calcWaveRadius(double depth, int time, int now) {
  double pDist = 0;
  double sDist = 0;
  double sT = 0;

  final double t = (now - time) / 1000.0;

  final timeTable = Global.timeTable[findClosest(Global.timeTable.keys.map(int.parse).toList(), depth).toString()]!;
  ({double P, double R, double S})? prevTable;

  for (final table in timeTable) {
    if (pDist == 0 && table.P > t) {
      if (prevTable != null) {
        final double tDiff = table.P - prevTable.P;
        final double rDiff = table.R - prevTable.R;
        final double tOffset = t - prevTable.P;
        final double rOffset = (tOffset / tDiff) * rDiff;
        pDist = prevTable.R + rOffset;
      } else {
        pDist = table.R;
      }
    }

    if (sDist == 0 && table.S > t) {
      if (prevTable != null) {
        final double tDiff = table.S - prevTable.S;
        final double rDiff = table.R - prevTable.R;
        final double tOffset = t - prevTable.S;
        final double rOffset = (tOffset / tDiff) * rDiff;
        sDist = prevTable.R + rOffset;
      } else {
        sDist = table.R;
        sT = table.S;
      }
    }

    if (pDist != 0 && sDist != 0) break;
    prevTable = table;
  }

  return (p: pDist, s: sDist, sT: sT);
}

int findClosest(List<int> arr, double target) {
  return arr.reduce((prev, curr) => (curr - target).abs() < (prev - target).abs() ? curr : prev);
}

Map<String, dynamic> eewAreaPga(double lat, double lon, double depth, double mag, Map<String, Location> region) {
  final Map<String, dynamic> json = {};
  double eewMaxI = 0.0;

  region.forEach((String key, Location info) {
    final double distSurface = LatLng(lat, lon).to(LatLng(info.lat, info.lng));
    final double dist = sqrt(pow(distSurface, 2) + pow(depth, 2));
    final double pga = 1.657 * exp(1.533 * mag) * pow(dist, -1.607);
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
  final double long = pow(10, 0.5 * magW - 1.85).toDouble() / 2;
  final double epicenterDistance = epicenterLocation.asLatLng.to(pointLocation.asLatLng);
  final double hypocenterDistance = sqrt(pow(depth, 2) + pow(epicenterDistance, 2)) - long;
  final double x = max(hypocenterDistance, 3);
  final double gpv600 =
      pow(
        10,
        0.58 * magW + 0.0038 * depth - 1.29 - log(x + 0.0028 * pow(10, 0.5 * magW)) / ln10 - 0.002 * x,
      ).toDouble();
  final double pgv400 = gpv600 * 1.31;
  final double pgv = pgv400 * 1.0;
  return 2.68 + 1.72 * log(pgv) / ln10;
}

double sWaveTimeByDistance(double depth, double sDist) {
  double sTime = 0.0;

  final timeTable = Global.timeTable[findClosest(Global.timeTable.keys.map(int.parse).toList(), depth).toString()]!;
  ({double P, double R, double S})? prevTable;

  for (final table in timeTable) {
    if (sTime == 0 && table.R >= sDist) {
      if (prevTable != null) {
        final double rDiff = table.R - prevTable.R;
        final double tDiff = table.S - prevTable.S;
        final double rOffset = sDist - prevTable.R;
        final double tOffset = (rOffset / rDiff) * tDiff;
        sTime = prevTable.S + tOffset;
      } else {
        sTime = table.S;
      }
    }

    if (sTime != 0) break;
    prevTable = table;
  }

  return sTime * 1000;
}

double pWaveTimeByDistance(double depth, double pDist) {
  double pTime = 0.0;

  final timeTable = Global.timeTable[findClosest(Global.timeTable.keys.map(int.parse).toList(), depth).toString()]!;
  ({double P, double R, double S})? prevTable;

  for (final table in timeTable) {
    if (pTime == 0 && table.R >= pDist) {
      if (prevTable != null) {
        final double rDiff = table.R - prevTable.R;
        final double tDiff = table.P - prevTable.P;
        final double rOffset = pDist - prevTable.R;
        final double tOffset = (rOffset / rDiff) * tDiff;
        pTime = prevTable.P + tOffset;
      } else {
        pTime = table.P;
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
      ? '5⁻'
      : (level == 6)
      ? '5⁺'
      : (level == 7)
      ? '6⁻'
      : (level == 8)
      ? '6⁺'
      : (level == 9)
      ? '7'
      : level.toString();
}

WaveTime calculateWaveTime(double depth, double distance) {
  final double za = 1 * depth;
  double g0;
  double G;
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
  double ptime = (1 / G) * log(tan(thetaA / 2) / tan(thetaB / 2));
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

({double dist, double i}) eewLocationInfo(
  double mag,
  double depth,
  double eqLat,
  double eqLng,
  double userLat,
  double userLon,
) {
  final distSurface = LatLng(eqLat, eqLng).to(LatLng(userLat, userLon)) /1000;
  final dist = sqrt(pow(distSurface, 2) + pow(depth, 2));
  final pga = 1.657 * exp(1.533 * mag) * pow(dist, -1.607);
  var intensity = pgaToFloat(pga);
  if (intensity > 4.5) {
    intensity = eewAreaPgv([eqLat, eqLng], [userLat, userLon], depth, mag);
  }
  return (dist: dist, i: intensity);
}
