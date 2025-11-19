import 'dart:io';
import 'package:dpip/core/widget_service.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';
import 'package:workmanager/workmanager.dart';

final talker = TalkerManager.instance;

/// 背景任務處理器
/// 由 Workmanager 呼叫,在背景執行小部件更新
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    talker.debug('[WidgetBackground] 執行背景任務: $task');

    try {
      switch (task) {
        case WidgetBackground.taskUpdateWidget:
          // 初始化必要的全域資料
          await Global.init();

          // 更新小部件
          await WidgetService.updateWidget();
          break;

        default:
          talker.warning('[WidgetBackground] 未知任務: $task');
      }

      return Future.value(true);
    } catch (e, stack) {
      talker.error('[WidgetBackground] 背景任務失敗', e, stack);
      return Future.value(false);
    }
  });
}

/// 小部件背景更新管理
class WidgetBackground {
  static const String taskUpdateWidget = 'widget_update_weather';

  /// 初始化背景任務
  static Future<void> initialize() async {
    // 只有 Android 需要初始化 Workmanager
    // iOS 使用 WidgetKit 的內建 Timeline 機制
    if (!Platform.isAndroid) {
      talker.info('[WidgetBackground] iOS 使用 WidgetKit Timeline，無需額外初始化');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // 設為 true 可查看詳細日誌
      );

      talker.info('[WidgetBackground] Workmanager 初始化成功');
    } catch (e, stack) {
      talker.error('[WidgetBackground] Workmanager 初始化失敗', e, stack);
    }
  }

  /// 註冊週期性更新任務
  ///
  /// [frequencyMinutes] - 更新頻率(分鐘),最小值為15分鐘 (Android WorkManager 系統限制)
  /// iOS 不需要註冊週期性任務，使用 WidgetKit Timeline
  static Future<void> registerPeriodicUpdate({int frequencyMinutes = 15}) async {
    // iOS 使用 WidgetKit 的 Timeline，在 Swift 端自動處理
    if (!Platform.isAndroid) {
      talker.info('[WidgetBackground] iOS 使用 WidgetKit Timeline (${frequencyMinutes}分鐘自動更新)');
      return;
    }

    try {
      // 確保頻率不低於15分鐘 (Android WorkManager 限制)
      final frequency = frequencyMinutes < 15 ? 15 : frequencyMinutes;

      await Workmanager().registerPeriodicTask(
        taskUpdateWidget,
        taskUpdateWidget,
        frequency: Duration(minutes: frequency),
        constraints: Constraints(
          networkType: NetworkType.connected, // 需要網路連線
          requiresBatteryNotLow: false, // 電量低時也執行
          requiresCharging: false, // 不需要充電
          requiresDeviceIdle: false, // 不需要裝置閒置
          requiresStorageNotLow: false, // 不需要儲存空間充足
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // 替換現有任務
        backoffPolicy: BackoffPolicy.exponential, // 失敗後的重試策略
        backoffPolicyDelay: Duration(minutes: 5), // 重試延遲
      );

      talker.info('[WidgetBackground] 已註冊週期性更新,頻率: $frequency 分鐘');
    } catch (e, stack) {
      talker.error('[WidgetBackground] 註冊週期性更新失敗', e, stack);
    }
  }

  /// 註冊一次性立即更新
  static Future<void> registerImmediateUpdate() async {
    try {
      await Workmanager().registerOneOffTask(
        '${taskUpdateWidget}_immediate',
        taskUpdateWidget,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      talker.debug('[WidgetBackground] 已註冊立即更新任務');
    } catch (e, stack) {
      talker.error('[WidgetBackground] 註冊立即更新失敗', e, stack);
    }
  }

  /// 取消所有背景任務
  static Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      talker.info('[WidgetBackground] 已取消所有背景任務');
    } catch (e, stack) {
      talker.error('[WidgetBackground] 取消背景任務失敗', e, stack);
    }
  }

  /// 取消特定任務
  static Future<void> cancelTask(String taskName) async {
    try {
      await Workmanager().cancelByUniqueName(taskName);
      talker.info('[WidgetBackground] 已取消任務: $taskName');
    } catch (e, stack) {
      talker.error('[WidgetBackground] 取消任務失敗: $taskName', e, stack);
    }
  }
}
