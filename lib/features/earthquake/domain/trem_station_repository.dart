/// Access to the seismic (TREM) station directory.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

/// The seismic-station directory (hex id → place), joined to the RTS feed.
///
/// Two calls, because the monitor wants two things from it: something to draw
/// the moment it opens, and the current list shortly after. [saved] is the
/// first — the last directory this device fetched, kept across launches — and
/// [refresh] the second, asked once each time the monitor opens. Stations are
/// added and moved rarely, so a saved copy is almost always already right, and
/// a monitor that could draw nothing until the network answered would draw
/// nothing at all on the connection an earthquake has just degraded.
abstract interface class TremStationRepository {
  /// The directory last fetched on this device, or null when there is none
  /// (never fetched, or the database would not open).
  Future<Map<String, SeismicStation>?> saved();

  /// Asks the server whether the directory changed — a conditional request, so
  /// an unchanged list costs a `304` and no body — keeps a changed one, and
  /// returns the directory now current. An `Err` means the server could not be
  /// asked, and leaves what [saved] returns untouched.
  Future<Result<Map<String, SeismicStation>>> refresh();
}
