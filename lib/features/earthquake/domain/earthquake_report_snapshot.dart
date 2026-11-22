import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';

enum EarthquakeReportSourceError { malformedJson, duplicateKey, invalidField }

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

  static final _fullReportId = RegExp(r'^[0-9]{6}-[0-9]{4}-[0-9]{4}-[0-9]{6}$');

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
    final String text;
    try {
      text = utf8.decode(body);
    } on FormatException {
      throw const EarthquakeReportSourceException(
        EarthquakeReportSourceError.malformedJson,
        '',
        'Expected a UTF-8 report body',
      );
    }
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
      final path = '/list/${_pointerToken(county.key)}';
      final area = _object(county.value, path);
      _requireInt(numbers, '$path/int');
      for (final entry in _object(area['town'], '$path/town').entries) {
        final stationPath = '$path/town/${_pointerToken(entry.key)}';
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

String _pointerToken(String key) =>
    key.replaceAll('~', '~0').replaceAll('/', '~1');

/// Scans JSON before jsonDecode can discard duplicate keys or numeric spelling.
/// Keys are decoded individually so an escaped key and its literal equivalent
/// compare equal. Decode the complete, validated document with Dart's decoder.
final class _ReportJsonScan {
  _ReportJsonScan(this._text);

  final String _text;
  final _numbers = <String, String>{};
  var _offset = 0;

  static final _space = RegExp(r'[ \t\r\n]*');
  static final _string = RegExp(
    r'"(?:[^"\\\x00-\x1f]|\\(?:["\\/bfnrt]|u[0-9a-fA-F]{4}))*"',
  );
  static final _number = RegExp(
    r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?(?=$|[ \t\r\n,}\]])',
  );

  Map<String, String> scan() {
    _value('', 0);
    _skipSpace();
    if (_offset != _text.length) _syntax('', 'Unexpected trailing input');
    return _numbers;
  }

  void _value(String path, int depth) {
    if (depth > 64) _syntax(path, 'JSON nesting is too deep');
    _skipSpace();
    if (_take('{')) {
      _objectValue(path, depth);
    } else if (_take('[')) {
      _arrayValue(path, depth);
    } else if (_match(_string) == null &&
        !_take('true') &&
        !_take('false') &&
        !_take('null')) {
      final token = _match(_number);
      if (token == null) _syntax(path, 'Expected a JSON value');
      _numbers[path] = token;
    }
  }

  void _objectValue(String path, int depth) {
    _skipSpace();
    if (_take('}')) return;
    final keys = <String>{};
    do {
      _skipSpace();
      final keyOffset = _offset;
      final token = _match(_string);
      if (token == null) _syntax(path, 'Expected a JSON object key');
      final key = jsonDecode(token) as String;
      final child = '$path/${_pointerToken(key)}';
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
