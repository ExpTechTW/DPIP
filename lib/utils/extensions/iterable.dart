import 'package:collection/collection.dart';

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> orderedBy(Iterable<T> order) {
    final orderList = order.toList();
    return toList().sorted((a, b) => orderList.indexOf(a) - orderList.indexOf(b));
  }
}

extension SetExtension<T> on Set<T> {
  Set<T> orderedBy(Iterable<T> order) {
    final orderList = order.toList();
    return sorted((a, b) => orderList.indexOf(a) - orderList.indexOf(b)).toSet();
  }
}
