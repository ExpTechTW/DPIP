/// Saving an image asks for the photo-library grant **before** writing, then
/// hands the bytes to the platform and reports back a typed result.
///
/// The platform half (MediaStore, `PHPhotoLibrary`) needs a real device to
/// observe; what this pins is the boundary the UI depends on: the permission
/// gate, what crosses the channel, and how each error code is classified.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/image_saver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.exptech.dpip/image_saver');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  final bytes = Uint8List.fromList([1, 2, 3, 4]);

  ImageSaveFailure? failureOf(Result<void> result) {
    final failure = result.failureOrNull;
    expect(failure, isA<ImageSaveFailure>());
    return failure as ImageSaveFailure;
  }

  test('a platform with no photo library reports unavailable', () async {
    final result = await const UnsupportedImageSaver().saveToGallery(
      bytes: bytes,
      fileName: 'dpip-earthquake-1.png',
    );

    expect(failureOf(result)!.reason, ImageSaveFailureReason.unavailable);
    expect(
      failureOf(await const UnsupportedImageSaver().ensurePermission())!.reason,
      ImageSaveFailureReason.unavailable,
    );
  });

  group('iOS', () {
    test(
      'sends the bytes, the name and the type once the library agrees',
      () async {
        Map<String, Object?>? arguments;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'status') return 'granted';
          expect(call.method, 'save');
          // The binding hands the payload over as a plain Map; casting it to a
          // typed map here would throw inside the handler and fail the call.
          arguments = (call.arguments as Map).cast<String, Object?>();
          return null;
        });

        final result = await IosImageSaver(isSupportedPlatform: true)
            .saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-1.png');

        expect(result.isOk, isTrue);
        expect(arguments!['bytes'], equals(bytes));
        expect(arguments!['fileName'], 'dpip-earthquake-1.png');
        expect(arguments!['mimeType'], 'image/png');
      },
    );

    test('a refused library fails before anything is written', () async {
      var saved = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') return 'denied';
        if (call.method == 'save') saved = true;
        return null;
      });

      final result = await IosImageSaver(isSupportedPlatform: true)
          .saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-2.png');

      expect(
        failureOf(result)!.reason,
        ImageSaveFailureReason.permissionDenied,
      );
      expect(saved, isFalse, reason: 'a refused save must not write');
    });

    test('asks once when the library has never been asked', () async {
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        methods.add(call.method);
        if (call.method == 'status') return 'notDetermined';
        if (call.method == 'request') return 'granted';
        return null;
      });

      final result = await IosImageSaver(isSupportedPlatform: true)
          .saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-3.png');

      expect(result.isOk, isTrue);
      expect(methods, ['status', 'request', 'save']);
    });
  });

  group('Android', () {
    test('API 29+ needs no storage grant at all', () async {
      var asked = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') return 'granted';
        return null;
      });

      final result = await AndroidImageSaver(
        isSupportedPlatform: true,
        storageStatus: () async {
          asked++;
          return ph.PermissionStatus.denied;
        },
        requestStorage: () async {
          asked++;
          return ph.PermissionStatus.denied;
        },
      ).saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-4.png');

      expect(result.isOk, isTrue);
      expect(asked, 0, reason: 'MediaStore needs no permission');
    });

    test('API 26–28 asks for the legacy grant when it is missing', () async {
      final methods = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') return 'denied';
        methods.add(call.method);
        return null;
      });

      var requested = 0;
      final result = await AndroidImageSaver(
        isSupportedPlatform: true,
        storageStatus: () async => ph.PermissionStatus.denied,
        requestStorage: () async {
          requested++;
          return ph.PermissionStatus.granted;
        },
      ).saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-5.png');

      expect(requested, 1, reason: 'asked once before the save');
      expect(methods, ['save']);
      expect(result.isOk, isTrue);
    });

    test('a permanently refused grant fails without prompting', () async {
      var requested = 0;
      var saved = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') return 'denied';
        if (call.method == 'save') saved = true;
        return null;
      });

      final result = await AndroidImageSaver(
        isSupportedPlatform: true,
        storageStatus: () async => ph.PermissionStatus.permanentlyDenied,
        requestStorage: () async {
          requested++;
          return ph.PermissionStatus.permanentlyDenied;
        },
      ).saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-6.png');

      expect(
        requested,
        0,
        reason: 'a permanently denied grant cannot be asked',
      );
      expect(saved, isFalse);
      expect(
        failureOf(result)!.reason,
        ImageSaveFailureReason.permissionDenied,
      );
    });

    test('a grant the user refuses at the prompt is not retried', () async {
      var saved = false;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') return 'denied';
        if (call.method == 'save') saved = true;
        return null;
      });

      final result = await AndroidImageSaver(
        isSupportedPlatform: true,
        storageStatus: () async => ph.PermissionStatus.denied,
        requestStorage: () async => ph.PermissionStatus.denied,
      ).saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-7.png');

      expect(saved, isFalse);
      expect(
        failureOf(result)!.reason,
        ImageSaveFailureReason.permissionDenied,
      );
    });
  });

  test(
    'a write failure is reported as failed, not as a permission problem',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'status') return 'granted';
        throw PlatformException(code: 'save_failed');
      });

      final result = await IosImageSaver(isSupportedPlatform: true)
          .saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-8.png');

      expect(failureOf(result)!.reason, ImageSaveFailureReason.failed);
    },
  );

  test('a missing plugin is unavailable rather than a crash', () async {
    // No handler registered at all.
    final result = await IosImageSaver(isSupportedPlatform: true)
        .saveToGallery(bytes: bytes, fileName: 'dpip-earthquake-9.png');

    expect(failureOf(result)!.reason, ImageSaveFailureReason.unavailable);
  });

  test('createImageSaver picks the platform saver it is told', () {
    expect(
      createImageSaver(isIOS: true, isAndroid: false),
      isA<IosImageSaver>(),
    );
    expect(
      createImageSaver(isIOS: false, isAndroid: true),
      isA<AndroidImageSaver>(),
    );
    expect(
      createImageSaver(isIOS: false, isAndroid: false),
      isA<UnsupportedImageSaver>(),
    );
  });
}
