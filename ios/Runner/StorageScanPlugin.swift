import Flutter
import Foundation
import UIKit

/// App-owned channel that scans the sandbox for disk usage, bounds the system
/// HTTP cache, and clears it.
///
/// iOS Settings reports the whole sandbox ("文件與資料"), which is far larger
/// than the ETag cache budget (150 MB of body blobs): the SQLite file carries
/// page/free-space overhead on top of the bodies, and the system URL cache
/// (NSURLCache, shared by every NSURLSession — Dio included) can quietly hold
/// hundreds of MB of disk. The Debug page needs real numbers, so `scan`
/// measures every top-level sandbox directory and the biggest files.
public class StorageScanPlugin: NSObject, FlutterPlugin {
  /// Upper bound for the system disk HTTP cache. URLs the app controls already
  /// go through its own SQLite cache; this only caps what NSURLCache keeps
  /// behind the app's back so total usage cannot grow without bound.
  static let systemDiskCacheBytes: Int = 64 * 1024 * 1024

  /// Files above this size are reported individually by `scan`.
  static let topFileFloor: Int64 = 512 * 1024

  /// Hard cap on visited files per directory so a pathological tree can't hang
  /// the channel.
  static let visitCap = 100_000

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/storage_scan",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(StorageScanPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scan":
      result(scan())
    case "configure":
      // Bound the shared URL cache once at startup (see class doc). Memory is
      // capped too — the default can be many tens of MB on a big device.
      URLCache.shared.memoryCapacity = 16 * 1024 * 1024
      URLCache.shared.diskCapacity = StorageScanPlugin.systemDiskCacheBytes
      result(nil)
    case "clearSystemHttpCache":
      URLCache.shared.removeAllCachedResponses()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// One top-level sandbox directory: its path and total on-disk size.
  private func dirEntry(_ url: URL, bytes: Int64) -> [String: Any] {
    ["path": url.path, "bytes": bytes]
  }

  private func scan() -> [String: Any] {
    let fileManager = FileManager.default
    let dirs = [
      fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
      fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
      fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
      URL(fileURLWithPath: NSTemporaryDirectory()),
    ].compactMap { $0 }

    var topFiles = [(path: String, bytes: Int64)]()
    var total: Int64 = 0
    var dirEntries = [[String: Any]]()
    for dir in dirs {
      let result = walk(dir)
      dirEntries.append(dirEntry(dir, bytes: result.bytes))
      total += result.bytes
      topFiles.append(contentsOf: result.top)
    }
    topFiles.sort { $0.bytes > $1.bytes }
    let files = topFiles.prefix(30).map {
      ["path": $0.path, "bytes": $0.bytes]
    }
    return [
      "totalBytes": total,
      "dirs": dirEntries,
      "files": files,
    ]
  }

  /// One pass over [root]: total file bytes plus every file above
  /// [StorageScanPlugin.topFileFloor].
  private func walk(_ root: URL) -> (bytes: Int64, top: [(path: String, bytes: Int64)]) {
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(
      at: root,
      includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
      options: [.skipsHiddenFiles]
    ) else { return (0, []) }
    var bytes: Int64 = 0
    var top = [(path: String, bytes: Int64)]()
    var visited = 0
    for case let url as URL in enumerator {
      visited += 1
      if visited > StorageScanPlugin.visitCap { break }
      guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey]) else {
        continue
      }
      if values.isDirectory == true { continue }
      let fileBytes = Int64(values.fileSize ?? 0)
      guard fileBytes > 0 else { continue }
      bytes += fileBytes
      if fileBytes >= StorageScanPlugin.topFileFloor {
        top.append((url.path, fileBytes))
      }
    }
    return (bytes, top)
  }
}
