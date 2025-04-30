import "package:http/http.dart";

extension ResponseExtension on Response {
  /// Checks if the response status code is in the 2xx range (200-299).
  ///
  /// Returns `true` if the status code is between 200 and 299, indicating a successful response.
  /// Returns `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final response = await http.get(Uri.parse('https://example.com'));
  /// if (response.ok) {
  ///   // Handle successful response
  /// } else {
  ///   // Handle error
  /// }
  /// ```
  bool get ok => (statusCode - 200) < 100 && (statusCode - 200) >= 0;
}
