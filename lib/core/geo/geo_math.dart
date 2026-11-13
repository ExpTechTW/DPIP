/// Angular + distance helpers shared by geo code and map layers.
library;

import 'dart:math' as math;

/// Degrees → radians — the conversion used whenever a latitude / longitude /
/// heading is fed to a trig function.
double degToRad(double degrees) => degrees * math.pi / 180.0;

/// Kilometres per degree of latitude — what a cos-weighted degree distance
/// reduces to. Longitude is scaled by `cos(latitude)` before it is added, so a
/// distance computed that way converts with this one number.
const double kKmPerDegree = 111.32;
