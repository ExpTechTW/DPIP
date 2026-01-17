/// A no-operation function that does nothing.
///
/// This function is useful as a placeholder callback or default handler when a function parameter
/// is required but no action is needed. It can be used to satisfy function type requirements without
/// performing any operations.
///
/// Example:
/// ```dart
/// // Use as a default callback
/// onTap: someCondition ? handleTap : noop;
///
/// // Use as a placeholder
/// final callback = noop;
/// ```
void noop() {}

/// Comparison function for ascending order sorting.
///
/// Used with [List.sort] or [Iterable.sorted] to sort numeric values in ascending order (smallest to largest).
///
/// Example:
/// ```dart
/// final numbers = [3, 1, 4, 1, 5];
/// numbers.sort(ascending); // [1, 1, 3, 4, 5]
/// ```
int ascending(num a, num b) => a.compareTo(b);

/// Comparison function for descending order sorting.
///
/// Used with [List.sort] or [Iterable.sorted] to sort numeric values in descending order (largest to smallest).
///
/// Example:
/// ```dart
/// final numbers = [3, 1, 4, 1, 5];
/// numbers.sort(descending); // [5, 4, 3, 1, 1]
/// ```
int descending(num a, num b) => b.compareTo(a);
