/// Pulls lines that native code recorded before this isolate existed into [Log].
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Channel the Android and iOS buffers answer on.
const String nativeLogChannelName = 'com.exptech.dpip/native_log';

/// Reads the native buffer into [Log] and clears it as that same handoff.
///
/// The platform method is `take`: it reads the file and clears it only after
/// that read succeeds, then returns the batch. A failed call leaves the file
/// where it is, so the next launch can try again.
///
/// Each line keeps the timestamp stored on the native side. A tag is written
/// as `[tag] message`, the shape the rest of the log uses for a subsystem.
Future<void> importNativeLogs({MethodChannel? channel}) async {
  final source = channel ?? const MethodChannel(nativeLogChannelName);
  final List<Object?>? raw;
  try {
    raw = await source.invokeListMethod<Object?>('take');
  } on PlatformException {
    return;
  } on MissingPluginException {
    return;
  }
  if (raw == null) return;
  for (final item in raw) {
    _importEntry(item);
  }
}

void _importEntry(Object? item) {
  if (item is! Map<Object?, Object?>) return;
  final message = item['message'];
  final time = item['time'];
  if (message is! String || message.isEmpty || time is! num) return;
  final tag = item['tag'];
  final level = item['level'];
  final tagText = tag is String ? tag : '';
  final levelName = level is String && level.isNotEmpty ? level : 'info';
  final text = tagText.isEmpty ? message : '[$tagText] $message';
  Log.at(
    time: DateTime.fromMillisecondsSinceEpoch(time.toInt()),
    level: levelName,
    message: text,
  );
}
