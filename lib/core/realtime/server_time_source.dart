import 'package:dpip/core/error/result.dart';

/// Source of corrected server time in ms-since-epoch (UTC), behind a seam so the
/// clock is testable without a network.
///
/// The production implementation is `NtpTimeSource` (real SNTP via
/// `flutter_ntp`); tests inject a fake.
abstract interface class ServerTimeSource {
  /// The server's current time (ms since epoch, UTC), or a [Failure].
  Future<Result<int>> serverTimeMs();
}
