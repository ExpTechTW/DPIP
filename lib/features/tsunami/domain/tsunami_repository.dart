/// Access to CWA tsunami bulletins.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/tsunami/domain/tsunami_report.dart';

/// Reads the tsunami index (the event's reports) and one full bulletin.
abstract interface class TsunamiRepository {
  /// Every report of the **newest event**, newest first; `Ok([])` when CWA has
  /// issued nothing at all.
  ///
  /// An event, not the whole index: a bulletin is re-issued as the event
  /// develops (第1報 predicted areas, 第3報 the cancellation with the observed
  /// heights), so a reader needs the event's reports together — and only the
  /// newest event, since a 2024 bulletin must not be listed under this year's.
  Future<Result<List<TsunamiBulletin>>> bulletins();

  /// One report in full, by its [TsunamiBulletin.id].
  Future<Result<TsunamiReport>> report(String id);
}
