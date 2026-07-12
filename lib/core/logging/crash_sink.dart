/// A destination for errors beyond the in-app log — a crash-reporting service
/// (e.g. Firebase Crashlytics / Sentry).
///
/// A seam, not an implementation: [Log] forwards handled and uncaught errors to
/// the sink set on it at start-up. Until a reporter is configured the sink is
/// null and errors go only to the in-app log, so the rest of the app never
/// depends on a specific provider.
abstract interface class CrashSink {
  /// Reports [error] with [stackTrace]. [fatal] distinguishes an uncaught crash
  /// from a handled exception; [context] is an optional human-readable label.
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal,
  });
}
