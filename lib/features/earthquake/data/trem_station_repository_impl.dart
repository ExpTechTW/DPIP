/// [TremStationRepository] over `/resource/station`, kept in [TremStationStore].
library;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/storage/trem_station_store.dart';
import 'package:dpip/features/earthquake/data/trem_station_csv.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';

/// Revalidates the directory with the ETag it was last served with and keeps
/// every good copy in the durable store.
///
/// `If-None-Match` is sent by hand rather than left to the HTTP cache, which is
/// told to keep out of this path: the saved copy has to survive a cache purge,
/// and a `304` only proves the saved copy current if the validator was the one
/// saved with it — which only this repository knows.
///
/// Each region's nginx mints its own ETag for the same file, so the first
/// request after a failover downloads the list once more. That is 6 kB, and
/// the price of never trusting one host's validator on another's say-so.
class TremStationRepositoryImpl implements TremStationRepository {
  TremStationRepositoryImpl(this._client, this._store, {required this._now});

  final ApiClient _client;
  final TremStationStore _store;
  final DateTime Function() _now;

  /// The last parsed directory, so repeat reads skip the database.
  Map<String, SeismicStation>? _current;

  @override
  Future<Map<String, SeismicStation>?> saved() async {
    final current = _current;
    if (current != null) return current;
    final stored = await _store.read();
    if (stored == null) return null;
    final Map<String, SeismicStation> parsed;
    try {
      parsed = parseTremStationCsv(stored.csv);
    } on FormatException {
      // Unreadable in its own format now: fetching fresh is the fix, not a
      // crash on the monitor's first frame.
      return null;
    }
    if (parsed.isEmpty) return null;
    return _current = parsed;
  }

  @override
  Future<Result<Map<String, SeismicStation>>> refresh() =>
      guardResult(() async {
        final stored = await _store.read();
        final saved = await this.saved();
        // A validator is only worth sending for a copy that still parses.
        final etag = saved == null ? null : stored?.etag;
        final response = await _client.request(
          ApiTier.coreStatic,
          ApiPaths.tremStations,
          options: Options(
            // `text/plain` would be honest; the server labels the CSV JSON, and
            // Dio must not try to decode it as such.
            responseType: ResponseType.plain,
            headers: {'If-None-Match': ?etag},
          ),
        );
        if (response.statusCode == 304 && saved != null) return saved;
        final csv = response.data as String;
        final parsed = parseTremStationCsv(csv);
        // An empty directory would blank every dot on the monitor — never keep
        // it over one that places stations.
        if (parsed.isEmpty) {
          throw const FormatException('station directory has no stations');
        }
        await _store.write(
          csv: csv,
          etag: response.headers.value('etag'),
          fetchedAt: _now(),
        );
        return _current = parsed;
      });
}
