import Security
import XCTest

@testable import Runner

final class SecretStorePluginTests: XCTestCase {
  private var key: String!

  override func setUpWithError() throws {
    try super.setUpWithError()
    key = "test.\(UUID().uuidString)"
    // tool/dev/test_ios.sh (and so CI) builds with CODE_SIGNING_ALLOWED=NO,
    // and an unsigned test host has no keychain entitlement: every call then
    // fails with errSecMissingEntitlement, which says nothing about this
    // code. A signed run (`tool/dev/test_ios.sh CODE_SIGNING_ALLOWED=YES
    // CODE_SIGN_IDENTITY=-`) exercises it for real.
    let probe = SecretStorePlugin.write(key, "probe")
    if probe == errSecMissingEntitlement {
      throw XCTSkip("Keychain needs a signed test host (OSStatus \(probe))")
    }
    _ = SecretStorePlugin.delete(key)
  }

  override func tearDown() {
    _ = SecretStorePlugin.delete(key)
    key = nil
    super.tearDown()
  }

  func testReadOfAnAbsentSecretIsNil() throws {
    XCTAssertNil(try SecretStorePlugin.read(key).get())
  }

  func testWriteThenReadReturnsTheValue() throws {
    XCTAssertEqual(SecretStorePlugin.write(key, "sk-first"), errSecSuccess)
    XCTAssertEqual(try SecretStorePlugin.read(key).get(), "sk-first")
  }

  func testWriteReplacesTheEarlierValue() throws {
    XCTAssertEqual(SecretStorePlugin.write(key, "sk-first"), errSecSuccess)
    XCTAssertEqual(SecretStorePlugin.write(key, "sk-second"), errSecSuccess)
    XCTAssertEqual(try SecretStorePlugin.read(key).get(), "sk-second")
  }

  func testDeleteRemovesTheValueAndAbsentDeleteSucceeds() throws {
    XCTAssertEqual(SecretStorePlugin.write(key, "sk-first"), errSecSuccess)
    XCTAssertEqual(SecretStorePlugin.delete(key), errSecSuccess)
    XCTAssertNil(try SecretStorePlugin.read(key).get())
    XCTAssertEqual(SecretStorePlugin.delete(key), errSecSuccess)
  }

  /// The promise the explanation page makes: a backup restored onto another
  /// phone does not carry the key.
  func testTheItemIsBoundToThisDevice() throws {
    XCTAssertEqual(SecretStorePlugin.write(key, "sk-first"), errSecSuccess)
    var query = SecretStorePlugin.base(key)
    query[kSecReturnAttributes as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    XCTAssertEqual(SecItemCopyMatching(query as CFDictionary, &item), errSecSuccess)
    let attributes = try XCTUnwrap(item as? [String: Any])
    XCTAssertEqual(
      attributes[kSecAttrAccessible as String] as? String,
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
  }
}
