import 'dart:convert';

import 'package:http/http.dart';

/// Extension on [Response] that provides convenient utilities for HTTP response handling.
///
/// This extension adds helpful getters to simplify common response validation operations, making it easier to check
/// response status and handle HTTP responses.
extension ResponseExtension on Response {
  /// Checks if the response status code is in the 2xx range (200-299).
  ///
  /// Returns `true` if the status code is between 200 and 299, indicating a successful HTTP response. Returns `false`
  /// otherwise.
  ///
  /// This is a convenient way to check if an HTTP request was successful without explicitly comparing status codes. All
  /// 2xx status codes (200 OK, 201 Created, 204 No Content, etc.) are considered successful responses.
  ///
  /// Example:
  /// ```dart
  /// final response = await http.get(Uri.parse('https://example.com'));
  /// if (response.ok) {
  ///   // Handle successful response
  ///   print('Request succeeded: ${response.body}');
  /// } else {
  ///   // Handle error
  ///   print('Request failed with status: ${response.statusCode}');
  /// }
  /// ```
  bool get ok => (statusCode - 200) < 100 && (statusCode - 200) >= 0;

  /// Parses the response body as a JSON list.
  ///
  /// Decodes the response body string as JSON and returns it as a [List].
  /// Throws a [FormatException] if the body is not valid JSON or if the JSON
  /// value is not a list.
  ///
  /// Example:
  /// ```dart
  /// final response = await http.get('https://api.example.com/items'.asUri);
  /// if (response.ok) {
  ///   final items = response.list();
  ///   print('Received ${items.length} items');
  /// }
  /// ```
  List list() => jsonDecode(body) as List;

  /// Parses the response body as a JSON object.
  ///
  /// Decodes the response body string as JSON and returns it as a
  /// [Map<String, dynamic>]. Throws a [FormatException] if the body is not
  /// valid JSON or if the JSON value is not an object.
  ///
  /// Example:
  /// ```dart
  /// final response = await http.get('https://api.example.com/user/123'.asUri);
  /// if (response.ok) {
  ///   final user = response.json();
  ///   print('User name: ${user['name']}');
  /// }
  /// ```
  Map<String, dynamic> json() => jsonDecode(body) as Map<String, dynamic>;
}
