/// Where a diagnostics dump goes.
library;

/// Uploads a dump and answers with the URL to read it at, or null when the
/// service replied with nothing usable.
///
/// An interface so the developer page can ask for the upload without reaching
/// into `data/` for the service that performs it — the page cares that a dump
/// becomes a link, not which paste service is behind it.
abstract interface class DumpUploader {
  Future<String?> upload(String content);
}
