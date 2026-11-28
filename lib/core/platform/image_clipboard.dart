import 'package:flutter/services.dart';

const _channel = MethodChannel('com.exptech.dpip/image_saver');

/// Copies the already encoded PNG. Returns whether the app should acknowledge
/// success, since Android 13 and newer have their own clipboard confirmation.
Future<bool> copyPngToClipboard(Uint8List bytes) async =>
    (await _channel.invokeMethod<bool>('copyPng', bytes))!;
