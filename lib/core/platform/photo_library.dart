import 'dart:typed_data';

import 'package:dpip/core/logging/log.dart';
import 'package:gal/gal.dart';

/// How a save-to-photo-library attempt ended — the only three shapes the UI
/// can say something different about.
enum PhotoSaveOutcome {
  /// The image is in the system photo library.
  saved,

  /// The user or the OS refused photo-library access.
  permissionDenied,

  /// Anything else: no space, bytes the platform cannot decode, a native
  /// failure.
  failed,
}

/// Writes image bytes into the system photo library (相簿).
///
/// `gal` is wrapped here rather than called from the report page so the page
/// has no plugin dependency: this file owns the permission dance (ask once,
/// report a refusal as [PhotoSaveOutcome.permissionDenied] instead of an
/// exception) and the [GalException] → [PhotoSaveOutcome] mapping, and a test
/// can stub the plugin's `gal` method channel.
abstract final class PhotoLibrary {
  const PhotoLibrary._();

  /// Saves [bytes] as an image named [name].
  ///
  /// [name] carries no extension: the native side derives one from the bytes
  /// themselves (Android guesses the format, iOS hands the name to Photos).
  static Future<PhotoSaveOutcome> saveImage(
    Uint8List bytes, {
    required String name,
  }) async {
    try {
      // `putImageBytes` asks for access on its own, but it throws away the
      // answer and lets the native call fail with ACCESS_DENIED instead. Asking
      // first turns a refusal into the outcome the UI can explain, and when the
      // permission is already granted nothing is shown to the user.
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        return PhotoSaveOutcome.permissionDenied;
      }
      await Gal.putImageBytes(bytes, name: name);
      return PhotoSaveOutcome.saved;
    } on GalException catch (error) {
      Log.error('photo library save failed', error, error.stackTrace);
      return error.type == GalExceptionType.accessDenied
          ? PhotoSaveOutcome.permissionDenied
          : PhotoSaveOutcome.failed;
    }
  }
}
