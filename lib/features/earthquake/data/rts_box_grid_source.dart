import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled RTS box grid into the domain [RtsBoxGrid].
///
/// The asset (`assets/box.json.gz`, gzip → JSON) is a `FeatureCollection` of
/// `Polygon` features, each carrying an integer `ID` property matched against
/// `Rts.box`'s keys. Kept out of the pure domain (which only consumes the
/// parsed grid) so the domain stays Flutter-free.
class RtsBoxGridSource {
  const RtsBoxGridSource();

  Future<RtsBoxGrid> load() async {
    final bytes = await rootBundle.load('assets/box.json.gz');
    final json = jsonDecode(
      utf8.decode(gzip.decode(bytes.buffer.asUint8List())),
    ) as Map<String, dynamic>;
    final rings = <int, List<List<double>>>{
      for (final feature in json['features'] as List)
        ((feature as Map)['properties'] as Map)['ID'] as int: [
          for (final point
              in ((feature['geometry'] as Map)['coordinates'] as List)[0]
                  as List)
            [(point[0] as num).toDouble(), (point[1] as num).toDouble()],
        ],
    };
    return RtsBoxGrid(rings);
  }
}
