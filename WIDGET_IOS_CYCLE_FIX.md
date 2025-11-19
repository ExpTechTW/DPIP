# 🔧 iOS Widget 循環依賴完整修復指南

## 🎯 問題分析

根據錯誤訊息,循環依賴的路徑是:
```
Copy WeatherWidget → Thin Binary → Info.plist → Copy WeatherWidget
```

這是 **Xcode 15+** 的已知問題,與 CocoaPods、Widget Extension 和 Flutter 的 "Thin Binary" 建置階段有關。

---

## ✅ 經過驗證的解決方案 (2025)

### 方案 1: 調整 Build Phases 順序 (推薦)

**步驟**:

1. **開啟 Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **選擇 Runner target**
   - 左側專案導覽器選擇 `Runner`
   - 中間 TARGETS 選擇 `Runner`

3. **點選 Build Phases 標籤**

4. **調整順序** (重要!):

   **目標順序**:
   ```
   1. Dependencies
   2. [CP] Check Pods Manifest.lock
   3. Compile Sources
   4. Link Binary With Libraries
   5. Embed App Extensions  ← 必須在這個位置!
   6. Copy Bundle Resources
   7. [CP] Embed Pods Frameworks
   8. [CP] Copy Pods Resources
   9. Thin Binary  ← 必須在最後或倒數第二
   10. Run Script (其他)
   ```

   **具體操作**:
   - 找到 **Embed App Extensions** (或 **Embed Foundation Extensions**)
   - **拖曳**它到 **Copy Bundle Resources** 之後
   - **但在** **[CP] Embed Pods Frameworks** **之前**

   - 找到 **Thin Binary**
   - **拖曳**它到**最底部**(或倒數第二,如果有 Crashlytics)

5. **確認 Embed App Extensions 設定**
   - 展開 **Embed App Extensions**
   - 確認 `WeatherWidgetExtension.appex` 在列表中
   - **取消勾選** "Copy only when installing"
   - **勾選** "Code Sign On Copy"

6. **清理重建**
   ```bash
   # 在 Xcode 中
   Product → Clean Build Folder (⇧⌘K)

   # 在終端機中
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   mise exec -- pod install
   cd ..
   flutter run
   ```

---

### 方案 2: 修改 Podfile (輔助方案)

在 `ios/Podfile` 最後加入:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      # 修復建置順序問題
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'

      # 避免 Widget Extension 循環依賴
      if target.name.include?('Extension')
        config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
      end
    end
  end

  # 確保 Widget Extension 正確嵌入
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.user_project.native_targets.each do |target|
      if target.name == 'Runner'
        target.build_configurations.each do |config|
          # 確保建置階段正確執行
          config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
        end
      end
    end
  end
end
```

然後重新安裝:
```bash
cd ios
rm -rf Pods Podfile.lock
mise exec -- pod install
cd ..
flutter clean
flutter run
```

---

### 方案 3: 添加 Target Dependencies (確保依賴正確)

1. 在 Xcode 中選擇 **Runner** target
2. **Build Phases** → **Dependencies**
3. 點選 **+** 按鈕
4. 添加 **WeatherWidget** (或 **WeatherWidgetExtension**)
5. 確保它在列表中

---

### 方案 4: 檢查 Info.plist 處理順序

確保 **Process Info.plist File** 在 **Copy WeatherWidget** 之前執行:

1. 在 Build Phases 中找不到此項(通常是自動的)
2. 但可以確保 **Copy Bundle Resources** 在 **Embed App Extensions** 之後

---

## 🔍 驗證修復

執行以下命令確認沒有循環依賴:

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  clean build 2>&1 | grep -i cycle
```

**如果沒有輸出** = 修復成功! ✅

---

## 📊 Build Phases 順序檢查清單

使用此清單確認順序正確:

```
□ Dependencies (包含 WeatherWidget)
□ [CP] Check Pods Manifest.lock
□ Compile Sources
□ Link Binary With Libraries
□ Embed App Extensions (包含 WeatherWidgetExtension.appex)
  └─ ☑ Code Sign On Copy
  └─ ☐ Copy only when installing (取消勾選)
□ Copy Bundle Resources
□ [CP] Embed Pods Frameworks
□ [CP] Copy Pods Resources
□ Thin Binary (在最後或倒數第二)
□ Run Script (其他腳本)
```

---

## 🚨 常見錯誤

### 錯誤 1: Thin Binary 在 Embed App Extensions 之前
**症狀**: 循環依賴錯誤
**修復**: 移動 Thin Binary 到最底部

### 錯誤 2: Embed App Extensions 在 [CP] Embed Pods Frameworks 之後
**症狀**: 循環依賴錯誤
**修復**: 移動 Embed App Extensions 到 [CP] Embed Pods Frameworks 之前

### 錯誤 3: "Copy only when installing" 被勾選
**症狀**: Widget 在 Debug 模式不顯示
**修復**: 取消勾選此選項

### 錯誤 4: 沒有設定 Dependencies
**症狀**: Widget Extension 建置順序不正確
**修復**: 在 Dependencies 中添加 WeatherWidget target

---

## 🎯 推薦的完整修復流程

```bash
# 1. 在 Xcode 中調整 Build Phases 順序
open ios/Runner.xcworkspace
# (按照上述方案 1 操作)

# 2. 清理所有建置產物
flutter clean
cd ios
rm -rf Pods Podfile.lock DerivedData
mise exec -- pod deintegrate
mise exec -- pod install
cd ..

# 3. 重新建置
flutter run -v
```

---

## 💡 為什麼會發生這個問題?

### Xcode 15+ 的變化
- Xcode 15 引入了更嚴格的建置依賴檢查
- 循環依賴在之前版本可能被忽略,但現在會報錯

### Flutter + CocoaPods + Widget Extension
這個組合特別容易出現問題因為:
1. **Thin Binary**: Flutter 的腳本需要處理 Info.plist
2. **[CP] Embed Pods Frameworks**: CocoaPods 需要嵌入框架
3. **Copy WeatherWidget**: Widget Extension 需要被複製
4. 如果順序不對,會形成循環依賴

### 解決原理
正確的順序確保:
1. **先**嵌入 App Extension
2. **再**嵌入 Pods Frameworks
3. **最後**執行 Thin Binary 腳本

---

## 📚 參考資源

- [Flutter Issue #135056](https://github.com/flutter/flutter/issues/135056) - iOS app extension cycle error
- [Stack Overflow: Handling Cycle inside Runner](https://stackoverflow.com/questions/77138968/)
- [Apple Developer Forums: Xcode 15 Cycle Error](https://developer.apple.com/forums/thread/730974)

---

## 🔄 如果還是失敗...

如果嘗試了所有方案還是無法解決:

### 臨時解決方案
參考 [iOS_TEMP_FIX.md](iOS_TEMP_FIX.md) 移除 Widget Extension

### 替代方案
先在 Android 上使用 Widget,等待:
- Xcode 更新
- Flutter 更新
- CocoaPods 更新

---

## ✅ 成功案例

根據 GitHub 和 Stack Overflow 的回報,**方案 1**(調整 Build Phases 順序)在大多數情況下都能成功解決問題。

關鍵是確保:
1. ✅ Embed App Extensions 在 [CP] Embed Pods Frameworks **之前**
2. ✅ Thin Binary 在**最底部**
3. ✅ Dependencies 包含 Widget target
4. ✅ "Copy only when installing" **未勾選**

祝你修復順利! 🎉
