import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:dpip/global.dart';
import 'package:dpip/util/log.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> fcmInit() async {
  await Firebase.initializeApp();
  await AwesomeNotificationsFcm().initialize(
    onFcmTokenHandle: onFcmTokenHandle,
    onNativeTokenHandle: onNativeTokenHandle,
    onFcmSilentDataHandle: onFcmSilentDataHandle,
    licenseKeys: [
      "2024-08-26==N0LtVWu49ox9yV8eaDrh8rGyji/iKzLaB6anluLFIPESM/rUtf0OTUDyExMB+hp8YqnfA9UMcwvT5i5lTcsB73WKbh2+cYbYwtSZoxjuSUUbNxzhnlH2uiD7CNYvtniORC69TStgEfXnYZ1dEfWe5p6Nwi4wDS7vTfyTOH2NqCW+5293ypcu6+7se2PxLGOF1s8YKbM3HU8nYk8juChbFNoxX/Y0pHOH+MvXi070o1+3SPL98BS9bPQQ0e9a9MgYpxRqthP/mT1Yx2AX4+d+Qb6NNiz8ub+rl1HhZc7vmy5bntJSwcculDhXG3YOP3uXeYYyc2L+NKqkHPYpflblOg=="
    ],
    debug: true,
  );
  await AwesomeNotificationsFcm().requestFirebaseAppToken();
}

Future<void> onFcmTokenHandle(String token) async {
  Global.preference.setString("fcm-token", token);
}

Future<void> onNativeTokenHandle(String token) async {
  TalkerManager.instance.info('FCM Token:"$token"');
  Global.preference.setString("fcm-token", token);
}

Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {
  Map<String, dynamic> data = silentData.data!.cast<String, dynamic>();

  if (silentData.createdLifeCycle == NotificationLifeCycle.AppKilled) {
    String channelKey = data['channel'] ?? 'other';
    data['content'] = {
      'id': int.parse(data['id'] ?? '0'),
      'channelKey': channelKey,
      'title': data['title'],
      'body': data['body'],
      'notificationLayout': NotificationLayout.Default.name,
    };
    await AwesomeNotifications().createNotificationFromJsonData(data);
  } else {
    await showNotify(data);
  }
  return Future.value();
}

Future<void> showNotify(Map<String, dynamic> data) async {
  String channelKey = data['channel'] ?? 'other';

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: int.parse(data['id'] ?? '0'),
      channelKey: channelKey,
      title: data['title'],
      body: data['body'],
      notificationLayout: NotificationLayout.Default,
    ),
  );
}
