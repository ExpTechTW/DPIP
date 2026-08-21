import 'package:dpip/core/logging/log.dart';
import 'package:flutter/foundation.dart';

/// Temporary tracing for the retained map lifecycle.
///
/// Flip this one flag off after the second-entry freeze is diagnosed. Keeping
/// it in Dart makes a hot reload enough to enable/disable the trace; no native
/// rebuild or simulator restart is required.
const bool mapTraceEnabled = false;

int _nextTraceId = 0;
int _nextTraceLine = 0;

int nextMapTraceId() => ++_nextTraceId;

String mapTraceObject(Object? object) =>
    object == null ? 'none' : identityHashCode(object).toRadixString(16);

void mapTrace(String scope, String message) {
  if (!kDebugMode || !mapTraceEnabled) return;
  Log.debug('MAP TRACE #${++_nextTraceLine} $scope $message');
}
