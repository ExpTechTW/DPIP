/// Converts an evidenced ExpTech Core v2 detail snapshot into share input v2.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/earthquake_report.dart';

enum ReportIntensityScale { cwa2020, legacy }

/// Evidence for one independently checked Core v2 detail snapshot.
///
/// The caller must establish the dataset, requested ID, magnitude kind and
/// intensity scale from the source contract and its applicability to this
/// snapshot. Check integer fields and key uniqueness on the raw record
/// before decoding: the detail parser can discard that information.
/// [sourceDecimals] holds the original decimal tokens by source JSON
/// Pointer, before the API decoder converts them to binary doubles.
/// [countyCodes] uses verified MOI county codes valid for this snapshot.
/// [stationCodes] uses verified CWA codes looked up by county and station name
/// within this snapshot. The names are lookup keys for the supplied evidence.
final class ExpTechReportEvidence {
  ExpTechReportEvidence({
    required EarthquakeReport snapshot,
    required this.requestedReportId,
    required Map<String, String> sourceDecimals,
    required Map<String, String> countyCodes,
    required Map<(String, String), String> stationCodes,
    this.scale,
    this.magnitudeIsMl = false,
  }) : _snapshot = snapshot.copyWith(
         list: {
           for (final entry in snapshot.list.entries)
             entry.key: entry.value.copyWith(town: Map.of(entry.value.town)),
         },
       ),
       _sourceDecimals = Map.unmodifiable(sourceDecimals),
       _countyCodes = Map.unmodifiable(countyCodes),
       _stationCodes = Map.unmodifiable(stationCodes);

  final EarthquakeReport _snapshot;
  final String requestedReportId;
  final ReportIntensityScale? scale;
  final bool magnitudeIsMl;
  final Map<String, String> _sourceDecimals;
  final Map<String, String> _countyCodes;
  final Map<(String, String), String> _stationCodes;
}

sealed class EarthquakeShareInput {
  const EarthquakeShareInput();
}

final class EarthquakeShareInputV2 extends EarthquakeShareInput {
  EarthquakeShareInputV2._(List<int> bytes)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  /// Complete, deterministic UTF-8 envelope for the v2 renderer.
  final Uint8List bytes;
}

enum EarthquakeShareInputError {
  missingSourceIdentity,
  snapshotMismatch,
  unsupportedIntensityScale,
  unknownMagnitudeType,
  missingAreaIdentity,
  missingStationIdentity,
  duplicateIdentity,
  missingCoordinates,
  missingSourceDecimal,
  conflictingIntensity,
  malformedSource,
  inputLimit,
}

final class UnsupportedEarthquakeShareInput extends EarthquakeShareInput
    implements Exception {
  const UnsupportedEarthquakeShareInput._(this.code, this.path, this.detail);

  final EarthquakeShareInputError code;

  /// JSON Pointer into the source detail record. Empty denotes the root.
  final String path;
  final String detail;
}

final _fullReportId = RegExp(r'^[0-9]{6}-[0-9]{4}-[0-9]{4}-[0-9]{6}$');
final _countyCode = RegExp(r'^[0-9]{5}$');
final _stationCode = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,123}$');
final _decimalToken = RegExp(r'^(-?)(0|[1-9][0-9]*)(?:\.([0-9]+))?$');
final _forbiddenText = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');
const _scaleReference = 'https://exptech.dev/docs/api/earthquake/report/';

/// Validation precedes byte emission. Ordinary detail models without matching
/// source evidence cannot establish the identities required by v2.
EarthquakeShareInput adaptEarthquakeShareInput(
  EarthquakeReport report, {
  ExpTechReportEvidence? evidence,
}) {
  try {
    if (evidence == null ||
        !_matches(_fullReportId, report.id) ||
        report.id != evidence.requestedReportId) {
      _reject(
        EarthquakeShareInputError.missingSourceIdentity,
        '/id',
        'A verified Core v2 detail request and its complete matching ID are required.',
      );
    }
    if (report != evidence._snapshot) {
      _reject(
        EarthquakeShareInputError.snapshotMismatch,
        '',
        'The supplied evidence belongs to a different report snapshot.',
      );
    }
    return _adapt(report, evidence);
  } on UnsupportedEarthquakeShareInput catch (failure) {
    return failure;
  }
}

