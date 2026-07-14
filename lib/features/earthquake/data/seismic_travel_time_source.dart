import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled seismic P/S travel-time table into the domain
/// [SeismicTravelTimeTable].
///
/// The asset (`assets/travel_time.json.gz`, gzip → JSON) is the CWA travel-time
/// model keyed by focal depth: `{ "<depthKm>": [ {"P":…,"S":…,"R":…}, … ] }`,
/// where each row is the P/S travel time (s) at epicentral radius `R` (km).
/// Kept out of the pure domain (which only consumes the parsed table) so the
/// domain stays Flutter-free.
class SeismicTravelTimeSource {
  const SeismicTravelTimeSource();

  Future<SeismicTravelTimeTable> load() async {
    final bytes = await rootBundle.load('assets/travel_time.json.gz');
    final json =
        jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
            as Map<String, dynamic>;
    final rowsByDepth = <int, List<TravelTimeRow>>{
      for (final entry in json.entries)
        int.parse(entry.key): [
          for (final row in entry.value as List)
            (
              p: ((row as Map)['P'] as num).toDouble(),
              r: (row['R'] as num).toDouble(),
              s: (row['S'] as num).toDouble(),
            ),
        ],
    };
    return SeismicTravelTimeTable(rowsByDepth);
  }
}
