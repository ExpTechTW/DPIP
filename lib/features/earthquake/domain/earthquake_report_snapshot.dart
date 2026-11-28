import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';

enum EarthquakeReportSourceError {
  malformedJson,
  duplicateKey,
  invalidField,
  identityMismatch,
  missingEvidence,
  unsupportedProfile,
  conflictingIntensity,
  inputLimit,
}

/// Source diagnostics use RFC 6901 JSON Pointers. The empty pointer is the
/// root; [offset] identifies a syntax error by its position in the JSON text.
final class EarthquakeReportSourceException extends FormatException {
  const EarthquakeReportSourceException(
    this.code,
    this.path,
    String message, [
    int? offset,
  ]) : super(message, null, offset);

  final EarthquakeReportSourceError code;
  final String path;
}

/// Exact content-decoded bytes from a single ExpTech Core v2 detail response.
///
/// The repository establishes the HTTP source. [decode] checks the body and
/// request identity, and is also used with archived bytes for offline tests.
final class CoreEarthquakeReportSnapshot {
  CoreEarthquakeReportSnapshot._({
    required this.body,
    required this.reportId,
    required this.originTimeUnixMs,
    required this.sourceNumbers,
    this.endpoint,
    this.confirmedAt,
    this.etag,
    this.revalidated = false,
  });

  final Uint8List body;
  final String reportId;
  final int originTimeUnixMs;
  final Map<String, String> sourceNumbers;
  final Uri? endpoint;

  /// When this HTTP request obtained or revalidated the body.
  final DateTime? confirmedAt;
  final String? etag;
  final bool revalidated;

  late final String bodySha256 = sha256.convert(body).toString();

  /// Decode the same bytes using DPIP's ordinary detail model. That model
  /// requires some fields the share contract can represent as unknown.
  late final EarthquakeReport report = EarthquakeReport.fromJson(readSource());

  /// Returns a fresh source object. Exact numeric spelling lives in
  /// [sourceNumbers]; this object supplies shape, decoded keys and text.
  Map<String, dynamic> readSource() =>
      jsonDecode(utf8.decode(body)) as Map<String, dynamic>;

  factory CoreEarthquakeReportSnapshot.decode(
    Uint8List body, {
    required String requestedReportId,
    Uri? endpoint,
    DateTime? confirmedAt,
    String? etag,
    bool revalidated = false,
  }) {
    if (body.length > 2 * 1024 * 1024) {
      _sourceLimit('', 'Source body exceeds 2 MiB.');
    }
    final bytes = Uint8List.fromList(body).asUnmodifiableView();
    final text = _decodeSourceText(bytes);
    final numbers = _ReportJsonScan(text, strictSource: true).scan();
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const EarthquakeReportSourceException(
        EarthquakeReportSourceError.malformedJson,
        '',
        'Expected a single Core detail object.',
      );
    }
    if (requestedReportId != decoded['id'] ||
        _fullReportId.stringMatch(requestedReportId) != requestedReportId) {
      _identityMismatch(
        '/id',
        'Expected the complete requested Core report ID.',
      );
    }
    _requireInt(numbers, '/time');
    final time = int.parse(numbers['/time']!);
    if (time < EarthquakeReportSnapshot.minReportTime ||
        time > EarthquakeReportSnapshot.maxReportTime) {
      _invalid('/time', 'Expected Unix milliseconds within 0001-9999.');
    }
    final taipei = DateTime.fromMillisecondsSinceEpoch(
      time,
      isUtc: true,
    ).add(const Duration(hours: 8));
    String two(int value) => value.toString().padLeft(2, '0');
    final year = taipei.year.toString().padLeft(4, '0');
    final idTime =
        '$year-${two(taipei.month)}${two(taipei.day)}-'
        '${two(taipei.hour)}${two(taipei.minute)}${two(taipei.second)}';
    if (requestedReportId.substring(7) != idTime) {
      _identityMismatch(
        '/time',
        'Origin time disagrees with the Taipei timestamp in the ID.',
      );
    }
    return CoreEarthquakeReportSnapshot._(
      body: bytes,
      reportId: requestedReportId,
      originTimeUnixMs: time,
      sourceNumbers: Map.unmodifiable(numbers),
      endpoint: endpoint,
      confirmedAt: confirmedAt,
      etag: etag,
      revalidated: revalidated,
    );
  }
}

/// The display model and evidence from the same ExpTech Core v2 detail body.
/// See https://exptech.dev/docs/api/earthquake/report/.
final class EarthquakeReportSnapshot {
  EarthquakeReportSnapshot._({
    required this.report,
    required this.requestedReportId,
    required this.bodySha256,
    required this.etag,
    required Map<String, String> sourceNumbers,
  }) : sourceNumbers = Map.unmodifiable(sourceNumbers);

