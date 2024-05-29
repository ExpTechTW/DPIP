import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void setupAndroidNotificationChannels() {
  AndroidFlutterLocalNotificationsPlugin plugin = AndroidFlutterLocalNotificationsPlugin();

  const earthquake = AndroidNotificationChannelGroup("earthquake", "地震", description: "地震相關通知");

  const report = AndroidNotificationChannel(
    "report",
    "地震報告",
    groupId: "earthquake",
    description: "地震發生後接收的地震報告。",
    importance: Importance.low,
    enableVibration: false,
  );

  const intensity = AndroidNotificationChannel(
    "intensity",
    "震度速報",
    groupId: "earthquake",
    description: "地震發生後接收的各地地震的最大震度通知。",
    importance: Importance.high,
  );

  const eew = AndroidNotificationChannel(
    "eew",
    "地震速報",
    groupId: "earthquake",
    description: "在地震發生時接收中央氣象署發布的強震即時警報。",
    importance: Importance.max,
    enableLights: true,
    enableVibration: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound("eew_alert.wav"),
  );

  const monitor = AndroidNotificationChannel(
    "monitor",
    "強震監視器",
    groupId: "earthquake",
    description: "當 TREM 在全臺部署的測站中，離所在地最近的測站觸發時接收的通知。",
    importance: Importance.high,
  );

  plugin.createNotificationChannelGroup(earthquake).catchError((_) {});

  plugin.createNotificationChannel(report).catchError((_) {});
  plugin.createNotificationChannel(intensity).catchError((_) {});
  plugin.createNotificationChannel(eew).catchError((_) {});
  plugin.createNotificationChannel(monitor).catchError((_) {});
}
