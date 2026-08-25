import Foundation
import SQLite3

/// The device's own movement history, written where the fixes arrive.
///
/// Background location wakes the app with the screen off and Dart not running,
/// so the track has to be written by the same native code that already reports
/// the fix. Dart never writes here — it opens this file read-only — and the
/// eviction that keeps it under budget is native too. One owner for the format,
/// one owner for the size.
///
/// ## Why its own file
///
/// Not a table in `dpip.db`. That database belongs to Dart's `sqlite_async`,
/// which keeps a WAL connection pool across isolates; a second writer in
/// another process would be a cross-process multi-writer, and its schema is
/// migrated by code this class cannot see. A separate file makes both problems
/// disappear and costs one file handle.
///
/// ## The encoding
///
/// Rows hold **deltas**, not absolutes. SQLite already stores small integers in
/// one or two bytes and large ones in four or six, so a delta of `+3` costs a
/// byte where an absolute latitude costs four — the compression is the record
/// format's, and nothing has to encode or decode a private blob.
///
/// Every 64th row is an **anchor**: absolute values, recognised by
/// `rowid % 64 == 0`, so no column is spent marking it. Eviction removes whole
/// anchor groups, which is what keeps the chain readable after the head is
/// gone — deleting a single delta row would silently displace everything after
/// it.
///
///     anchor  t(4) + lat(3) + lng(3) + header ≈ 14 B
///     delta   t(1) + lat(1) + lng(1) + header ≈  8 B
///
/// Measured at 14.19 bytes a row over 200,000 rows, rowid and B-tree included,
/// so the budget below holds about 3.7 million fixes. Significant-change
/// delivers tens to low hundreds a day, which is a century of them; the budget
/// is there for the pathological case, not the expected one.
final class LocationTrackStore {
  static let shared = LocationTrackStore()

  /// Degrees are stored as ten-thousandths: about 11 m, and the precision the
  /// caller asked for.
  private static let scale = 10_000.0

  /// Rows between absolute anchors. A power of two so the modulo is cheap and
  /// the boundary is obvious in a hex dump.
  private static let anchorEvery: Int64 = 64

  private static let budgetBytes: Int64 = 50 * 1024 * 1024

  /// How often to bother checking the size. The check is a `pragma` pair, but
  /// it runs inside a background wake window measured in seconds, and the file
  /// cannot grow by a meaningful fraction of 50 MB between two fixes.
  private static let checkEvery: Int64 = 512

  private var db: OpaquePointer?
  private let queue = DispatchQueue(label: "com.exptech.dpip.location-track")

  private init() {}

  /// Records one fix. Safe to call from any thread; never throws into the
  /// caller, because the caller is a location callback whose failure would take
  /// the reporting path down with it.
  func record(latitude: Double, longitude: Double, at time: Date = Date()) {
    queue.async { [weak self] in
      guard let self, let db = self.open() else { return }
      let t = Int64(time.timeIntervalSince1970)
      let lat = Int64((latitude * Self.scale).rounded())
      let lng = Int64((longitude * Self.scale).rounded())

      var rowid = self.lastRowId(db) + 1
      let previous = rowid % Self.anchorEvery == 0 ? nil : self.lastAbsolute(db)

      // A row that cannot be a delta has to be an anchor, and an anchor is
      // recognised by its rowid alone — so move the row to the next boundary
      // rather than writing an absolute value where a reader expects a delta.
      // Happens exactly twice: on the first fix, and on the first after the
      // tail was evicted.
      if previous == nil, rowid % Self.anchorEvery != 0 {
        rowid += Self.anchorEvery - rowid % Self.anchorEvery
      }

      self.insert(
        db, rowid: rowid,
        t: previous.map { t - $0.t } ?? t,
        lat: previous.map { lat - $0.lat } ?? lat,
        lng: previous.map { lng - $0.lng } ?? lng)
      self.evictIfNeeded(db)
    }
  }

  /// Deletes every recorded fix and hands the pages back to the filesystem.
  ///
  /// Through the open handle on the store's own queue, never by unlinking the
  /// file. This class caches `db` for the life of the process, and a handle
  /// whose file was removed underneath it goes on writing perfectly happily
  /// into an unlinked inode: the rows reappear the moment anything reads, the
  /// space is never returned, and nothing anywhere reports a problem.
  ///
  /// [completion] fires on the queue once the delete has actually run, so a
  /// caller that re-reads the count sees the cleared store rather than the one
  /// it asked to clear.
  func clear(completion: (() -> Void)? = nil) {
    queue.async { [weak self] in
      guard let self, let db = self.open() else {
        completion?()
        return
      }
      self.exec(db, "DELETE FROM fix")
      // Only gives bytes back because `auto_vacuum=INCREMENTAL` was set before
      // the table existed — see `open()`. Without that this deletes rows and
      // leaves the file exactly as large as it was.
      self.exec(db, "PRAGMA incremental_vacuum")
      completion?()
    }
  }

  // MARK: - storage

