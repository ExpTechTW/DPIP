import 'dart:io';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Hands encoded image bytes to the platform's own photo library.
///
/// The image never crosses this boundary as a path or a widget: the caller owns
/// the bytes it already has, and the platform owns where a photo lives. Android
/// writes through MediaStore (or the public Pictures directory on API 26–28),
/// iOS through `PHPhotoLibrary`, so a saved report appears in the gallery like
/// any other picture and needs no storage permission from the app's own files.
abstract interface class ImageSaver {
  /// Saves [bytes] as a photo named [fileName].
  ///
  /// [mimeType] is what the platform records for the file; it must match the
  /// bytes, or the gallery shows a broken entry rather than the image.
  ///
  /// Asks for the photo-library grant first (see [ensurePermission]); a save
  /// never begins without it.
  Future<Result<void>> saveToGallery({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/png',
  });

  /// Obtains the grant [saveToGallery] needs, prompting when the OS still can.
  ///
  /// Returned separately so a caller can check before fetching anything, and
  /// so the UI can tell "the library refused" (Settings is the only way
  /// forward) apart from a failed write.
  Future<Result<void>> ensurePermission();
}

/// The one MethodChannel protocol both platforms speak.
///
/// iOS's `ImageSaverPlugin` and Android's `ImageSaverChannel` implement the same
/// method name, argument keys and error codes, so the platform differences stay
/// on their own side and the decoding is written once here.
///
/// `base` so it can only be extended in this library: the subclasses are the
/// complete set of platforms this app ships.
base class _MethodChannelImageSaver implements ImageSaver {
  _MethodChannelImageSaver(this._channel, this._isSupportedPlatform);

  final MethodChannel _channel;
  final bool _isSupportedPlatform;

  /// The permission this save needs, asked **before** anything is written.
  ///
  /// A save that starts without it is either a system dialog the user sees
  /// after the fact or a silent failure; asking first is what lets the UI say
  /// "the photo library refused" and offer Settings instead of a vague error.
  /// The platform's own check is still the final word — `save` keeps its
  /// refusal path for the race where the grant is revoked mid-write.
  @override
  Future<Result<void>> ensurePermission() async {
    if (!_isSupportedPlatform) return _unavailable();

    final status = await _channelString('status');
    switch (status) {
      case 'granted':
        return const Ok(null);
      case 'denied':
        // iOS never asks twice, so a refusal here is already final.
        return _permissionDenied();
      case 'notDetermined':
        return await _channelString('request') == 'granted'
            ? const Ok(null)
            : _permissionDenied();
      default:
        // No answer — an engine that never registered the channel, or a future
        // platform without a status method. `save` still reports unavailable.
        return const Ok(null);
    }
  }

  @override
  Future<Result<void>> saveToGallery({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/png',
  }) async {
    if (!_isSupportedPlatform) return _unavailable();

    final permission = await ensurePermission();
    if (permission case Err(:final failure)) return Err(failure);

    return _invoke(bytes, fileName, mimeType);
  }

  Future<String?> _channelString(String method) async {
    try {
      return await _channel.invokeMethod<String>(method);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'image saver $method');
      return null;
    }
  }

  static Result<void> _unavailable() => const Err(
    ImageSaveFailure(
      ImageSaveFailureReason.unavailable,
      'Saving images is unavailable on this platform.',
    ),
  );

  static Result<void> _permissionDenied() => const Err(
    ImageSaveFailure(
      ImageSaveFailureReason.permissionDenied,
      'The photo library refused the image.',
    ),
  );

  Future<Result<void>> _invoke(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      await _channel.invokeMethod<void>('save', {
        'bytes': bytes,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      return const Ok(null);
    } on MissingPluginException {
      return const Err(
        ImageSaveFailure(
          ImageSaveFailureReason.unavailable,
          'Saving images is unavailable on this platform.',
        ),
      );
    } on PlatformException catch (error) {
      final failure = _saveFailure(error);
      Log.warning('Saving an image failed: ${failure.reason.name}');
      return Err(failure);
    } on Object {
      Log.warning('Saving an image failed unexpectedly');
      return const Err(
        ImageSaveFailure(
          ImageSaveFailureReason.failed,
          'The image could not be saved.',
        ),
      );
    }
  }

  static ImageSaveFailure _saveFailure(PlatformException error) {
    return switch (error.code) {
      'permission_denied' => const ImageSaveFailure(
        ImageSaveFailureReason.permissionDenied,
        'The photo library refused the image.',
      ),
      'unsupported' => const ImageSaveFailure(
        ImageSaveFailureReason.unavailable,
        'Saving images is unavailable on this platform.',
      ),
      _ => const ImageSaveFailure(
        ImageSaveFailureReason.failed,
        'The image could not be saved.',
      ),
    };
  }
}