EarthquakeShareInputV2 _adapt(
  EarthquakeReport report,
  ExpTechReportEvidence evidence,
) {
  if (evidence.scale != ReportIntensityScale.cwa2020) {
    _reject(
      EarthquakeShareInputError.unsupportedIntensityScale,
      '/list',
      'The Core v2 modern intensity encoding must be established for this snapshot.',
    );
  }
  if (!evidence.magnitudeIsMl) {
    _reject(
      EarthquakeShareInputError.unknownMagnitudeType,
      '/mag',
      'Verify that the Core v2 ML magnitude definition applies to this snapshot.',
    );
  }
  if (report.time < -62135625600000 || report.time > 253402271999999) {
    _malformed('/time', 'Expected Unix milliseconds within the v2 time range.');
  }

  final epicenter = _coordinates(
    report.latitude,
    report.longitude,
    '',
    evidence,
  );
  final depth = _fixedPoint(report.depth, '/depth', evidence, 1000, 0, 1000000);
  final magnitude = _fixedPoint(
    report.magnitude,
    '/mag',
    evidence,
    100,
    -200,
    1000,
  );
  final location = _localized(report.location, '/loc');

  if (report.list.length > 256) {
    _reject(EarthquakeShareInputError.inputLimit, '/list', 'Too many areas.');
  }
  final areas = <String, Map<String, Object?>>{};
  final observations = <String, Map<String, Object?>>{};
  final countyNames = report.list.keys.toList()..sort();
  for (final countyName in countyNames) {
    final area = report.list[countyName]!;
    final areaPath = '/list/${_pointerToken(countyName)}';
    final areaName = _localized(countyName, areaPath);
    final countyCode = evidence._countyCodes[countyName];
    if (countyCode == null || !_matches(_countyCode, countyCode)) {
      _reject(
        EarthquakeShareInputError.missingAreaIdentity,
        areaPath,
        'Provide a verified MOI county code applicable to this snapshot.',
      );
    }
    if (areas.containsKey(countyCode)) {
      _reject(
        EarthquakeShareInputError.duplicateIdentity,
        areaPath,
        'Repeated county identity.',
      );
    }
    _validateIntensity(area.intensity, '$areaPath/int');
    areas[countyCode] = {
      'id': countyCode,
      'intensity': area.intensity,
      'name': areaName,
      'region_id': {'id': countyCode, 'namespace': 'tw.moi.county'},
    };

    final stationNames = area.town.keys.toList()..sort();
    for (final stationName in stationNames) {
      final station = area.town[stationName]!;
      final stationPath = '$areaPath/town/${_pointerToken(stationName)}';
      if (observations.length == 2048) {
        _reject(
          EarthquakeShareInputError.inputLimit,
          stationPath,
          'Too many observations.',
        );
      }
      final name = _localized(stationName, stationPath);
      final code = evidence._stationCodes[(countyName, stationName)];
      if (code == null || !_matches(_stationCode, code)) {
        _reject(
          EarthquakeShareInputError.missingStationIdentity,
          stationPath,
          'Provide a verified CWA station code for this observation.',
        );
      }
      // Core detail has one reading per verified station. Reject ambiguous
      // duplicates before using its scoped station identity as the local ID.
      final id = 'cwa:$code';
      if (observations.containsKey(id)) {
        _reject(
          EarthquakeShareInputError.duplicateIdentity,
          stationPath,
          'Repeated station identity.',
        );
      }
      _validateIntensity(station.intensity, '$stationPath/int');
      if (station.intensity > area.intensity) {
        _reject(
          EarthquakeShareInputError.conflictingIntensity,
          '$stationPath/int',
          'The observation exceeds its source area maximum.',
        );
      }
      observations[id] = {
        'area_id': countyCode,
        'id': id,
        'intensity': station.intensity,
        'name': name,
        'position': _coordinates(
          station.latitude,
          station.longitude,
          stationPath,
          evidence,
        ),
        'station_id': {'id': code, 'namespace': 'cwa'},
      };
    }
  }

  final bytes = utf8.encode(
    jsonEncode({
      'locale': 'zh-Hant',
      'report': {
        'areas': _ordered(areas),
        'depth_m': depth,
        'epicenter': epicenter,
        'intensity_scale': 'cwa-2020',
        'location': location,
        'magnitude': {'centi': magnitude, 'kind': 'ml'},
        'observations': _ordered(observations),
        'origin_time_unix_ms': report.time,
        'published_max_intensity': null,
      },
      'schema_version': 2,
      'source': {
        'event_id': null,
        'namespace': 'exptech.eq-report-v2',
        'publication': null,
        'report_id': report.id,
        'revision': null,
        'scale_evidence': {
          'kind': 'dataset_contract',
          'reference': _scaleReference,
        },
      },
    }),
  );
  if (bytes.length > 1024 * 1024) {
    _reject(
      EarthquakeShareInputError.inputLimit,
      '',
      'The v2 envelope exceeds 1 MiB.',
    );
  }
  return EarthquakeShareInputV2._(bytes);
}

