/// Server status repository contract.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/status/domain/server_status.dart';

/// Fetches the ExpTech status dashboard snapshot.
///
/// The underlying graphite URL is content-addressed for our purposes: the query
/// body is a compile-time constant, so the same URL always means the same query
/// and the ETag store treats it like an immutable tile — a revisit is a local
/// SQLite read, not a round trip to Grafana.
abstract class ServerStatusRepository {
  /// The current dashboard snapshot.
  Future<Result<ServerStatus>> status();
}
