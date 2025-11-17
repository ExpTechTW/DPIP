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
}
