import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

String? _pendingChannelKey;

Future<void> notifyInit() async {
  await AwesomeNotifications().initialize(
    'resource://drawable/ic_stat_name',
    [
      NotificationChannel(
        channelGroupKey: 'group_eew',
        channelKey: 'eew_alert-important-v2',
        channelName: '緊急地震速報(重大)',
        channelDescription: '最大震度 5 弱以上以及所在地(鄉鎮)預估震度 4 以上',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/eew_alert',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        locked: true,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eew',
        channelKey: 'eew_alert-general-v2',
        channelName: '緊急地震速報(一般)',
        channelDescription: '最大震度 5 弱以上以及所在地(鄉鎮)預估震度 2 以上',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/eew',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: mediumVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eew',
        channelKey: 'eew_alert-silent-v2',
        channelName: '緊急地震速報(無聲通知)',
        channelDescription: '最大震度 5 弱以上以及所在地(鄉鎮)預估震度 1 以上',
        importance: NotificationImportance.Low,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: false,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eew',
        channelKey: 'eew-important-v2',
        channelName: '地震速報(重大)',
        channelDescription: '所在地(鄉鎮)預估震度 4 以上',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/eew',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        locked: true,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eew',
        channelKey: 'eew-general-v2',
        channelName: '地震速報(一般)',
        channelDescription: '所在地(鄉鎮)預估震度 2 以上',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/eew',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: mediumVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eew',
        channelKey: 'eew-silence-v2',
        channelName: '地震速報 (無聲通知)',
        channelDescription: '所在地(鄉鎮)預估震度 1 以上',
        importance: NotificationImportance.Low,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: false,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eq',
        channelKey: 'int_report-general-v2',
        channelName: '震度速報(一般)',
        channelDescription: '所在地(鄉鎮)實測震度 3 以上',
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/int_report',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eq',
        channelKey: 'int_report-silence-v2',
        channelName: '震度速報 (無聲通知)',
        channelDescription: '所在地(鄉鎮)實測震度 1 以上',
        importance: NotificationImportance.Low,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: false,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eq',
        channelKey: 'eq-v2',
        channelName: '強震監視器(一般)',
        channelDescription: '偵測到晃動',
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/eq',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: mediumVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eq',
        channelKey: 'report-general-v2',
        channelName: '地震報告(一般)',
        channelDescription: '地震報告所在地震度 3 以上',
        importance: NotificationImportance.Default,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/report',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_eq',
        channelKey: 'report-silence-v2',
        channelName: '地震報告 (無聲通知)',
        channelDescription: '地震報告所在地震度 3 以下的地區',
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.Min,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: false,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: false,
      ),
      NotificationChannel(
        channelGroupKey: 'group_rain',
        channelKey: 'thunderstorm-general-v2',
        channelName: '雷雨即時訊息(一般)',
        channelDescription: '所在地(鄉鎮)發布雷雨即時訊息或山區暴雨時',
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/rain',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: mediumVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_weather',
        channelKey: 'weather_major-important-v2',
        channelName: '天氣警特報(重大)',
        channelDescription: '所在地(鄉鎮)發布紅色燈號之天氣警特報',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/weather',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        locked: true,
      ),
      NotificationChannel(
        channelGroupKey: 'group_weather',
        channelKey: 'weather_minor-general-v2',
        channelName: '天氣警特報(一般)',
        channelDescription: '所在地(鄉鎮)發布上述除外燈號之天氣警特報',
        importance: NotificationImportance.Default,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/normal',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: mediumVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_evacuation',
        channelKey: 'evacuation_major-important-v2',
        channelName: '避難資訊(重大)',
        channelDescription: '所在地(鄉鎮)發布防空、土石流、淹水或堰塞湖避難警訊時',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/warn',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        locked: true,
      ),
      NotificationChannel(
        channelGroupKey: 'group_evacuation',
        channelKey: 'evacuation_minor-general-v2',
        channelName: '避難資訊(一般)',
        channelDescription: '所在地(鄉鎮)發布防空、土石流、淹水或堰塞湖避難警訊時',
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/warn',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: mediumVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_tsunami',
        channelKey: 'tsunami-important-v2',
        channelName: '海嘯資訊(重大)',
        channelDescription: '海嘯警報發布時，沿海地區鄉鎮',
        importance: NotificationImportance.Max,
        defaultPrivacy: NotificationPrivacy.Public,
        criticalAlerts: true,
        playSound: true,
        soundSource: 'resource://raw/tsunami',
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: highVibrationPattern,
        locked: true,
      ),
      NotificationChannel(
        channelGroupKey: 'group_tsunami',
        channelKey: 'tsunami-general-v2',
        channelName: '海嘯資訊(一般)',
        channelDescription: '海嘯警報發布時，上述除外地區',
        importance: NotificationImportance.Default,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/normal',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
      ),
      NotificationChannel(
        channelGroupKey: 'group_tsunami',
        channelKey: 'tsunami-silent-v2',
        channelName: '太平洋海嘯消息 (無聲通知)',
        channelDescription: '地震報告所在地震度 3 以下的地區',
        groupAlertBehavior: GroupAlertBehavior.Children,
        importance: NotificationImportance.Min,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: false,
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: false,
      ),
      NotificationChannel(
        channelGroupKey: 'group_other',
        channelKey: 'announcement-general-v2',
        channelName: '其他通知',
        channelDescription: '發送公告時',
        importance: NotificationImportance.Default,
        defaultPrivacy: NotificationPrivacy.Public,
        playSound: true,
        soundSource: 'resource://raw/info',
        defaultColor: Colors.red,
        ledColor: Colors.red,
        enableVibration: true,
        vibrationPattern: lowVibrationPattern,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(channelGroupKey: 'group_eew', channelGroupName: '地震速報音效'),
      NotificationChannelGroup(channelGroupKey: 'group_eq', channelGroupName: '地震資訊'),
      NotificationChannelGroup(channelGroupKey: 'group_info', channelGroupName: '防災資訊'),
      NotificationChannelGroup(channelGroupKey: 'group_other', channelGroupName: '其他'),
    ],
    debug: true,
  );

  AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);

  final receivedAction = await AwesomeNotifications().getInitialNotificationAction();
  if (receivedAction != null) {
    _pendingChannelKey = receivedAction.channelKey;
    TalkerManager.instance.debug('Stored pending notification: channelKey=$_pendingChannelKey');
  }
}

void handlePendingNotificationNavigation(BuildContext context) {
  if (_pendingChannelKey == null) return;

  TalkerManager.instance.debug('Handling pending notification: channelKey=$_pendingChannelKey');

  if (_pendingChannelKey?.startsWith('eq') == true) {
    context.push(MapPage.route(options: MapPageOptions(initialLayer: MapLayer.monitor)));
  }

  _pendingChannelKey = null;
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  final context = router.routerDelegate.navigatorKey.currentContext;
  if (context == null) {
    _pendingChannelKey = receivedAction.channelKey;
    TalkerManager.instance.debug('Context not available, stored pending notification: channelKey=$_pendingChannelKey');
    return;
  }

  final channelKey = receivedAction.channelKey;
  TalkerManager.instance.debug('Notification clicked: channelKey=$channelKey');

  if (channelKey?.startsWith('eq') == true) {
    context.push(MapPage.route(options: MapPageOptions(initialLayer: MapLayer.monitor)));
    return;
  }
}
