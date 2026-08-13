import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled seismic P/S travel-time grid into the domain
/// [SeismicTravelTimeTable].
///
/// The asset (`assets/travel_time.json.gz`, gzip → JSON) is the reference CWA
/// model as a depth × dist grid: `{ "depth": […], "dist": […], "p": [[…]],
/// "sp": [[…]] }`, where `p` is the P-wave time (s) and `sp` the S–P lead
/// time (s) at each cell. Kept out of the pure domain (which only consumes
/// the parsed table) so the domain stays Flutter-free.
class SeismicTravelTimeSource {
  const SeismicTravelTimeSource();

  Future<SeismicTravelTimeTable> load() async {
    final bytes = await rootBundle.load('assets/travel_time.json.gz');
    final json = jsonDecode(
      utf8.decode(gzip.decode(bytes.buffer.asUint8List())),
    ) as Map<String, dynamic>;
    List<double> row(dynamic value) =>
        (value as List).cast<num>().map((v) => v.toDouble()).toList();
    return SeismicTravelTimeTable(
      depth: row(json['depth']),
      dist: row(json['dist']),
      p: (json['p'] as List).map(row).toList(),
      sp: (json['sp'] as List).map(row).toList(),
    );
  }
}