  final EarthquakeReport report;
  final String requestedReportId;

  /// The optional HTTP validator associated with this exact response body.
  final String? etag;

  /// Fingerprint of the original HTTP entity, including its JSON spelling.
  /// Supplemental county/station identities can be checked against this exact
  /// snapshot. The detail body supplies only their names and station positions.
  final String bodySha256;

  /// Unmodified JSON number tokens, indexed by source JSON Pointer.
  final Map<String, String> sourceNumbers;

  /// The Unix-millisecond range Share Render Input v2 accepts (0001–9999).
  /// Bounding it here also keeps every later `DateTime` conversion in range.
  static const minReportTime = -62135625600000;
  static const maxReportTime = 253402271999999;

  bool get hasMatchingReportId =>
      requestedReportId == report.id &&
      _fullReportId.stringMatch(report.id) == report.id;

  factory EarthquakeReportSnapshot.decode(
    Uint8List body, {
    required String requestedReportId,
    String? etag,
  }) {
    final text = _decodeSourceText(body);
    final numbers = _ReportJsonScan(text).scan();
    final json = _object(jsonDecode(text), '');
    for (final field in ['id', 'loc']) {
      if (json[field] is! String) _invalid('/$field', 'Expected a string');
    }
    _requireInt(numbers, '/time');
    final time = int.parse(numbers['/time']!);
    if (time < minReportTime || time > maxReportTime) {
      _invalid('/time', 'Expected Unix milliseconds within 0001-9999');
    }
    _requireInt(numbers, '/trem');
    for (final field in ['lat', 'lon', 'depth', 'mag']) {
      _requireFinite(json, '', field);
    }
    for (final county in _object(json['list'], '/list').entries) {
      final path = '/list/${escapeReportPointerKey(county.key)}';
      final area = _object(county.value, path);
      _requireInt(numbers, '$path/int');
      for (final entry in _object(area['town'], '$path/town').entries) {
        final stationPath = '$path/town/${escapeReportPointerKey(entry.key)}';
        final station = _object(entry.value, stationPath);
        _requireInt(numbers, '$stationPath/int');
        _requireFinite(station, stationPath, 'lat');
        _requireFinite(station, stationPath, 'lon');
      }
    }
    return EarthquakeReportSnapshot._(
      report: EarthquakeReport.fromJson(json),
      requestedReportId: requestedReportId,
      bodySha256: sha256.convert(body).toString(),
      etag: etag,
      sourceNumbers: numbers,
    );
  }
}

final _fullReportId = RegExp(r'^[0-9]{6}-[0-9]{4}-[0-9]{4}-[0-9]{6}$');

String _decodeSourceText(Uint8List body) {
  try {
    // utf8.decode strips a leading BOM, so inspect it before decoding.
    if (body.length >= 3 &&
        body[0] == 0xef &&
        body[1] == 0xbb &&
        body[2] == 0xbf) {
      throw const FormatException('Unexpected BOM');
    }
    return utf8.decode(body);
  } on FormatException {
    throw const EarthquakeReportSourceException(
      EarthquakeReportSourceError.malformedJson,
      '',
      'Expected a UTF-8 report body without a BOM.',
    );
  }
}

Never _sourceLimit(String path, String message) =>
    throw EarthquakeReportSourceException(
      EarthquakeReportSourceError.inputLimit,
      path,
      message,
    );

Never _identityMismatch(String path, String message) =>
    throw EarthquakeReportSourceException(
      EarthquakeReportSourceError.identityMismatch,
      path,
      message,
    );

Map<String, dynamic> _object(Object? value, String path) {
  if (value is! Map<String, dynamic>) _invalid(path, 'Expected an object');
  return value;
}

void _requireInt(Map<String, String> numbers, String path) {
  final token = numbers[path];
  // The generated model uses num.toInt(), so check the source token before
  // it can silently truncate a fraction or round an out-of-range integer.
  if (token == null || int.tryParse(token) == null) {
    _invalid(path, 'Expected a JSON integer in range');
  }
}

void _requireFinite(Map<String, dynamic> object, String path, String field) {
  final value = object[field];
  if (value is! num || !value.isFinite) {
    _invalid('$path/$field', 'Expected a finite JSON number');
  }
}

Never _invalid(String path, String message) =>
    throw EarthquakeReportSourceException(
      EarthquakeReportSourceError.invalidField,
      path,
      message,
    );

String escapeReportPointerKey(String key) =>
    key.replaceAll('~', '~0').replaceAll('/', '~1');

