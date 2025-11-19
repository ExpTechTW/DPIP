# 🚀 DPIP 天氣小部件 - 快速入門

這是一個快速設定指南,讓你在 5-10 分鐘內完成 DPIP 天氣桌面小部件的基本設定。

## ⚡ 快速步驟

### 1️⃣ 安裝依賴 (1 分鐘)

```bash
flutter pub get
```

### 2️⃣ Android 設定 (已完成 ✅)

**無需任何操作!** 所有 Android 相關程式碼和設定已自動完成。

直接執行測試:

```bash
flutter run
```

然後在 Android 主畫面長按 → 選擇「小部件」→ 找到 DPIP 天氣小部件 → 拖曳到主畫面

### 3️⃣ iOS 設定 (5-8 分鐘)

**必須透過 Xcode 完成**

⚠️ **注意**: 目前 iOS 建置有循環依賴錯誤,需要先修復。請參考下方的「iOS 循環依賴修復」章節。

#### 步驟 A: 開啟 Xcode

```bash
open ios/Runner.xcworkspace
```

#### 步驟 B: 建立 Widget Extension

1. **File → New → Target**
2. 選擇 **Widget Extension**
3. 設定:
   - Product Name: `WeatherWidget`
   - Bundle Identifier: `com.exptech.dpip.WeatherWidget`
   - 取消勾選 **Include Configuration Intent**
4. 點選 **Finish** → **Activate**

#### 步驟 C: 設定 App Group (兩個 target 都要做)

**Runner target:**
1. 選擇 **Runner** target
2. **Signing & Capabilities** 標籤
3. **+ Capability** → 搜尋 **App Groups**
4. 勾選或新增 `group.com.exptech.dpip`

**WeatherWidget target:**
1. 選擇 **WeatherWidget** target
2. 重複上述步驟 2-4

#### 步驟 D: 替換程式碼

1. 刪除 Xcode 自動生成的 `WeatherWidget.swift`
2. 在 Xcode 左側專案導覽器,右鍵 **WeatherWidget** 資料夾
3. **Add Files to "Runner"...**
4. 選擇專案中的 `ios/WeatherWidget/WeatherWidget.swift`
5. 確保 Target Membership 只勾選 **WeatherWidget**

#### 步驟 E: 執行測試

```bash
flutter run
```

在 iOS 主畫面長按 → 點選 **+** → 搜尋 DPIP → 加入「即時天氣」小部件

---

## ✅ 驗證成功

小部件應該顯示:
- ☀️ 天氣狀況圖示和文字
- 🌡️ 當前溫度 (大字體)
- 💨 體感溫度
- 💧 濕度、風速、風向、降雨
- 📍 氣象站資訊
- 🕐 更新時間

---

## 🔄 自動更新

小部件會:
- ✅ 每 30 分鐘自動背景更新
- ✅ App 刷新時同步更新
- ✅ 即使 App 關閉也會繼續更新

---

## 🔧 iOS 循環依賴修復

如果遇到 `Error (Xcode): Cycle inside Runner` 錯誤:

### 快速修復

1. 開啟 Xcode: `open ios/Runner.xcworkspace`
2. 選擇 **Runner** target
3. 點選 **Build Phases** 標籤
4. 找到 **Embed App Extensions**
5. **拖曳**它到 **[CP] Embed Pods Frameworks** 之前
6. Xcode: Product → Clean Build Folder (⇧⌘K)
7. 執行: `flutter clean && flutter run`

### 詳細修復指南

參考 [WIDGET_IOS_FIX.md](./WIDGET_IOS_FIX.md) 獲取完整解決方案。

### 或者先在 Android 測試

iOS 的循環依賴不影響功能,你可以:
1. 先在 **Android** 上測試 Widget (完全可用)
2. 之後再修復 iOS 建置問題

參考 [QUICK_TEST.md](./QUICK_TEST.md) 快速開始測試。

---

## ❓ 遇到問題?

查看完整文件: [WIDGET_IMPLEMENTATION.md](./WIDGET_IMPLEMENTATION.md)

### 常見問題速查

**iOS 找不到小部件?**
→ 檢查是否完成「步驟 C: 設定 App Group」(兩個 target 都要設定!)

**小部件顯示錯誤?**
→ 確認 App Group ID 完全一致: `group.com.exptech.dpip`

**Android 小部件不更新?**
→ 檢查背景執行權限,關閉電池優化

---

## 🎉 完成!

恭喜!你的 DPIP App 現在支援桌面天氣小部件了。
