import 'dart:math' as math;

/// Where the sun is, and when it rises and sets, for a point on the ground.
///
/// The reference engine has no ephemeris — its sky is a ring of authored keyframes.
/// But the ring still has to be *anchored* to the real day, or dawn keyframes
/// land at the wrong hour and drift by hours across the seasons. In Taiwan
/// daylight runs from about 10h35m in December to 13h40m in June, so anchoring
/// to fixed clock times would be visibly wrong twice a year.
///
/// So this computes the real sunrise and sunset, and the keyframe ring is
/// stretched between them (see `keyframePosition` in `sky_keyframe.dart`).

/// [elevation] is radians above the horizon (negative at night); [azimuth] is
/// radians clockwise from true north.
typedef SolarPosition = ({double elevation, double azimuth});

/// Taiwan's approximate geographic centre — the fallback when no device
/// location is available. The sun's position varies by well under a degree
/// across the island, so this is visually exact for the whole country.
const double kTaiwanLatitude = 23.75;
const double kTaiwanLongitude = 121.0;

const double _deg = math.pi / 180.0;

/// Days since the J2000.0 epoch (2000-01-01 12:00 UTC).
double _julianDays(DateTime utc) =>
    utc.millisecondsSinceEpoch / 86400000.0 - 10957.5;

/// The sun's apparent position at [utc], by a low-precision algorithm
/// (accurate to ~0.01°, far beyond what a backdrop needs).
SolarPosition solarPosition(
  DateTime utc, {
  double latitude = kTaiwanLatitude,
  double longitude = kTaiwanLongitude,
}) {
  final n = _julianDays(utc);

  final meanLongitude = (280.460 + 0.9856474 * n) % 360.0;
  final meanAnomaly = ((357.528 + 0.9856003 * n) % 360.0) * _deg;

  // Equation of centre → apparent ecliptic longitude.
  final eclipticLongitude =
      (meanLongitude +
          1.915 * math.sin(meanAnomaly) +
          0.020 * math.sin(2 * meanAnomaly)) *
      _deg;

  final obliquity = (23.439 - 0.0000004 * n) * _deg;

  final rightAscension = math.atan2(
    math.cos(obliquity) * math.sin(eclipticLongitude),
    math.cos(eclipticLongitude),
  );
  final declination = math.asin(
    math.sin(obliquity) * math.sin(eclipticLongitude),
  );

  final gmstHours = (18.697374558 + 24.06570982441908 * n) % 24.0;
  final hourAngle = (gmstHours * 15.0 + longitude) * _deg - rightAscension;

  final lat = latitude * _deg;
  final sinElevation =
      math.sin(lat) * math.sin(declination) +
      math.cos(lat) * math.cos(declination) * math.cos(hourAngle);

  return (
    elevation: math.asin(sinElevation.clamp(-1.0, 1.0)),
    azimuth:
        math.atan2(
          -math.sin(hourAngle),
          math.tan(declination) * math.cos(lat) -
              math.sin(lat) * math.cos(hourAngle),
        ) %
        (2 * math.pi),
  );
}

/// Sunrise and sunset for the calendar day of [utc], in local decimal hours
/// at [utcOffsetHours].
///
/// Solved from the hour angle at which the sun's centre reaches −0.833°
/// (the standard refraction-and-radius allowance), so it matches published
/// almanac times rather than geometric horizon crossing.
({double sunrise, double sunset}) sunTimes(
  DateTime utc, {
  double latitude = kTaiwanLatitude,
  double longitude = kTaiwanLongitude,
  double utcOffsetHours = 8,
}) {
  final n = _julianDays(utc);

  final meanLongitude = (280.460 + 0.9856474 * n) % 360.0;
  final meanAnomaly = ((357.528 + 0.9856003 * n) % 360.0) * _deg;
  final eclipticLongitude =
      (meanLongitude +
          1.915 * math.sin(meanAnomaly) +
          0.020 * math.sin(2 * meanAnomaly)) *
      _deg;
  final obliquity = (23.439 - 0.0000004 * n) * _deg;
  final declination = math.asin(
    math.sin(obliquity) * math.sin(eclipticLongitude),
  );

  final lat = latitude * _deg;
  const altitude = -0.833 * _deg;

  final cosHourAngle =
      (math.sin(altitude) - math.sin(lat) * math.sin(declination)) /
      (math.cos(lat) * math.cos(declination));

  // Polar day or night — no crossing exists.
  if (cosHourAngle <= -1) return (sunrise: 0.0, sunset: 24.0);
  if (cosHourAngle >= 1) return (sunrise: 12.0, sunset: 12.0);

  final hourAngle = math.acos(cosHourAngle) / _deg / 15.0; // hours

  // Equation of time, from the difference between mean and apparent sun.
  final rightAscension = math.atan2(
    math.cos(obliquity) * math.sin(eclipticLongitude),
    math.cos(eclipticLongitude),
  );
  var eot = (meanLongitude * _deg - rightAscension) / _deg / 15.0;
  // Unwrap: the difference must stay within a few minutes of zero.
  eot = (eot + 12.0) % 24.0 - 12.0;

  final solarNoon = 12.0 - longitude / 15.0 + utcOffsetHours - eot;

  return (sunrise: solarNoon - hourAngle, sunset: solarNoon + hourAngle);
}

/// Whether the sun is below the horizon at [localHour] on the day of [utcDay].
///
/// This is what decides between the day and the night form of a weather glyph
/// — a clear 02:00 must show a moon, not a sun. It uses the same
/// refraction-corrected [sunTimes] as the backdrop, so the icon and the sky
/// behind it flip at the same minute instead of a few minutes apart.
///
/// Takes a bare local hour because that is all an hourly forecast carries (its
/// points are `"HH:00"` labels with no date). The day only sets the season, and
/// sunrise moves by about a minute a day, so a chip that actually belongs to
/// tomorrow is still resolved correctly.
bool isNightHour(
  double localHour, {
  required DateTime utcDay,
  double latitude = kTaiwanLatitude,
  double longitude = kTaiwanLongitude,
  double utcOffsetHours = 8,
}) {
  final times = sunTimes(
    utcDay,
    latitude: latitude,
    longitude: longitude,
    utcOffsetHours: utcOffsetHours,
  );
  return localHour < times.sunrise || localHour >= times.sunset;
}

/// Whether the sun is below the horizon at the instant [utc].
bool isNightAt(
  DateTime utc, {
  double latitude = kTaiwanLatitude,
  double longitude = kTaiwanLongitude,
  double utcOffsetHours = 8,
}) {
  final local = utc.add(Duration(minutes: (utcOffsetHours * 60).round()));
  return isNightHour(
    local.hour + local.minute / 60.0 + local.second / 3600.0,
    utcDay: utc,
    latitude: latitude,
    longitude: longitude,
    utcOffsetHours: utcOffsetHours,
  );
}
