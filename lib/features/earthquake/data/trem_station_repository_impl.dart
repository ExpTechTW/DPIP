/// [TremStationRepository] backed by the legacy `/api/v1/trem/station` catalogue.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';

class TremStationRepositoryImpl implements TremStationRepository {
  TremStationRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<Result<Map<String, SeismicStation>>> stations() => guardResult(
    () async {
      final data =
          await _client.get(ApiTier.legacyApi, '/api/v1/trem/station')
              as Map<String, dynamic>;
      final directory = <String, SeismicStation>{};
      for (final entry in data.entries) {
        // `{ id: { net, info: [ {code, lat, lon, time}… ], work } }` — the last
        // info entry is the station's current location.
        final info = (entry.value as Map<String, dynamic>)['info'] as List?;
        if (info == null || info.isEmpty) continue;
        final last = info.last as Map<String, dynamic>;
        final lat = (last['lat'] as num?)?.toDouble();
        final lon = (last['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        directory[entry.key] = SeismicStation(
          id: entry.key,
          latitude: lat,
          longitude: lon,
        );
      }
      return directory;
    },
  );
}
