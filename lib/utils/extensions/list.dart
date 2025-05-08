import 'package:maplibre_gl/maplibre_gl.dart';

extension ListExtension<T> on List<T> {
  /// Joins the elements of this list with the given [separator] between each element.
  ///
  /// This is similar to [List.join] but returns a new list instead of a string.
  /// The resulting list will have [length * 2 - 1] elements, with the [separator]
  /// inserted between each original element.
  ///
  /// Example:
  /// ```dart
  /// final list = [1, 2, 3];
  /// final result = list.superJoin(0); // [1, 0, 2, 0, 3]
  /// ```
  ///
  /// Returns an empty list if this list is empty.
  List<T> superJoin(T separator) {
    if (isEmpty) return [];
    return expand((element) => [element, separator]).take(length * 2 - 1).toList();
  }
}

extension ListExtension2 on List<double> {
  LatLng get asLatLng => LatLng(this[0], this[1]);
}

extension IterableExtension<T> on Iterable<T> {
  /// Checks whether any element of this iterable satisfies [test].
  ///
  /// Checks every element in iteration order, and returns `true` if
  /// any element matches [test] and `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final list = [1, 2, 3];
  /// final result = list.containsWhere((element) => element == 2); // true
  /// ```
  bool containsWhere(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  T? get lastOrNull => isNotEmpty ? last : null;
}