/// Android implementation — MediaStore, with the legacy public-directory write
/// on API 26–28 behind `WRITE_EXTERNAL_STORAGE`.
final class AndroidImageSaver extends _MethodChannelImageSaver {
  AndroidImageSaver({
    MethodChannel? channel,
    bool? isSupportedPlatform,
    Future<ph.PermissionStatus> Function()? storageStatus,
    Future<ph.PermissionStatus> Function()? requestStorage,
  }) : _storageStatus = storageStatus ?? (() => ph.Permission.storage.status),
       _requestStorage =
           requestStorage ?? (() => ph.Permission.storage.request()),
       super(
         channel ?? const MethodChannel('com.exptech.dpip/image_saver'),
         isSupportedPlatform ?? Platform.isAndroid,
       );

  final Future<ph.PermissionStatus> Function() _storageStatus;
  final Future<ph.PermissionStatus> Function() _requestStorage;

  /// Asks only where Android actually needs a grant.
  ///
  /// The native side answers `granted` for API 29+, where MediaStore needs no
  /// permission at all — asking there would be a prompt nobody can grant, and
  /// `permission_handler` reports it permanently denied because the manifest
  /// caps the declaration at API 28.
  @override
  Future<Result<void>> ensurePermission() async {
    if (!_isSupportedPlatform) return super.ensurePermission();

    if (await _channelString('status') == 'granted') return const Ok(null);

    var status = await _storageStatus();
    if (status.isGranted || status.isLimited) return const Ok(null);
    if (status.isPermanentlyDenied) {
      return _MethodChannelImageSaver._permissionDenied();
    }

    status = await _requestStorage();
    if (status.isGranted || status.isLimited) return const Ok(null);
    return _MethodChannelImageSaver._permissionDenied();
  }
}

/// iOS implementation — `PHPhotoLibrary` add-only access.
final class IosImageSaver extends _MethodChannelImageSaver {
  IosImageSaver({MethodChannel? channel, bool? isSupportedPlatform})
    : super(
        channel ?? const MethodChannel('com.exptech.dpip/image_saver'),
        isSupportedPlatform ?? Platform.isIOS,
      );
}

/// The saver for a platform with no photo library.
///
/// It exists so callers have no nullable saver and no `Platform` check of their
/// own; the failure is the same typed one iOS sees when the library refuses.
final class UnsupportedImageSaver implements ImageSaver {
  const UnsupportedImageSaver();

  @override
  Future<Result<void>> ensurePermission() async => const Err(
    ImageSaveFailure(
      ImageSaveFailureReason.unavailable,
      'Saving images is unavailable on this platform.',
    ),
  );

  @override
  Future<Result<void>> saveToGallery({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/png',
  }) async => const Err(
    ImageSaveFailure(
      ImageSaveFailureReason.unavailable,
      'Saving images is unavailable on this platform.',
    ),
  );
}

/// The saver for the platform this build is running on.
///
/// [isIOS] and [isAndroid] exist so the selection itself can be tested: `dart:io`
/// `Platform` answers for the machine the test runs on, which is neither of the
/// two platforms this app ships, so a test could otherwise only ever see the
/// unsupported saver. Production passes neither.
ImageSaver createImageSaver({
  bool? isIOS,
  bool? isAndroid,
  Future<ph.PermissionStatus> Function()? storageStatus,
  Future<ph.PermissionStatus> Function()? requestStorage,
}) {
  final ios = isIOS ?? Platform.isIOS;
  final android = isAndroid ?? Platform.isAndroid;
  if (ios) return IosImageSaver();
  if (android) {
    return AndroidImageSaver(
      storageStatus: storageStatus,
      requestStorage: requestStorage,
    );
  }
  return const UnsupportedImageSaver();
}