  private func open() -> OpaquePointer? {
    if let db { return db }
    guard let path = Self.path() else { return nil }
    var handle: OpaquePointer?
    guard sqlite3_open_v2(
      path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil
    ) == SQLITE_OK else {
      sqlite3_close(handle)
      return nil
    }
    // Explicit, not inherited. The default protection class would let these
    // writes work today and stop working the day someone raises the app's
    // default to `complete` — and every one of these writes happens with the
    // screen off, which is exactly when that class denies access.
    try? FileManager.default.setAttributes(
      [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
      ofItemAtPath: path)

    // Before the table exists: setting it afterwards is a no-op until a full
    // VACUUM, and without it the file only ever grows — deleting rows would
    // free pages inside the file and never give the bytes back to the budget.
    exec(handle, "PRAGMA auto_vacuum=INCREMENTAL")
    exec(handle, "PRAGMA journal_mode=WAL")
    // Durability is worth less here than surviving the wake window: a fix lost
    // to a power cut is one point on a track, while a blocked fsync inside a
    // ten-second background window can cost the report as well.
    exec(handle, "PRAGMA synchronous=NORMAL")
    exec(handle, """
      CREATE TABLE IF NOT EXISTS fix (
        id  INTEGER PRIMARY KEY,
        t   INTEGER NOT NULL,
        lat INTEGER NOT NULL,
        lng INTEGER NOT NULL
      )
      """)
    db = handle
    return handle
  }

  private static func path() -> String? {
    // Application Support, beside the app's other databases, and excluded from
    // backups: a movement history is regenerable and does not belong in a
    // restore of a different device.
    guard var url = try? FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true)
    else { return nil }
    url.appendPathComponent("location_track.db")
    var resource = URLResourceValues()
    resource.isExcludedFromBackup = true
    var mutable = url
    try? mutable.setResourceValues(resource)
    return url.path
  }

  private func exec(_ db: OpaquePointer?, _ sql: String) {
    sqlite3_exec(db, sql, nil, nil, nil)
  }

  private func lastRowId(_ db: OpaquePointer) -> Int64 {
    scalar(db, "SELECT IFNULL(MAX(id), 0) FROM fix") ?? 0
  }

  /// The absolute position of the last row, rebuilt from its anchor forward.
  ///
  /// Walking the group is bounded by [anchorEvery], so this is at most 64 rows
  /// of arithmetic — cheaper than keeping a cached copy that a second process
  /// or a crash could leave stale.
  private func lastAbsolute(_ db: OpaquePointer) -> (t: Int64, lat: Int64, lng: Int64)? {
    let last = lastRowId(db)
    guard last > 0 else { return nil }
    let anchor = last - (last % Self.anchorEvery)
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(
      db, "SELECT id, t, lat, lng FROM fix WHERE id >= ? ORDER BY id", -1, &statement, nil
    ) == SQLITE_OK else { return nil }
    defer { sqlite3_finalize(statement) }
    sqlite3_bind_int64(statement, 1, anchor)

    var current: (t: Int64, lat: Int64, lng: Int64)?
    while sqlite3_step(statement) == SQLITE_ROW {
      let id = sqlite3_column_int64(statement, 0)
      let t = sqlite3_column_int64(statement, 1)
      let lat = sqlite3_column_int64(statement, 2)
      let lng = sqlite3_column_int64(statement, 3)
      if id % Self.anchorEvery == 0 || current == nil {
        current = (t, lat, lng)
      } else if let previous = current {
        current = (previous.t + t, previous.lat + lat, previous.lng + lng)
      }
    }
    return current
  }

  private func insert(_ db: OpaquePointer, rowid: Int64, t: Int64, lat: Int64, lng: Int64) {
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(
      db, "INSERT INTO fix (id, t, lat, lng) VALUES (?, ?, ?, ?)", -1, &statement, nil
    ) == SQLITE_OK else { return }
    defer { sqlite3_finalize(statement) }
    sqlite3_bind_int64(statement, 1, rowid)
    sqlite3_bind_int64(statement, 2, t)
    sqlite3_bind_int64(statement, 3, lat)
    sqlite3_bind_int64(statement, 4, lng)
    sqlite3_step(statement)
  }

  private func scalar(_ db: OpaquePointer, _ sql: String) -> Int64? {
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
    defer { sqlite3_finalize(statement) }
    return sqlite3_step(statement) == SQLITE_ROW ? sqlite3_column_int64(statement, 0) : nil
  }

  /// Drops the oldest anchor groups until the file is back inside its budget.
  ///
  /// Whole groups, never single rows: a delta row is meaningless without the
  /// anchor it counts from, so removing one row from the middle would shift
  /// every position after it without any way to notice.
  private func evictIfNeeded(_ db: OpaquePointer) {
    let last = lastRowId(db)
    guard last % Self.checkEvery == 0 else { return }
    guard let pageSize = scalar(db, "PRAGMA page_size"),
          let pageCount = scalar(db, "PRAGMA page_count")
    else { return }
    var bytes = pageSize * pageCount
    guard bytes > Self.budgetBytes else { return }

    // Free about a tenth of the budget at a time. Trimming to exactly the limit
    // would put the next fix straight back over it, and the VACUUM below is the
    // expensive part of this whole path.
    let target = Self.budgetBytes - Self.budgetBytes / 10
    var oldest = scalar(db, "SELECT IFNULL(MIN(id), 0) FROM fix") ?? 0
    while bytes > target, oldest > 0 {
      let boundary = oldest + Self.anchorEvery - (oldest % Self.anchorEvery)
      exec(db, "DELETE FROM fix WHERE id < \(boundary)")
      exec(db, "PRAGMA incremental_vacuum")
      guard let count = scalar(db, "PRAGMA page_count") else { break }
      bytes = pageSize * count
      guard let next = scalar(db, "SELECT IFNULL(MIN(id), 0) FROM fix"), next > oldest else { break }
      oldest = next
    }
  }
}
