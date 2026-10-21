import Flutter
import Foundation
import Security

/// Secrets the user hands the app — today the AI chat's API key.
///
/// One Keychain generic-password item per secret, readable after the first
/// unlock and **only on this device**: `ThisDeviceOnly` keeps the item out of
/// any backup restored onto another phone, which is what lets the app say the
/// key never leaves this one.
///
/// Errors report the `OSStatus` only, never the value.
public class SecretStorePlugin: NSObject, FlutterPlugin {
  static let service = "com.exptech.dpip.secret-store"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.exptech.dpip/secret_store",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(SecretStorePlugin(), channel: channel)
  }

  public func handle(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    guard let args = call.arguments as? [String: Any],
      let key = args["key"] as? String, !key.isEmpty
    else {
      result(FlutterError(code: "bad_key", message: "missing key", details: nil))
      return
    }
    switch call.method {
    case "read":
      switch SecretStorePlugin.read(key) {
      case .success(let value): result(value)
      case .failure(let status): result(SecretStorePlugin.error(status))
      }
    case "write":
      guard let value = args["value"] as? String else {
        result(FlutterError(code: "bad_value", message: "missing value", details: nil))
        return
      }
      let status = SecretStorePlugin.write(key, value)
      result(status == errSecSuccess ? nil : SecretStorePlugin.error(status))
    case "delete":
      let status = SecretStorePlugin.delete(key)
      result(status == errSecSuccess ? nil : SecretStorePlugin.error(status))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func base(_ key: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
    ]
  }

  /// The saved value, nil when there is none.
  static func read(_ key: String) -> Result<String?, OSStatusError> {
    var query = base(key)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    switch status {
    case errSecSuccess:
      guard let data = item as? Data else { return .success(nil) }
      return .success(String(data: data, encoding: .utf8))
    case errSecItemNotFound:
      return .success(nil)
    default:
      return .failure(OSStatusError(status: status))
    }
  }

  /// Replaces any earlier value. Delete-then-add rather than update, so the
  /// accessibility class is always the one set here, even for an item an
  /// older build might have written differently.
  static func write(_ key: String, _ value: String) -> OSStatus {
    _ = delete(key)
    var item = base(key)
    item[kSecValueData as String] = Data(value.utf8)
    item[kSecAttrAccessible as String] =
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(item as CFDictionary, nil)
  }

  /// Removes the value; absent already counts as success.
  static func delete(_ key: String) -> OSStatus {
    let status = SecItemDelete(base(key) as CFDictionary)
    return status == errSecItemNotFound ? errSecSuccess : status
  }

  static func error(_ status: OSStatus) -> FlutterError {
    FlutterError(code: "keychain", message: "OSStatus \(status)", details: nil)
  }

  static func error(_ failure: OSStatusError) -> FlutterError {
    error(failure.status)
  }
}

struct OSStatusError: Error {
  let status: OSStatus
}