/// Scans JSON before jsonDecode can discard duplicate keys or numeric spelling.
/// Keys are decoded individually so an escaped key and its literal equivalent
/// compare equal. Decode the complete, validated document with Dart's decoder.
final class _ReportJsonScan {
  _ReportJsonScan(this._text, {this.strictSource = false});

  final bool strictSource;

  final String _text;
  final _numbers = <String, String>{};
  var _offset = 0;
  var _values = 0;

  static final _space = RegExp(r'[ \t\r\n]*');
  static final _number = RegExp(
    r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?(?=$|[ \t\r\n,}\]])',
  );

  static final _negativeZero = RegExp(r'^-0(?:\.0+)?(?:[eE]|$)');

  Map<String, String> scan() {
    _value('', 0);
    _skipSpace();
    if (_offset != _text.length) _syntax('', 'Unexpected trailing input');
    return _numbers;
  }

  void _value(String path, int depth) {
    if (strictSource) {
      if (depth > 40) _sourceLimit(path, 'Source nesting exceeds 40 levels.');
      if (++_values > 50000) {
        _sourceLimit(path, 'Source exceeds 50,000 JSON values.');
      }
      if (path.length > 1024 || utf8.encode(path).length > 1024) {
        _sourceLimit('', 'Source pointer exceeds 1,024 UTF-8 bytes.');
      }
    } else if (depth > 64) {
      _syntax(path, 'JSON nesting is too deep');
    }
    _skipSpace();
    if (_take('{')) {
      _objectValue(path, depth);
    } else if (_take('[')) {
      _arrayValue(path, depth);
    } else if (_text.startsWith('"', _offset)) {
      _readString(path);
    } else if (!_take('true') && !_take('false') && !_take('null')) {
      final token = _match(_number);
      if (token == null) _syntax(path, 'Expected a JSON value');
      if (strictSource && _negativeZero.hasMatch(token)) {
        _invalid(path, 'Negative zero is ambiguous across JSON decoders.');
      }
      _numbers[path] = token;
    }
  }

  // Scan without a repeated regex over potentially very large strings.
  // The standard decoder validates JSON escape syntax on the isolated token.
  String _readString(String path) {
    final start = _offset;
    if (!_take('"')) _syntax(path, 'Expected a JSON string');
    while (_offset < _text.length) {
      final unit = _text.codeUnitAt(_offset++);
      if (unit == 0x5c) {
        if (_offset < _text.length) _offset++;
      } else if (unit == 0x22) {
        final String value;
        try {
          value = jsonDecode(_text.substring(start, _offset)) as String;
        } on FormatException {
          _syntax(path, 'Invalid JSON string');
        }
        if (!_hasPairedSurrogates(value)) {
          _syntax(path, 'Unpaired surrogate in JSON string');
        }
        return value;
      }
    }
    _syntax(path, 'Unterminated JSON string');
  }

  static bool _hasPairedSurrogates(String value) {
    for (var i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      if (unit < 0xd800 || unit > 0xdfff) continue;
      if (unit >= 0xdc00 || ++i == value.length) return false;
      final low = value.codeUnitAt(i);
      if (low < 0xdc00 || low > 0xdfff) return false;
    }
    return true;
  }

  void _objectValue(String path, int depth) {
    _skipSpace();
    if (_take('}')) return;
    final keys = <String>{};
    do {
      _skipSpace();
      final keyOffset = _offset;
      final key = _readString(path);
      final child = '$path/${escapeReportPointerKey(key)}';
      if (!keys.add(key)) {
        throw EarthquakeReportSourceException(
          EarthquakeReportSourceError.duplicateKey,
          child,
          'Duplicate JSON object key',
          keyOffset,
        );
      }
      _expect(':', child);
      _value(child, depth + 1);
      _skipSpace();
    } while (_take(','));
    _expect('}', path);
  }

  void _arrayValue(String path, int depth) {
    _skipSpace();
    if (_take(']')) return;
    var index = 0;
    do {
      _value('$path/$index', depth + 1);
      index++;
      _skipSpace();
    } while (_take(','));
    _expect(']', path);
  }

  void _skipSpace() {
    _offset = _space.matchAsPrefix(_text, _offset)!.end;
  }

  bool _take(String token) {
    if (!_text.startsWith(token, _offset)) return false;
    _offset += token.length;
    return true;
  }

  String? _match(RegExp pattern) {
    final match = pattern.matchAsPrefix(_text, _offset);
    if (match == null) return null;
    _offset = match.end;
    return match.group(0);
  }

  void _expect(String token, String path) {
    _skipSpace();
    if (!_take(token)) _syntax(path, 'Expected $token');
  }

  Never _syntax(String path, String message) =>
      throw EarthquakeReportSourceException(
        EarthquakeReportSourceError.malformedJson,
        path,
        message,
        _offset,
      );
}
