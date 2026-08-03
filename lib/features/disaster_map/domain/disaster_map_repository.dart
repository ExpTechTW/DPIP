/// Repository for disaster-prevention map (DPM) layers — AED today, more later.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';

/// DPM tile URLs + AED detail fetch. Tiles are pulled by MapLibre; detail is
/// app-fetched on tap.
abstract interface class DisasterMapRepository {
  /// XYZ MVT template for [layer] (e.g. `aed`).
  ///
  /// `https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt`
  String tileUrl(String layer);

  /// AED detail by internal tile feature [id] (not `aed_id`).
  Future<Result<AedDetail>> aedDetail(int id);
}
