import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';

/// Access to Earthquake Early Warning data.
///
/// The repository template: presentation depends on this **abstraction** (never
/// on the API classes or the data layer), the concrete implementation and its
/// JSON mapping live in `data/`, and tests supply a fake. All methods return a
/// [Result] so failures are explicit.
abstract interface class EewRepository {
  /// The currently-active EEW alerts, newest first; `Ok([])` when none.
  Future<Result<List<Eew>>> activeEews();
}
