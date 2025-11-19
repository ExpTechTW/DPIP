# 📱 DPIP 天氣桌面小部件實作指南

本文件說明如何完成 DPIP 天氣桌面小部件的設定,讓 Android 和 iOS 裝置能在桌面顯示即時天氣資訊。

## 📋 目錄

- [已完成的部分](#已完成的部分)
- [需要手動完成的步驟](#需要手動完成的步驟)
  - [1. 安裝依賴套件](#1-安裝依賴套件)
  - [2. Android 設定](#2-android-設定)
  - [3. iOS 設定](#3-ios-設定)
- [功能說明](#功能說明)
- [測試方法](#測試方法)
- [故障排除](#故障排除)

---

## ✅ 已完成的部分

以下程式碼和設定已經自動生成:

### Flutter 端
- ✅ `lib/core/widget_service.dart` - 小部件資料處理服務
- ✅ `lib/core/widget_background.dart` - 背景更新管理
- ✅ `lib/main.dart` - 初始化 Workmanager
- ✅ `lib/app/home/page.dart` - 整合小部件更新到 HomePage
- ✅ `pubspec.yaml` - 已加入 `home_widget` 和 `workmanager` 依賴

### Android 端
- ✅ `android/app/src/main/kotlin/com/exptech/dpip/WeatherWidgetProvider.kt` - Widget Provider
- ✅ `android/app/src/main/res/layout/weather_widget.xml` - 小部件佈局
- ✅ `android/app/src/main/res/xml/weather_widget_info.xml` - 小部件配置
- ✅ `android/app/src/main/res/drawable/widget_background.xml` - 背景樣式
- ✅ `android/app/src/main/res/drawable/feels_like_background.xml` - 體感溫度背景
- ✅ `android/app/src/main/res/values/strings.xml` - 字串資源
- ✅ `android/app/src/main/AndroidManifest.xml` - Widget 註冊

### iOS 端
- ✅ `ios/WeatherWidget/WeatherWidget.swift` - SwiftUI Widget 實作
- ✅ `ios/WeatherWidget/Info.plist` - Widget Extension 設定檔

---

## 🔧 需要手動完成的步驟

### 1. 安裝依賴套件

```bash
flutter pub get
```

### 2. Android 設定

Android 部分的程式碼已全部生成,**無需額外手動操作**。

#### 驗證 AndroidManifest.xml

確認 `android/app/src/main/AndroidManifest.xml` 中已包含以下內容:

```xml
<!-- Weather Widget -->
<receiver
        android:name=".WeatherWidgetProvider"
        android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
            android:name="android.appwidget.provider"
            android:resource="@xml/weather_widget_info"/>
</receiver>
```

#### 自訂天氣圖示 (選用)

目前使用系統預設圖示。如需自訂圖示,請:

1. 將圖示檔案放到 `android/app/src/main/res/drawable/`
2. 修改 `WeatherWidgetProvider.kt` 中的 `getWeatherIcon()` 函數:

```kotlin
private fun getWeatherIcon(code: Int): Int {
    return when (code) {
        1 -> R.drawable.weather_sunny
        2, 3 -> R.drawable.weather_cloudy
        // ... 其他代碼
    }
}
```

### 3. iOS 設定

⚠️ **重要**: iOS Widget Extension 需要透過 Xcode 手動建立。

#### 步驟 3.1: 開啟 Xcode 專案

```bash
open ios/Runner.xcworkspace
```

#### 步驟 3.2: 建立 Widget Extension

1. 在 Xcode 選單選擇 **File → New → Target**
2. 在模板視窗選擇 **Widget Extension**
3. 設定如下:
   - **Product Name**: `WeatherWidget`
   - **Team**: 選擇你的開發團隊
   - **Bundle Identifier**: `com.exptech.dpip.WeatherWidget`
   - **Include Configuration Intent**: 取消勾選
4. 點選 **Finish**
5. 出現對話框詢問是否啟用 scheme,點選 **Activate**

#### 步驟 3.3: 設定 App Group

為了讓 Flutter App 和 Widget Extension 共享資料,需要設定 App Group。

**A. 在 Runner (主 App) 中:**

1. 選擇 **Runner** target
2. 選擇 **Signing & Capabilities** 標籤
3. 點選 **+ Capability**
4. 搜尋並加入 **App Groups**
5. 勾選或新增 `group.com.exptech.dpip`

**B. 在 WeatherWidget target 中:**

1. 選擇 **WeatherWidget** target
2. 重複上述步驟 2-5

#### 步驟 3.4: 替換 Widget 程式碼

1. 刪除 Xcode 自動生成的 `WeatherWidget.swift` 檔案
2. 將我們生成的 `ios/WeatherWidget/WeatherWidget.swift` 加入專案:
   - 在 Xcode 左側專案導覽器中,右鍵點選 **WeatherWidget** 資料夾
   - 選擇 **Add Files to "Runner"...**
   - 選擇 `ios/WeatherWidget/WeatherWidget.swift`
   - 確保 **Target Membership** 只勾選 **WeatherWidget**

#### 步驟 3.5: 更新 home_widget 設定

在 `lib/core/widget_service.dart` 中,確認 App Group 名稱正確:

```dart
// 在使用 HomeWidget 前設定 App Group (僅 iOS)
import 'dart:io';

if (Platform.isIOS) {
  await HomeWidget.setAppGroupId('group.com.exptech.dpip');
}
```

修改 `widget_service.dart`,在 `updateWidget()` 函數開頭加入:

```dart
static Future<void> updateWidget() async {
  try {
    // iOS 需要設定 App Group
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId('group.com.exptech.dpip');
    }

    talker.debug('[WidgetService] 開始更新小部件');
    // ... 其餘程式碼
```

需要加入 import:

```dart
import 'dart:io';
```

#### 步驟 3.6: 設定最低 iOS 版本

確保 Widget Extension 的最低支援版本與主 App 一致:

1. 選擇 **WeatherWidget** target
2. **General** 標籤 → **Deployment Info** → **iOS** 設為 `15.0` 或以上

---

## 🎯 功能說明

### 自動更新機制

- **週期性更新**: 每 30 分鐘自動更新一次 (可在 `page.dart` 的 `_initializeWidget()` 中調整)
- **手動更新**: 使用者下拉刷新 HomePage 時同時更新小部件
- **背景更新**: 透過 Workmanager 在背景執行,即使 App 關閉也能更新

### 顯示的資料

小部件顯示以下天氣資訊:
- ☀️ 天氣狀態 (晴天、多雲、雨天等)
- 🌡️ 當前溫度
- 💨 體感溫度
- 💧 濕度
- 🍃 風速、風向
- 🌧️ 降雨量
- 📍 氣象站名稱和距離
- 🕐 更新時間

### 資料流程

```
Flutter App (HomePage)
    ↓ (呼叫 WidgetService.updateWidget())
    ↓
取得天氣資料 (ExpTech API)
    ↓
計算體感溫度
    ↓
儲存到 SharedPreferences/UserDefaults
    ↓
觸發小部件更新
    ↓
原生 Widget 讀取資料並顯示
```

---

## 🧪 測試方法

### Android 測試

1. 執行 App:
   ```bash
   flutter run
   ```

2. 在 Android 主畫面長按空白處
3. 選擇「小部件」或「Widgets」
4. 找到 DPIP 天氣小部件
5. 拖曳到主畫面

6. 檢查小部件是否正常顯示天氣資訊

### iOS 測試

1. 執行 App:
   ```bash
   flutter run
   ```

2. 在 iOS 主畫面長按空白處進入編輯模式
3. 點選左上角的 **+** 號
4. 搜尋 DPIP 或向下滾動找到「即時天氣」
5. 選擇中等大小 (Medium) 的小部件
6. 點選「加入小部件」

7. 檢查小部件是否正常顯示

### 背景更新測試

1. 將 App 完全關閉
2. 等待 30 分鐘或修改更新間隔為較短時間 (如 15 分鐘)
3. 檢查小部件資料是否自動更新

**測試提示**: 在 `widget_background.dart` 中將 `isInDebugMode` 設為 `true` 可查看詳細日誌:

```dart
await Workmanager().initialize(
  callbackDispatcher,
  isInDebugMode: true, // 開啟除錯模式
);
```

---

## 🔧 故障排除

### Android 常見問題

#### 問題: 小部件顯示「無法載入天氣」

**解決方法**:
1. 確認 App 有網路權限
2. 檢查位置權限是否開啟
3. 查看 Logcat 日誌: `adb logcat | grep WidgetService`

#### 問題: 小部件不更新

**解決方法**:
1. 檢查 AndroidManifest.xml 中是否正確註冊 WeatherWidgetProvider
2. 確認 Workmanager 已初始化
3. 檢查背景執行權限 (電池優化設定)

### iOS 常見問題

#### 問題: 找不到小部件

**解決方法**:
1. 確認已正確建立 Widget Extension target
2. 檢查 Bundle Identifier 是否正確
3. 重新編譯: `flutter clean && flutter run`

#### 問題: 小部件顯示錯誤

**解決方法**:
1. 確認 App Group 已正確設定在兩個 target 中
2. 檢查 App Group ID 是否一致: `group.com.exptech.dpip`
3. 在 Xcode Console 查看錯誤訊息

#### 問題: 小部件資料不更新

**解決方法**:
1. 確認 `HomeWidget.setAppGroupId()` 已正確呼叫
2. iOS 限制背景更新頻率,可能需等待較長時間
3. 檢查系統的「背景 App 重新整理」設定是否開啟

### 通用問題

#### 問題: Workmanager 版本相容性

如果遇到 Flutter 3.29.0+ 與 workmanager 0.5.2 的相容性問題:

1. 嘗試降級 Flutter 或
2. 關注 [workmanager GitHub issue #588](https://github.com/fluttercommunity/flutter_workmanager/issues/588) 等待修復
3. 暫時可註解掉 Workmanager 相關程式碼,僅使用手動更新

---

## 📚 參考資料

- [home_widget 套件文件](https://pub.dev/packages/home_widget)
- [workmanager 套件文件](https://pub.dev/packages/workmanager)
- [Google Codelab: Flutter Home Screen Widgets](https://codelabs.developers.google.com/flutter-home-screen-widgets)
- [Apple WidgetKit 文件](https://developer.apple.com/documentation/widgetkit)
- [Android App Widgets 文件](https://developer.android.com/develop/ui/views/appwidgets)

---

## 📝 調整設定

### 修改更新頻率

在 `lib/app/home/page.dart` 的 `_initializeWidget()` 中:

```dart
// 修改為 15 分鐘
await WidgetBackground.registerPeriodicUpdate(frequencyMinutes: 15);

// 或修改為 60 分鐘
await WidgetBackground.registerPeriodicUpdate(frequencyMinutes: 60);
```

**注意**: Android 最小間隔為 15 分鐘。

### 自訂小部件樣式

- **Android**: 修改 `android/app/src/main/res/layout/weather_widget.xml`
- **iOS**: 修改 `ios/WeatherWidget/WeatherWidget.swift` 中的 `WeatherWidgetEntryView`

### 修改顯示資料

在 `lib/core/widget_service.dart` 的 `_saveWidgetData()` 中新增或移除要傳遞的資料。

---

## ✨ 完成!

設定完成後,使用者即可在 Android 和 iOS 桌面上看到即時天氣資訊,並自動保持更新。

如有問題,請參考故障排除章節或查看相關日誌。
