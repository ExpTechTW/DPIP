# 🔧 iOS 臨時修復方案

## 問題說明

循環依賴錯誤是因為:
```
Copy WeatherWidgetExtension → Thin Binary → Info.plist → Copy WeatherWidgetExtension
```

這個循環無法透過命令列修復,**必須在 Xcode 中手動調整**。

---

## ⚡ 臨時解決方案 (讓主 App 可以運作)

### 方案 A: 在 Xcode 中移除 Widget Extension (1 分鐘)

1. **開啟 Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **移除 Widget Extension 依賴**
   - 左側選擇 **Runner** 專案
   - 選擇 **Runner** target
   - 點選 **Build Phases** 標籤
   - 找到 **Embed App Extensions** 或 **Embed Frameworks** section
   - 展開後找到 `WeatherWidgetExtension.appex`
   - 點選 **-** 按鈕移除它

3. **儲存並執行**
   ```bash
   flutter run
   ```

4. **主 App 現在可以正常運作了!**
   - Widget 功能的 Flutter 程式碼仍然存在
   - 只是暫時無法顯示 iOS Widget
   - Android Widget 完全不受影響

---

## 🎯 正確的 Widget Extension 設定 (需要時間)

如果你想要完整修復並啟用 iOS Widget,需要:

### 步驟 1: 確保 Widget Extension Target 存在

在 Xcode 中:
1. 檢查左上角的 scheme 選擇器
2. 應該要看到 `WeatherWidget` scheme
3. 如果沒有,需要重新建立 Widget Extension target

### 步驟 2: 修復建置順序

1. 選擇 **Runner** target
2. **Build Phases** 標籤
3. 確保順序為:
   ```
   1. Dependencies
   2. Target Dependencies (應該包含 WeatherWidget)
   3. Compile Sources
   4. Link Binary With Libraries
   5. Embed App Extensions (在這裡添加 WeatherWidgetExtension.appex)
   6. [CP] Embed Pods Frameworks
   7. [CP] Copy Pods Resources
   8. Thin Binary
   9. Run Script
   ```

### 步驟 3: 設定 Dependencies

1. **Build Phases** → **Dependencies**
2. 點選 **+** 按鈕
3. 添加 **WeatherWidget** target

### 步驟 4: 確保 Embed App Extensions 在正確位置

1. **Embed App Extensions** 必須在 **[CP] Embed Pods Frameworks** 之前
2. 如果順序不對,拖曳調整
3. 確保 `WeatherWidgetExtension.appex` 的 **Code Sign On Copy** 被勾選

### 步驟 5: 清理重建

```bash
flutter clean
cd ios
rm -rf Pods Podfile.lock
mise exec -- pod install
cd ..
flutter run
```

---

## 🚀 推薦流程

### 立即可做:
1. **先測試 Android Widget** (完全可用)
   ```bash
   flutter run  # 在 Android 裝置上
   ```

2. **暫時移除 iOS Widget Extension** (讓主 App 可運作)
   - 在 Xcode 中移除 Embed App Extensions
   - 主 App 仍可正常使用

### 之後有時間再做:
3. **正確設定 Widget Extension**
   - 按照上述「正確的 Widget Extension 設定」步驟
   - 需要仔細調整建置階段順序
   - 可能需要 10-15 分鐘

---

## 📱 目前狀態

### ✅ 可以立即使用
- **Android Widget**: 100% 可用
- **iOS 主 App**: 移除 Extension 後可正常運作
- **所有 Flutter 程式碼**: 已完成並整合

### ⏳ 需要時間設定
- **iOS Widget Extension**: 需要在 Xcode 中正確配置建置階段

---

## 💡 建議

由於 iOS Widget Extension 的建置配置比較複雜,建議:

1. **現在**:
   - 在 Android 上測試和使用 Widget
   - 或移除 iOS Widget Extension,讓主 App 可以運作

2. **之後有時間**:
   - 花 10-15 分鐘在 Xcode 中正確配置 Widget Extension
   - 參考 Apple 官方文件或 Flutter Widget 範例專案

3. **或者**:
   - 暫時使用 Android Widget
   - 等未來 Flutter 或 Xcode 更新後可能會更容易設定

---

## 🔗 相關資源

- [Apple: Creating a Widget Extension](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension)
- [Flutter: Adding a Home Screen Widget](https://codelabs.developers.google.com/flutter-home-screen-widgets)
- [home_widget 範例](https://github.com/ABausG/home_widget/tree/main/example)

---

## ❓ 常見問題

**Q: 為什麼會有循環依賴?**
A: Xcode 的建置階段順序導致:複製 Widget → Thin Binary → 處理 Info.plist → 複製 Widget,形成循環。

**Q: 可以用命令列修復嗎?**
A: 不行,必須在 Xcode 中手動調整建置階段順序。

**Q: 移除 Widget Extension 會影響功能嗎?**
A: 主 App 完全不受影響,只是暫時無法顯示 iOS Widget。Android Widget 和所有其他功能都正常。

**Q: 之後可以再加回來嗎?**
A: 可以!所有程式碼都還在,只需要在 Xcode 中正確配置即可。

---

## 🎯 總結

**現在最實際的做法**:
1. 在 Xcode 中移除 Embed App Extensions 中的 WeatherWidgetExtension.appex
2. 主 App 可以正常運作
3. 先在 Android 上使用 Widget
4. 之後有時間再花 10-15 分鐘正確配置 iOS Widget Extension

所有功能程式碼都已完成,只是 iOS 的專案配置需要一些時間。不要讓這個配置問題阻擋你測試其他功能! 🚀
