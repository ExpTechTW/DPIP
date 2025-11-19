# 📐 DPIP 天氣小部件 - 佈局說明

## 🎨 可用的小部件尺寸

DPIP 現在提供兩種小部件尺寸,滿足不同的桌面佈局需求:

### 1️⃣ 標準版 (4×3)

**尺寸**: 250dp × 180dp (約 4×3 網格單元)

**顯示內容**:
- ☀️ 天氣圖示和狀態
- 🌡️ 當前溫度 (大字體 40sp)
- 💨 體感溫度
- 📊 完整氣象資訊網格:
  - 濕度 💧
  - 風速 💨
  - 風向 🧭
  - 降雨量 🌧️
- 📍 氣象站名稱和距離
- 🕐 更新時間

**適用場景**:
- 桌面有充足空間
- 需要查看完整天氣資訊
- 作為主要天氣資訊來源

**檔案**:
- 佈局: `android/app/src/main/res/layout/weather_widget.xml`
- 配置: `android/app/src/main/res/xml/weather_widget_info.xml`
- Provider: `android/app/src/main/kotlin/com/exptech/dpip/WeatherWidgetProvider.kt`

---

### 2️⃣ 小方形版 (2×2) 🆕

**尺寸**: 120dp × 120dp (約 2×2 網格單元)

**顯示內容**:
- ☀️ 天氣圖示和狀態 (緊湊排列)
- 🌡️ 當前溫度 (中等字體 36sp)
- 💨 體感溫度
- 📊 簡化資訊:
  - 濕度 💧 (emoji + 數值)
  - 風速 💨 (emoji + 數值)
- 🕐 更新時間

**適用場景**:
- 桌面空間有限
- 只需要核心天氣資訊
- 搭配其他小部件使用
- 簡約美觀風格

**檔案**:
- 佈局: `android/app/src/main/res/layout/weather_widget_small.xml`
- 配置: `android/app/src/main/res/xml/weather_widget_small_info.xml`
- Provider: `android/app/src/main/kotlin/com/exptech/dpip/WeatherWidgetSmallProvider.kt`

---

## 🔧 改進重點

### 修復邊界溢出問題 ✅

原有問題:
- ❌ padding 過大 (16dp)
- ❌ 字體大小過大 (48sp)
- ❌ 間距不均勻
- ❌ 缺少 `clipChildren` 和 `clipToPadding` 設定
- ❌ 缺少 `singleLine` 和 `ellipsize` 防止文字溢出

新的改進:
- ✅ 減少 padding (12dp → 標準版, 10dp → 小方形版)
- ✅ 調整字體大小 (40sp → 標準版, 36sp → 小方形版)
- ✅ 使用 `layout_weight` 動態分配空間
- ✅ 添加 `clipChildren="false"` 和 `clipToPadding="false"`
- ✅ 所有文字視圖使用 `singleLine="true"` 和 `ellipsize="end"`
- ✅ 圖示使用 `scaleType="centerInside"` 確保不超出邊界
- ✅ 溫度使用 `includeFontPadding="false"` 減少多餘空間

### 美觀緊湊設計 ✅

**視覺改進**:
- 🎨 更緊湊的內邊距和間距
- 📏 更合理的字體大小層次
- 🔤 更清晰的資訊層級
- ⚖️ 更平衡的空間分配
- 🎯 重點突出溫度資訊

**響應式佈局**:
- 📱 支援可調整大小 (`resizeMode="horizontal|vertical"`)
- 🔄 使用相對佈局確保不同螢幕適配
- 📐 使用 `layout_weight` 動態分配網格空間

---

## 🚀 使用方法

### 添加小部件到桌面

1. **長按** Android 主畫面空白處
2. 選擇「**小部件**」或「**Widgets**」
3. 找到「**DPIP**」分類
4. 選擇你需要的尺寸:
   - **天氣小部件** (標準版 4×3)
   - **緊湊的天氣小部件** (小方形版 2×2)
5. **拖曳**到桌面合適位置

### 調整小部件大小

兩個版本都支援調整大小:
1. **長按**小部件直到出現調整框
2. **拖曳**邊框調整寬度和高度
3. 佈局會自動適應新尺寸

---

## 🔄 自動更新

所有小部件共用相同的資料來源,更新機制統一:

- ✅ **每 30 分鐘**背景自動更新
- ✅ **App 刷新**時同步更新
- ✅ **所有尺寸**同時更新
- ✅ App 關閉後仍繼續運作

---

## 📱 技術細節

### 資料共享

兩個小部件使用相同的 `SharedPreferences` 資料:
- Flutter 透過 `home_widget` 套件寫入資料
- Android Provider 讀取相同的資料源
- 一次更新,所有小部件同步

### 更新流程

```
Flutter WidgetService.updateWidget()
    ↓
寫入 SharedPreferences
    ↓
通知 WeatherWidgetProvider (標準版)
    ↓
通知 WeatherWidgetSmallProvider (小方形版)
    ↓
所有小部件更新完成 ✅
```

### Provider 註冊

`AndroidManifest.xml` 中註冊兩個 Provider:

```xml
<!-- 標準版 4x3 -->
<receiver android:name=".WeatherWidgetProvider" ...>
    <meta-data android:resource="@xml/weather_widget_info"/>
</receiver>

<!-- 小方形版 2x2 -->
<receiver android:name=".WeatherWidgetSmallProvider" ...>
    <meta-data android:resource="@xml/weather_widget_small_info"/>
</receiver>
```

---

## 🎨 UI 設計原則

### 標準版 (4×3)
- **目標**: 提供完整的天氣資訊一覽
- **設計**: 垂直堆疊,從上到下層次分明
- **重點**: 溫度居中突出,詳細資訊網格化

### 小方形版 (2×2)
- **目標**: 在有限空間內顯示核心資訊
- **設計**: 緊湊垂直佈局,居中對齊
- **重點**: 溫度為主,濕度和風速為輔
- **特色**: 使用 emoji 節省空間,更直觀

---

## 🔮 未來可能的擴展

- 📊 更多尺寸選項 (1×1, 3×2, 5×2 等)
- 🎨 自訂主題和配色
- 📈 天氣趨勢圖表 (小時預報)
- 🌙 根據時間自動切換深色/淺色模式
- 🔔 天氣警報快速顯示
- 📍 多地點切換

---

## 🐛 疑難排解

### 小部件不顯示?
- 檢查 App 是否有定位權限
- 確認已在 App 內刷新過天氣資料
- 嘗試移除小部件後重新添加

### 資料不更新?
- 檢查背景執行權限
- 關閉電池優化 (Settings → Battery → App → Unrestricted)
- 手動在 App 內下拉刷新

### 佈局顯示異常?
- 嘗試調整小部件大小
- 確保 Android 系統版本 ≥ 12 (較佳支援)
- 重啟系統桌面 (Launcher)

---

## 📚 相關文件

- [README_WIDGET.md](README_WIDGET.md) - 主要使用指南
- [WIDGET_IMPLEMENTATION.md](WIDGET_IMPLEMENTATION.md) - 完整實作文件
- [QUICK_TEST.md](QUICK_TEST.md) - 快速測試指南

---

**更新日期**: 2025-11-19
**版本**: 2.0 (新增小方形版)
