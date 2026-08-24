/// Bug-tracker repository contract — read-only by design.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';

import 'dart:typed_data';

/// The reported-bug threads mirrored from the Discord tracker.
///
/// There is deliberately no way to create, reply, close or tag: the tracker is
/// a window for app users to see what has already been reported and what the
/// team said about it. Writing happens on Discord, where triage lives.
abstract class BugRepository {
  /// Every open thread, newest first as the source reports them.
  Future<Result<List<BugThread>>> threads();

  /// One thread with its full reply history.
  Future<Result<BugThreadDetail>> thread(int id);

  /// One avatar's bytes — fetched through the shared ETag/gzip stack.
  Future<Result<Uint8List>> avatar(String url);
}
