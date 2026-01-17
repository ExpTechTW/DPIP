import 'package:collection/collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Extension on [Iterable] that provides convenient utilities for working with iterable collections.
///
/// This extension adds helpful methods to simplify common operations on iterable collections, including ordering,
/// searching, and element access.
extension IterableExtension<T> on Iterable<T> {
  /// Orders this iterable according to the sequence specified in [order].
  ///
  /// Returns a new iterable with elements sorted according to their position in [order]. Elements that appear in
  /// [order] are sorted by their index in [order], while elements not found in [order] are placed at the end,
  /// maintaining their relative order.
  ///
  /// The [order] parameter defines the desired ordering sequence. Elements are compared by their position in this
  /// sequence using `indexOf`, so elements appearing earlier in [order] will appear earlier in the result.
  ///
  /// Example:
  /// ```dart
  /// final items = ['c', 'a', 'd', 'b'];
  /// final order = ['a', 'b', 'c'];
  /// final ordered = items.orderedBy(order); // ['a', 'b', 'c', 'd']
  /// ```
  ///
  /// Note: Elements not present in [order] will have an index of -1 and will be sorted to the end.
  Iterable<T> orderedBy(Iterable<T> order) {
    final orderList = order.toList();
    return toList().sorted(
      (a, b) => orderList.indexOf(a) - orderList.indexOf(b),
    );
  }

  /// Checks whether any element of this iterable satisfies [test].
  ///
  /// Checks every element in iteration order, and returns `true` if any element matches [test] and `false` otherwise.
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

  /// Returns the last element of this iterable, or `null` if the iterable is empty.
  T? get lastOrNull => isNotEmpty ? last : null;
}

/// Extension on [List] that provides convenient utilities for working with lists.
///
/// This extension adds helpful methods to simplify common list operations, such as joining elements with separators.
extension ListExtension<T> on List<T> {
  /// Joins the elements of this list with the given [separator] between each element.
  ///
  /// This is similar to [List.join] but returns a new list instead of a string. The resulting list will have `length *
  /// 2 - 1` elements, with the [separator] inserted between each original element.
  ///
  /// Returns an empty list if this list is empty.
  ///
  /// Example:
  /// ```dart
  /// final list = [1, 2, 3];
  /// final result = list.superJoin(0); // [1, 0, 2, 0, 3]
  /// ```
  List<T> superJoin(T separator) {
    if (isEmpty) return [];
    return expand(
      (element) => [element, separator],
    ).take(length * 2 - 1).toList();
  }
}

/// Extension on [List<double>] that provides convenient utilities for geographic coordinate conversion.
///
/// This extension adds helpful getters and methods to convert lists of doubles to geographic coordinate objects and
/// perform geographic operations used in mapping libraries.
extension ListDoubleExtension on List<double> {
  /// Converts this list to a [LatLng] coordinate.
  ///
  /// The list must contain at least 2 elements: `[latitude, longitude]`.
  LatLng get asLatLng => LatLng(this[0], this[1]);

  /// Converts this list to a [LatLngBounds] object.
  ///
  /// The list must contain at least 4 elements: `[southwestLat, southwestLng, northeastLat, northeastLng]`.
  LatLngBounds get asLatLngBounds => LatLngBounds(
    southwest: LatLng(this[0], this[1]),
    northeast: LatLng(this[2], this[3]),
  );

  /// Expands this bounding box to include the given [point].
  ///
  /// This list must contain exactly 4 elements representing a bounding box in the format
  /// `[southLat, westLng, northLat, eastLng]`. The method modifies this list in place to include
  /// the given [point] within the bounds, expanding the box as necessary.
  ///
  /// Returns this list for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final bounds = [25.0, 121.0, 25.5, 121.5]; // Initial bounds
  /// bounds.expandBounds(LatLng(24.9, 120.9)); // Expands south and west
  /// ```
  List<double> expandBounds(LatLng point) {
    assert(length == 4, 'Bounds must contain exactly 4 elements');

    // South
    if (this[0] > point.latitude) {
      this[0] = point.latitude;
    }
    // West
    if (this[1] > point.longitude) {
      this[1] = point.longitude;
    }
    // North
    if (this[2] < point.latitude) {
      this[2] = point.latitude;
    }
    // East
    if (this[3] < point.longitude) {
      this[3] = point.longitude;
    }

    return this;
  }
}

/// Extension on [Set] that provides convenient utilities for ordering collections.
///
/// This extension adds helpful methods to simplify ordering operations based on a predefined order sequence, making it
/// easy to sort collections according to a specific order rather than natural ordering.
extension SetExtension<T> on Set<T> {
  /// Orders this set according to the sequence specified in [order].
  ///
  /// Returns a new set with elements sorted according to their position in [order]. Elements that appear in [order] are
  /// sorted by their index in [order], while elements not found in [order] are placed at the end, maintaining their
  /// relative order.
  ///
  /// The [order] parameter defines the desired ordering sequence. Elements are compared by their position in this
  /// sequence using `indexOf`, so elements appearing earlier in [order] will appear earlier in the result.
  ///
  /// Example:
  /// ```dart
  /// final items = {'c', 'a', 'd', 'b'};
  /// final order = ['a', 'b', 'c'];
  /// final ordered = items.orderedBy(order); // {'a', 'b', 'c', 'd'}
  /// ```
  ///
  /// Note: Elements not present in [order] will have an index of -1 and will be sorted to the end.
  Set<T> orderedBy(Iterable<T> order) {
    final orderList = order.toList();
    return sorted(
      (a, b) => orderList.indexOf(a) - orderList.indexOf(b),
    ).toSet();
  }
}
