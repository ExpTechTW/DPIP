/// Cloudflare status repository contract.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';

/// Fetches the Cloudflare status-page snapshot for the regions the app uses.
abstract class CloudflareStatusRepository {
  /// The current Taipei / Kaohsiung component statuses.
  Future<Result<CloudflareStatus>> status();
}
