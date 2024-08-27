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
