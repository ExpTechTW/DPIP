import Foundation

/// The one place the per-target hourly-forecast cache's location is written.
///
/// It lives in `Shared` rather than beside `ForecastWidgetSnapshotStore`, which
/// is the only thing that reads and writes files in it, because two targets
/// need the path and only one of them can see that store. The store is built on
/// `WidgetLocationTarget`, `ForecastWidgetSnapshot` and `ForecastWidgetExpiry`,
/// none of which the app links; making it a Runner member to reach one
/// directory name would drag the widget's whole model layer across.
///
/// The alternative was to spell the path a second time inside the plugin, and a
/// second spelling of a snapshot path is the exact defect this repository has
/// already shipped once: when current weather became one file per target, only
/// the write path was told, and `clear` went on removing a single legacy file,
/// reporting success, and leaving every real snapshot on disk.
enum ForecastSnapshotLocation {
    static func directoryURL(in containerURL: URL) -> URL {
        containerURL
            .appendingPathComponent("WidgetSnapshots", isDirectory: true)
            .appendingPathComponent("hourly-forecast", isDirectory: true)
    }

    /// Removes the whole cache under one delete claim.
    ///
    /// `ForecastWidgetSnapshotStore.write` coordinates on the individual file,
    /// which is a descendant of this directory, so the claim conflicts with a
    /// refresh already writing — without it a forecast published a moment
    /// before the clear could recreate the directory and survive it.
    static func removeAll(in containerURL: URL) throws {
        let directory = directoryURL(in: containerURL)
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var result: Result<Void, Error>?

        coordinator.coordinate(
            writingItemAt: directory,
            options: .forDeleting,
            error: &coordinationError
        ) { coordinatedURL in
            result = Result {
                do {
                    try FileManager.default.removeItem(at: coordinatedURL)
                } catch let error as CocoaError
                    where error.code == .fileNoSuchFile
                {
                    // Nothing cached yet, or already cleared.
                }
            }
        }

        if let result {
            return try result.get()
        }
        if let coordinationError {
            throw coordinationError
        }
    }
}