List<T> _ordered<T>(Map<String, T> values) => [
  for (final id in values.keys.toList()..sort()) values[id]!,
];

Map<String, Object?> _localized(String value, String path) {
  final bytes = utf8.encode(value);
  if (value.replaceAll(' ', '').isEmpty ||
      _forbiddenText.hasMatch(value) ||
      bytes.length > 512 ||
      utf8.decode(bytes) != value) {
    _malformed(path, 'Expected non-blank v2 text of at most 512 UTF-8 bytes.');
  }
  return {'en-US': null, 'zh-Hant': value};
}

Map<String, int> _coordinates(
  double latitude,
  double longitude,
  String path,
  ExpTechReportEvidence evidence,
) {
  final latPath = '$path/lat';
  final lonPath = '$path/lon';
  final lat = _tryFixedPoint(
    latitude,
    latPath,
    evidence,
    1000000,
    -90000000,
    90000000,
  );
  final lon = _tryFixedPoint(
    longitude,
    lonPath,
    evidence,
    1000000,
    -180000000,
    180000000,
  );
  if (lat == null || lon == null) {
    _reject(
      EarthquakeShareInputError.missingCoordinates,
      lat == null ? latPath : lonPath,
      'The original source coordinate token is required.',
    );
  }
  return {'lat_e6': lat, 'lon_e6': lon};
}

int _fixedPoint(
  double modelValue,
  String path,
  ExpTechReportEvidence evidence,
  int scale,
  int min,
  int max,
) =>
    _tryFixedPoint(modelValue, path, evidence, scale, min, max) ??
    _reject(
      EarthquakeShareInputError.missingSourceDecimal,
      path,
      'The original source decimal token is required.',
    );

int? _tryFixedPoint(
  double modelValue,
  String path,
  ExpTechReportEvidence evidence,
  int scale,
  int min,
  int max,
) {
  if (!modelValue.isFinite) {
    _malformed(path, 'Expected a finite source number.');
  }
  final token = evidence._sourceDecimals[path];
  if (token == null) return null;
  final match = token.length <= 128 ? _decimalToken.matchAsPrefix(token) : null;
  if (match == null ||
      match.end != token.length ||
      double.tryParse(token) != modelValue) {
    _malformed(
      path,
      'Expected a plain decimal token matching the decoded value.',
    );
  }

  // Validate the exact decimal before rounding. Binary double and rounding
  // alone could admit a just-outside coordinate or move a half tie.
  final fraction = match.group(3) ?? '';
  final digits = BigInt.parse('${match.group(2)}$fraction');
  final negative = match.group(1) == '-';
  if (negative && digits == BigInt.zero) {
    _malformed(path, 'Negative zero is unsupported.');
  }
  final denominator = BigInt.from(10).pow(fraction.length);
  final scaled = digits * BigInt.from(scale);
  final signed = negative ? -scaled : scaled;
  if (signed < BigInt.from(min) * denominator ||
      signed > BigInt.from(max) * denominator) {
    _malformed(
      path,
      'The source value is outside the v2 range before rounding.',
    );
  }
  final rounded =
      (scaled * BigInt.two + denominator) ~/ (denominator * BigInt.two);
  return (negative ? -rounded : rounded).toInt();
}

void _validateIntensity(int value, String path) {
  if (value < 0 || value > 9) {
    _malformed(path, 'Expected a Core v2 intensity ordinal from 0 to 9.');
  }
}

String _pointerToken(String value) =>
    value.replaceAll('~', '~0').replaceAll('/', '~1');

bool _matches(RegExp expression, String value) =>
    expression.matchAsPrefix(value)?.end == value.length;

Never _malformed(String path, String detail) =>
    _reject(EarthquakeShareInputError.malformedSource, path, detail);

Never _reject(EarthquakeShareInputError code, String path, String detail) =>
    throw UnsupportedEarthquakeShareInput._(code, path, detail);
