/// Secrets the app holds for the user — today one: the API key the user gives
/// the AI chat for their own AI service.
///
/// A platform channel rather than a package, like the rest of `core/platform/`,
/// and deliberately not [SettingsStore]: settings live in `dpip.db` in
/// application-support, which iOS copies into iCloud and device backups. A key
/// the explanation page says never leaves this phone cannot live there.
///
/// - **iOS:** a Keychain generic-password item with
///   `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, so a backup restored
///   onto another device does not carry it.
/// - **Android:** an AES-GCM key generated inside the Android Keystore (it
///   never leaves the secure hardware); only the ciphertext is written, to
///   `noBackupFilesDir`. The manifest already sets `allowBackup="false"`.
///
/// Reading a secret the platform can no longer decrypt (a Keystore key wiped
/// by a lock-screen reset) answers null, as if it had never been saved — the
/// user enters it again; nothing else can be done with it.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// The secrets the app may store. An enum, not a `String`, for the same
/// reason [SettingKey] is typed: an ad-hoc name cannot reach the store.
///
/// **Never change a [name]** — it is the storage address of a saved secret.
enum SecretKey {
  /// The API key for the AI chat's AI service.
  aiApiKey('ai.apiKey');

  const SecretKey(this.name);

  final String name;
}

/// Reads and writes [SecretKey]s.
abstract class SecretStore {
  /// The saved value, or null when there is none (or it cannot be read).
  Future<String?> read(SecretKey key);

  /// Saves [value], replacing any earlier one. Throws when the platform
  /// refuses, so the caller can say the key was not saved.
  Future<void> write(SecretKey key, String value);

  /// Removes the value; a no-op when there is none.
  Future<void> delete(SecretKey key);
}

/// [SecretStore] backed by the platform's own key storage.
class PlatformSecretStore implements SecretStore {
  PlatformSecretStore({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.exptech.dpip/secret_store');

  final MethodChannel _channel;

  @override
  Future<String?> read(SecretKey key) async {
    try {
      return await _channel.invokeMethod<String>('read', {'key': key.name});
    } on PlatformException catch (error) {
      // The message names the failing step, never the value.
      Log.warning('secret store: read ${key.name} failed (${error.code})');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> write(SecretKey key, String value) async {
    try {
      await _channel.invokeMethod<void>('write', {
        'key': key.name,
        'value': value,
      });
    } on PlatformException catch (error) {
      // Code and message name the failing step (an OSStatus, a Keystore
      // exception's class), never the value.
      Log.warning(
        'secret store: write ${key.name} failed '
        '(${error.code}: ${error.message})',
      );
      rethrow;
    } on MissingPluginException {
      // A hot restart onto a build without this channel; only a full rebuild
      // brings the platform side in.
      Log.warning('secret store: write ${key.name} failed (no platform side)');
      rethrow;
    }
  }

  @override
  Future<void> delete(SecretKey key) async {
    try {
      await _channel.invokeMethod<void>('delete', {'key': key.name});
    } on PlatformException catch (error) {
      Log.warning('secret store: delete ${key.name} failed (${error.code})');
    } on MissingPluginException {
      // Nothing was ever stored where there is no store.
    }
  }
}
