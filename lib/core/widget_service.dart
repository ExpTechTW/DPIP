import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/gps_location.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

final talker = TalkerManager.instance;

/// 天氣桌面小部件服務
/// 負責獲取天氣資料並更新桌面小部件
class WidgetService {
  static const String _widgetNameAndroid = 'WeatherWidgetProvider';
  static const String _widgetNameAndroidSmall = 'WeatherWidgetSmallProvider';
  static const String _widgetNameIOS = 'WeatherWidget';

  /// 更新小部件資料
  static Future<void> updateWidget() async {
    try {
      // iOS 需要設定 App Group
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId('group.com.exptech.dpip');
      }

      talker.debug('[WidgetService] 開始更新小部件');

      // 1. 取得位置資訊
      await _ensureLocationData();

      final lat = Preference.locationLatitude;
      final lon = Preference.locationLongitude;

      if (lat == null || lon == null) {
        talker.warning('[WidgetService] 位置資訊不可用');
        await _saveErrorState('位置未設定');
        return;
      }

      // 2. 獲取天氣資料
      final weather = await _fetchWeatherData(lat, lon);

      if (weather == null) {
        talker.warning('[WidgetService] 無法獲取天氣資料');
        await _saveErrorState('無法獲取天氣');
        return;
      }

      // 3. 計算體感溫度
      final feelsLike = _calculateFeelsLike(
        weather.data.temperature,
        weather.data.humidity,
        weather.data.wind.speed,
      );

      // 4. 儲存資料到 SharedPreferences/UserDefaults
      await _saveWidgetData(weather, feelsLike);

      // 5. 觸發小部件更新 (更新所有小部件變體)
      if (Platform.isAndroid) {
        // 更新標準版和小方形版
        await HomeWidget.updateWidget(androidName: _widgetNameAndroid);
        await HomeWidget.updateWidget(androidName: _widgetNameAndroidSmall);
      } else {
        await HomeWidget.updateWidget(iOSName: _widgetNameIOS);
      }

      talker.info('[WidgetService] 小部件更新成功');
    } catch (e, stack) {
      talker.error('[WidgetService] 更新失敗', e, stack);
      await _saveErrorState('更新失敗');
    }
  }

  /// 確保位置資料可用
  static Future<void> _ensureLocationData() async {
    await Preference.reload();

    // 如果是自動定位模式,更新GPS位置
    if (Preference.locationAuto == true) {
      await updateLocationFromGPS();
    } else {
      // 使用手動設定的位置
      final code = Preference.locationCode;
      if (code != null) {
        final location = Global.location[code];
        if (location != null) {
          Preference.locationLatitude = location.lat;
          Preference.locationLongitude = location.lng;
        }
      }
    }
  }

  /// 獲取天氣資料
  static Future<RealtimeWeather?> _fetchWeatherData(double lat, double lon) async {
    try {
      final response = await ExpTech().getWeatherRealtimeByCoords(lat, lon);
      return response;
    } catch (e) {
      talker.error('[WidgetService] 獲取天氣資料失敗', e);
      return null;
    }
  }

  /// 計算體感溫度 (與 weather_header.dart 相同邏輯)
  static double _calculateFeelsLike(double temperature, double humidity, double windSpeed) {
    final e = humidity / 100 * 6.105 * exp(17.27 * temperature / (temperature + 237.3));
    return temperature + 0.33 * e - 0.7 * windSpeed - 4.0;
  }

  /// 儲存小部件資料
  static Future<void> _saveWidgetData(RealtimeWeather weather, double feelsLike) async {
    // 基本天氣資訊
    await HomeWidget.saveWidgetData<String>('weather_status', weather.data.weather);
    await HomeWidget.saveWidgetData<int>('weather_code', weather.data.weatherCode);
    await HomeWidget.saveWidgetData<double>('temperature', weather.data.temperature);
    await HomeWidget.saveWidgetData<double>('feels_like', feelsLike);

    // 詳細氣象資料
    await HomeWidget.saveWidgetData<double>('humidity', weather.data.humidity);
    await HomeWidget.saveWidgetData<double>('wind_speed', weather.data.wind.speed);
    await HomeWidget.saveWidgetData<String>('wind_direction', weather.data.wind.direction);
    await HomeWidget.saveWidgetData<int>('wind_beaufort', weather.data.wind.beaufort);
    await HomeWidget.saveWidgetData<double>('pressure', weather.data.pressure);
    await HomeWidget.saveWidgetData<double>('rain', weather.data.rain);
    await HomeWidget.saveWidgetData<double>('visibility', weather.data.visibility);

    // 陣風資料 (選用)
    if (weather.data.gust.speed > 0) {
      await HomeWidget.saveWidgetData<double>('gust_speed', weather.data.gust.speed);
      await HomeWidget.saveWidgetData<int>('gust_beaufort', weather.data.gust.beaufort);
    }

    // 日照時數 (選用)
    if (weather.data.sunshine >= 0) {
      await HomeWidget.saveWidgetData<double>('sunshine', weather.data.sunshine);
    }

    // 氣象站資訊
    await HomeWidget.saveWidgetData<String>('station_name', weather.station.name);
    await HomeWidget.saveWidgetData<double>('station_distance', weather.station.distance);

    // 更新時間
    await HomeWidget.saveWidgetData<int>('update_time', weather.time);

    // 狀態標記
    await HomeWidget.saveWidgetData<bool>('has_error', false);
    await HomeWidget.saveWidgetData<String>('error_message', '');
  }

  /// 儲存錯誤狀態
  static Future<void> _saveErrorState(String message) async {
    await HomeWidget.saveWidgetData<bool>('has_error', true);
    await HomeWidget.saveWidgetData<String>('error_message', message);

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: _widgetNameAndroid);
      await HomeWidget.updateWidget(androidName: _widgetNameAndroidSmall);
    } else {
      await HomeWidget.updateWidget(iOSName: _widgetNameIOS);
    }
  }

  /// 清除小部件資料 (用於登出或重置)
  static Future<void> clearWidget() async {
    await HomeWidget.saveWidgetData<bool>('has_error', true);
    await HomeWidget.saveWidgetData<String>('error_message', '已清除');

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(androidName: _widgetNameAndroid);
      await HomeWidget.updateWidget(androidName: _widgetNameAndroidSmall);
    } else {
      await HomeWidget.updateWidget(iOSName: _widgetNameIOS);
    }
  }
}
