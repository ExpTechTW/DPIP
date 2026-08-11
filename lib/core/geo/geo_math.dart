/// Angular + distance helpers shared by geo code and map layers.
library;

import 'dart:math' as math;

/// Degrees → radians — the conversion used whenever a latitude / longitude /
/// heading is fed to a trig function.
double degToRad(double degrees) => degrees * math.pi / 180.0;
