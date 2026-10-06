import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the settings groups cover every alert family', () {
    expect(NotificationChannels.groups.map((g) => g.channelGroupKey), [
      'group_eew',
      'group_eq',
      'group_info',
      'group_tsunami',
      'group_mesh',
      'group_other',
    ]);
  });
}
