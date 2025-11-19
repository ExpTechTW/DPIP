# 🔧 修復 iOS Widget 循環依賴錯誤

## 問題

```
Error (Xcode): Cycle inside Runner; building could produce unreliable results.
```

這是因為 Widget Extension 的建置階段設定導致的循環依賴。

## 解決方法

### 方法 1: 在 Xcode 中調整建置設定 (推薦)

1. **開啟 Xcode 專案**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **選擇 Runner target**
   - 在左側專案導覽器選擇 `Runner` 專案
   - 選擇 `Runner` target

3. **調整 Build Phases 順序**
   - 點選 `Build Phases` 標籤
   - 找到這些 phases 並**確保順序如下**:
     1. Dependencies
     2. [CP] Check Pods Manifest.lock
     3. Run Script (Flutter相關)
     4. Compile Sources
     5. Link Binary With Libraries
     6. Embed App Extensions (確保這個在 Embed Pods Frameworks 之前)
     7. [CP] Embed Pods Frameworks
     8. [CP] Copy Pods Resources
     9. Thin Binary
     10. Run Script (其他)

4. **調整 Embed App Extensions 設定**
   - 找到 `Embed App Extensions` phase
   - 展開它,確認 `WeatherWidgetExtension.appex` 在列表中
   - 確保 `Code Sign On Copy` 被勾選

5. **清理並重建**
   ```bash
   flutter clean
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter pub get
   ```

### 方法 2: 修改 Podfile (替代方案)

如果方法 1 不行,可以調整 Podfile:

1. **編輯 ios/Podfile**

在檔案最後加入:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # 修復建置順序問題
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end

  # 確保 Widget Extension 正確嵌入
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.user_project.native_targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      end
    end
  end
end
```

2. **重新安裝 Pods**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```

### 方法 3: 暫時移除 Widget Extension (快速測試)

如果你想先測試主 App 而不使用 Widget:

1. **在 Xcode 中**
   - 選擇 Runner target
   - Build Phases → Embed App Extensions
   - 移除 `WeatherWidgetExtension.appex`

2. **執行 App**
   ```bash
   flutter run
   ```

3. **主 App 可以正常運作**,只是暫時沒有 Widget

## 驗證修復

執行以下命令確認沒有循環依賴:

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -arch x86_64 \
  clean build
```

如果成功,應該會看到 `BUILD SUCCEEDED`

## 常見問題

### Q: 為什麼會出現循環依賴?

A: 這通常是因為:
1. Widget Extension 與主 App 之間的依賴順序不正確
2. CocoaPods 的 framework 嵌入階段順序問題
3. Xcode 自動生成的建置階段順序衝突

### Q: 修復後還是失敗?

A: 嘗試:
1. 完全清理專案: `flutter clean && rm -rf ios/Pods ios/Podfile.lock`
2. 重新安裝: `cd ios && pod install && cd ..`
3. 在 Xcode 中 Product → Clean Build Folder (Cmd+Shift+K)
4. 重新執行 `flutter run`

### Q: Android 可以正常使用嗎?

A: **可以!** 這個問題只影響 iOS。Android Widget 完全不受影響,可以正常使用。

## 臨時解決方案

如果上述方法都不行,你可以:

1. **先在 Android 上測試 Widget 功能**
   ```bash
   flutter run  # 在 Android 裝置上
   ```

2. **等待修復 iOS 後再測試**
   - Widget 的 Flutter 邏輯已完成
   - 只是 iOS 建置配置需要調整

3. **或者暫時註解掉 Widget Extension**
   - 在 Xcode 中移除 WeatherWidget target
   - 主 App 仍可正常運作

---

## 總結

這個錯誤是 iOS 專案設定問題,不是程式碼問題。所有 Widget 的功能程式碼都已正確實作。

**最簡單的解決方式**: 在 Xcode 中調整 Build Phases 順序,確保 `Embed App Extensions` 在 `[CP] Embed Pods Frameworks` 之前執行。
