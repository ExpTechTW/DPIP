import 'package:dpip/features/bug_tracker/domain/bug_thread.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin and staff ids are recognised, everyone else is a user', () {
    expect(bugAuthorRole(bugTrackerAdminIds.first), BugAuthorRole.admin);
    expect(bugAuthorRole(bugTrackerStaffIds.first), BugAuthorRole.staff);
    expect(bugAuthorRole(1), BugAuthorRole.user);
  });

  test('loose strings and unix seconds survive a round trip', () {
    const loose = LooseString();
    expect(loose.fromJson(null), '');
    expect(loose.toJson('body'), 'body');

    const clock = UnixSecondsDateTime();
    final at = DateTime.utc(2026, 1, 1);
    expect(clock.fromJson(clock.toJson(at)), at);
  });
}
