import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report_snapshot.dart';

enum EarthquakeShareLocale {
  zhHant('zh-Hant'),
  enUs('en-US');

  const EarthquakeShareLocale(this.tag);
  final String tag;
}

/// Renderer-ready v3 input whose pointers are scoped to one exact Core body.
final class EarthquakeShareInputV3 {
  EarthquakeShareInputV3._({
    required List<int> bytes,
    required this.snapshot,
    required this._identity,
    required this._report,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final Uint8List bytes;
  final CoreEarthquakeReportSnapshot snapshot;
  final Map<String, Object?> _identity;
  final Map<String, Object?> _report;

  // All object keys are fixed ASCII keys emitted in JCS order. Values are
  // Unicode strings, exact integers or null, and report rows are sorted by ID.
  late final Uint8List canonicalContent = utf8
      .encode(
        jsonEncode({
          'report': _report,
          'schema_version': 3,
          'source': _identity,
        }),
      )
      .asUnmodifiableView();

  /// Matches Rust's content_sha256. Locale and render options are separate
  /// cache-key inputs; the source body fingerprint is part of this hash.
  late final String contentSha256 = sha256.convert(canonicalContent).toString();
}

const _modernFromUnixMs = 1577808000000; // 2020-01-01 00:00:00 Asia/Taipei
const _scaleReference = 'https://exptech.dev/docs/api/earthquake/report/#震度表示法';
final _forbiddenText = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

/// Projects the modern Core v2 source profile into renderer input v3.
/// Throws [EarthquakeReportSourceException] with a source pointer on failure.
EarthquakeShareInputV3 adaptEarthquakeShareSnapshotV3(
  CoreEarthquakeReportSnapshot snapshot, {
  EarthquakeShareLocale locale = EarthquakeShareLocale.zhHant,
}) {
  if (snapshot.originTimeUnixMs < _modernFromUnixMs) {
    _reject(
      EarthquakeReportSourceError.unsupportedProfile,
      '/time',
      'Historical Core publication and intensity scale are unverified.',
    );
  }

  final source = snapshot.readSource();
  final numbers = snapshot.sourceNumbers;
  final epicenter = _position(numbers, source, '', requiredPosition: true);
  final mag = _measurement(numbers, source['mag'], '/mag', 2, -200, 1000);
  final depth = _measurement(numbers, source['depth'], '/depth', 3, 0, 1000000);
  final location = _localized(source['loc'], '/loc');
  final counties = _object(source['list'], '/list');
  if (counties.length > 256) {
    _reject(EarthquakeReportSourceError.inputLimit, '/list', 'Too many areas.');
  }
  final areas = <Map<String, Object?>>[];
  final observations = <Map<String, Object?>>[];
  for (final county in counties.entries) {
    final areaId = '/list/${escapeReportPointerKey(county.key)}';
    _validatePointerLength(areaId);
    final area = _object(county.value, areaId);
    final areaIntensity = _intensity(numbers, area['int'], '$areaId/int');
    areas.add({
      'id': areaId,
      'intensity': areaIntensity,
      'name': _localized(county.key, areaId),
      'region_id': null,
    });
    final towns = _object(area['town'], '$areaId/town');
    if (towns.length > 2048 - observations.length) {
      _reject(
        EarthquakeReportSourceError.inputLimit,
        '$areaId/town',
        'Too many observations.',
      );
    }
    var maxObserved = -1;
    var hasUnknown = false;
    // Every observation is built from its own decoded entry under this exact
    // county. Escaping is injective and the scanner already rejected duplicate
    // decoded keys, so the pointers are unique and reference the parent area.
    for (final town in towns.entries) {
      final id = '$areaId/town/${escapeReportPointerKey(town.key)}';
      _validatePointerLength(id);
      final station = _object(town.value, id);
      final intensity = _intensity(numbers, station['int'], '$id/int');
      if (intensity == null) {
        hasUnknown = true;
      } else {
        if (areaIntensity != null && intensity > areaIntensity) {
          _reject(
            EarthquakeReportSourceError.conflictingIntensity,
            '$id/int',
            'Observation exceeds its source area maximum.',
          );
        }
        if (intensity > maxObserved) maxObserved = intensity;
      }
      observations.add({
        'area_id': areaId,
        'id': id,
        'intensity': intensity,
        'name': _localized(town.key, id),
        'position': _position(numbers, station, id),
        'station_id': null,
      });
    }
    if (areaIntensity != null &&
        towns.isNotEmpty &&
        !hasUnknown &&
        maxObserved != areaIntensity) {
      _reject(
        EarthquakeReportSourceError.conflictingIntensity,
        '$areaId/int',
        'Area maximum disagrees with its fully known observations.',
      );
    }
  }
  areas.sort(_compareIds);
  observations.sort(_compareIds);
  final report = <String, Object?>{
    'areas': areas,
    'depth_m': depth,
    'epicenter': epicenter,
    'intensity_scale': 'cwa-2020',
    'location': location,
    'magnitude': mag == null ? null : {'centi': mag, 'kind': 'ml'},
    'observations': observations,
    'origin_time_unix_ms': snapshot.originTimeUnixMs,
    'published_max_intensity': null,
  };
  final identity = <String, Object?>{
    'namespace': 'exptech.eq-report-v2',
    'report_id': snapshot.reportId,
    'snapshot': {
      'body_sha256': snapshot.bodySha256,
      'kind': 'exptech_core_v2_json_pointer',
    },
  };
  final bytes = utf8.encode(
    jsonEncode({
      'locale': locale.tag,
      'report': report,
      'schema_version': 3,
      'source': {
        ...identity,
        'scale_evidence': {
          'kind': 'dataset_contract',
          'reference': _scaleReference,
        },
      },
    }),
  );
  if (bytes.length > 1024 * 1024) {
    _reject(
      EarthquakeReportSourceError.inputLimit,
      '',
      'V3 envelope exceeds 1 MiB.',
    );
  }
  return EarthquakeShareInputV3._(
    bytes: bytes,
    snapshot: snapshot,
    identity: identity,
    report: report,
  );
}

int _compareIds(Map<String, Object?> a, Map<String, Object?> b) {
  // UTF-8 byte order follows Unicode scalar order, unlike Dart's UTF-16
  // String.compareTo when a supplementary code point is involved.
  final left = (a['id']! as String).runes.iterator;
  final right = (b['id']! as String).runes.iterator;
  while (left.moveNext()) {
    if (!right.moveNext()) return 1;
    final compared = left.current.compareTo(right.current);
    if (compared != 0) return compared;
  }
  return right.moveNext() ? -1 : 0;
}

Map<String, dynamic> _object(Object? value, String path) {
  if (value == null) _missing(path, 'Expected a source object.');
  if (value is! Map<String, dynamic>) {
    _invalid(path, 'Expected a source object.');
  }
  return value;
}

Map<String, Object?> _localized(Object? value, String path) {
  if (value == null) _missing(path, 'Expected a source name.');
  if (value is! String ||
      value.replaceAll(' ', '').isEmpty ||
      _forbiddenText.hasMatch(value) ||
      utf8.encode(value).length > 512) {
    _invalid(path, 'Expected non-blank text of at most 512 UTF-8 bytes.');
  }
  return {'en-US': null, 'zh-Hant': value};
}

void _validatePointerLength(String pointer) {
  if (utf8.encode(pointer).length > 512) {
    _reject(
      EarthquakeReportSourceError.inputLimit,
      pointer,
      'Pointer exceeds 512 UTF-8 bytes.',
    );
  }
}

int? _intensity(Map<String, String> numbers, Object? value, String path) {
  if (value == null) return null;
  final token = numbers[path];
  if (token == null || token.length != 1) {
    _invalid(path, 'Expected a Core intensity integer from 0 to 9.');
  }
  // The source scanner has already checked that this is a JSON number token.
  return int.parse(token);
}

Map<String, int>? _position(
  Map<String, String> numbers,
  Map<String, dynamic> object,
  String path, {
  bool requiredPosition = false,
}) {
  final lat = _measurement(
    numbers,
    object['lat'],
    '$path/lat',
    6,
    -90000000,
    90000000,
  );
  final lon = _measurement(
    numbers,
    object['lon'],
    '$path/lon',
    6,
    -180000000,
    180000000,
  );
  if (lat != null && lon != null) return {'lat_e6': lat, 'lon_e6': lon};
  if (requiredPosition) {
    _missing(
      lat == null ? '$path/lat' : '$path/lon',
      'Expected both source coordinates.',
    );
  }
  return null;
}

int? _measurement(
  Map<String, String> numbers,
  Object? value,
  String path,
  int decimalPlaces,
  int min,
  int max,
) {
  if (value == null) return null;
  final token = numbers[path];
  if (token == null) {
    _invalid(path, 'Expected an original source decimal token.');
  }

  // Move the decimal point using the token itself. Only the bounded whole
  // part and the first rounding digit ever become machine integers.
  final negative = token.startsWith('-');
  final limit = negative ? -min : max;
  final exponentIndex = token.indexOf(RegExp('[eE]'));
  var exponent = 0;
  if (exponentIndex != -1) {
    final parsed = int.tryParse(token.substring(exponentIndex + 1), radix: 10);
    if (parsed == null || parsed < -2147483648 || parsed > 2147483647) {
      _invalid(path, 'Source decimal exponent is out of range.');
    }
    exponent = parsed;
  }
  final mantissa = token.substring(
    negative ? 1 : 0,
    exponentIndex == -1 ? null : exponentIndex,
  );
  final dot = mantissa.indexOf('.');
  final digits = mantissa.replaceFirst('.', '');
  final first = digits.indexOf(RegExp('[1-9]'));
  if (first < 0) return 0;
  final point =
      (dot < 0 ? mantissa.length : dot) + exponent + decimalPlaces - first;
  if (point > 9 || limit == 0) _outOfRange(path);
  if (point < 0) return 0;

  int digitAt(int index) =>
      index < digits.length ? digits.codeUnitAt(index) - 48 : 0;
  final fractionStart = first + point;
  var whole = 0;
  for (var i = first; i < fractionStart; i++) {
    whole = whole * 10 + digitAt(i);
  }
  if (whole > limit ||
      (whole == limit &&
          fractionStart < digits.length &&
          digits.indexOf(RegExp('[1-9]'), fractionStart) >= 0)) {
    _outOfRange(path);
  }
  final rounded = whole + (digitAt(fractionStart) >= 5 ? 1 : 0);
  return negative ? -rounded : rounded;
}

Never _outOfRange(String path) => _invalid(
  path,
  'Source decimal is outside the permitted range before rounding.',
);

Never _missing(String path, String detail) =>
    _reject(EarthquakeReportSourceError.missingEvidence, path, detail);

Never _invalid(String path, String detail) =>
    _reject(EarthquakeReportSourceError.invalidField, path, detail);

Never _reject(EarthquakeReportSourceError code, String path, String detail) =>
    throw EarthquakeReportSourceException(code, path, detail);
