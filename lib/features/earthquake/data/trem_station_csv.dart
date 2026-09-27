/// Parses the `/resource/station` directory — CSV, whatever its
/// `Content-Type` claims.
///
/// ```text
/// loc_code,id,lat,lon,floor,code,net,time,work
/// 1,125313C,23.3188,121.4564,2,962,3,2026-02-16,1
/// ```
///
/// Columns are found by header name, not position, so a column added or moved
/// server-side does not shift every field one place over. `id` is the hex
/// device id the RTS frames are keyed by; `code` is the township.
library;

import 'package:dpip/features/earthquake/domain/seismic_station.dart';

/// Every station row with a usable id and position, keyed by id.
///
/// A row marked out of service (`work` not `1`) is still kept: the directory
/// only places stations, and a station that is off sends no frames, so it is
/// never drawn — dropping it here would only mean a station brought back into
/// service stays invisible until the next time the list is fetched.
///
/// Throws [FormatException] when the header lacks a column the join needs, so
/// a changed format reaches the caller as a decode failure instead of an empty
/// directory that would be saved over a good one.
Map<String, SeismicStation> parseTremStationCsv(String csv) {
  final lines = csv.split('\n');
  final header = [for (final cell in lines.first.split(',')) cell.trim()];
  int column(String name) {
    final index = header.indexOf(name);
    if (index < 0) {
      throw FormatException('station directory has no "$name" column');
    }
    return index;
  }

  final idAt = column('id');
  final latAt = column('lat');
  final lonAt = column('lon');
  final codeAt = header.indexOf('code');
  final directory = <String, SeismicStation>{};
  for (final line in lines.skip(1)) {
    final cells = line.split(',');
    if (cells.length < header.length) continue;
    final id = cells[idAt].trim();
    final lat = double.tryParse(cells[latAt]);
    final lon = double.tryParse(cells[lonAt]);
    if (id.isEmpty || lat == null || lon == null) continue;
    final code = codeAt < 0 ? '' : cells[codeAt].trim();
    directory[id] = SeismicStation(
      id: id,
      latitude: lat,
      longitude: lon,
      townCode: code.isEmpty ? null : code,
    );
  }
  return directory;
}
