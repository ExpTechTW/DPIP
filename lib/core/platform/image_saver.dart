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
  /// so the UI can choose the appropriate recovery when the library refuses.
  Future<Result<void>> ensurePermission();
}

extension GuardedImageSave on ImageSaver {
  /// Saves only while the caller still owns the image. A null result means
  /// eligibility was lost before the write was dispatched.
  Future<Result<void>?> saveToGalleryIfCurrent({
    required Uint8List bytes,
    required String fileName,
    required bool Function() isCurrent,
    String mimeType = 'image/png',
  }) async {
    if (!isCurrent()) return null;
    if (this case final _MethodChannelImageSaver saver) {
      return saver._saveToGallery(bytes, fileName, mimeType, isCurrent);
    }
    return saveToGallery(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }
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
  bool _writing = false;

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

    try {
      final status = await _channel.invokeMethod<String>('status');
      if (status == 'granted') return const Ok(null);
      return await _checkPermission(status);
    } on MissingPluginException {
      return _unavailable();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Checking gallery access failed');
      return Err(_failure(ImageSaveFailureReason.failed));
    }
  }

  Future<Result<void>> _checkPermission(String? status) async {
    if (status == 'notDetermined') {
      status = await _channel.invokeMethod<String>('request');
    }
    return switch (status) {
      'granted' => const Ok(null),
      'denied' => Err(
        _failure(ImageSaveFailureReason.permissionSettingsRequired),
      ),
      'restricted' => Err(
        _failure(ImageSaveFailureReason.permissionRestricted),
      ),
      'notDetermined' => Err(_failure(ImageSaveFailureReason.permissionDenied)),
      _ => _unavailable(),
    };
  }

  @override
  Future<Result<void>> saveToGallery({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/png',
  }) async => (await _saveToGallery(bytes, fileName, mimeType))!;

  Future<Result<void>?> _saveToGallery(
    Uint8List bytes,
    String fileName,
    String mimeType, [
    bool Function()? isCurrent,
  ]) async {
    if (!_isSupportedPlatform) return _unavailable();
    if (_writing) return Err(_failure(ImageSaveFailureReason.failed));

    final permission = await ensurePermission();
    // Permission prompts can outlive the dialog. Check immediately before
    // the irreversible native call, without an async gap after this guard.
    if (isCurrent?.call() == false) return null;
    if (permission case Err(:final failure)) return Err(failure);
    if (_writing) return Err(_failure(ImageSaveFailureReason.failed));

    _writing = true;
    try {
      return await _invoke(bytes, fileName, mimeType);
    } finally {
      _writing = false;
    }
  }

  static Result<void> _unavailable() =>
      Err(_failure(ImageSaveFailureReason.unavailable));

  static ImageSaveFailure _failure(ImageSaveFailureReason reason) =>
      ImageSaveFailure(reason, 'Gallery save failed: ${reason.name}');

  ImageSaveFailureReason get _nativeDenial =>
      ImageSaveFailureReason.permissionSettingsRequired;

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
      return _unavailable();
    } on PlatformException catch (error) {
      final reason = switch (error.code) {
        'permission_denied' => _nativeDenial,
        'permission_restricted' => ImageSaveFailureReason.permissionRestricted,
        'unsupported' => ImageSaveFailureReason.unavailable,
        _ => ImageSaveFailureReason.failed,
      };
      Log.warning('Saving an image failed: ${reason.name} (${error.code})');
      return Err(_failure(reason));
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Saving an image failed unexpectedly');
      return Err(_failure(ImageSaveFailureReason.failed));
    }
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
  Future<Result<void>> _checkPermission(String? nativeStatus) async {
    // Only the API 26–28 path returns denied. An absent or unknown reply
    // cannot establish that the platform needs a storage permission.
    if (nativeStatus != 'denied') {
      return _MethodChannelImageSaver._unavailable();
    }

    var status = await _storageStatus();
    if (status.isDenied) status = await _requestStorage();
    if (status.isGranted || status.isLimited) return const Ok(null);

    final reason = status.isPermanentlyDenied
        ? ImageSaveFailureReason.permissionSettingsRequired
        : status.isRestricted
        ? ImageSaveFailureReason.permissionRestricted
        : ImageSaveFailureReason.permissionDenied;
    return Err(_MethodChannelImageSaver._failure(reason));
  }

  @override
  ImageSaveFailureReason get _nativeDenial =>
      ImageSaveFailureReason.permissionDenied;
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
