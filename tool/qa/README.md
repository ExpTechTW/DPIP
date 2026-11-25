# 地震分享圖 QA

在 DPIP 根目錄執行下列指令。請先啟動 iOS Simulator 或 Android Emulator，並將
`<device-id>` 換成 Flutter 裝置 ID，例如 `emulator-5554` 或 iOS 模擬器的 UDID。

```sh
tool/dev/qa_report_picture.sh <device-id>
```

首次使用時，先以專案鎖定的工具鏈解析依賴（已有本機快取可用
`tool/dev/deps.sh --offline`）。原生函式庫為選用建置輸入。若啟動器提示缺少產物，
請備妥相鄰的 `eq-report-pic` checkout，依平台執行其中一組指令。

```sh
tool/dev/build_report_picture.sh ios ../eq-report-pic
shasum -a 256 -c native/eq_report_pic/ios/SHA256SUMS

tool/dev/build_report_picture.sh android ../eq-report-pic
shasum -a 256 -c native/eq_report_pic/android/SHA256SUMS
```

建置腳本從固定 Git 修訂離線編譯，並一併放入字型。Rust targets、Xcode／Android NDK
版本與路徑見[原生建置說明](../../ARCHITECTURE.md#native-build-inputs)。
啟動器從版本庫讀取離線樣本，報告產圖可在斷網下操作。

## 手動檢查

- [ ] 讓「臺東縣近海 · 已查證」保持選取，按「產生 PNG」。看到「產圖成功」、
  `1920 × 1080 px`、ABI `1.3`、Capabilities `0x31f` 及 PNG SHA-256。
  尺寸來自解碼後的 PNG；可雙指放大檢視原圖。
- [ ] 在卡片上核對臺東縣近海、ML 3.9、深度 43.5 km、臺東縣震度 2、花蓮縣震度 1。
  QA 畫面顯示完整報告 ID `115000-2026-0422-111524`，以及 Core v2 原始本文 SHA-256。
  [縣市與五筆測站的查證紀錄](../../test/features/earthquake/domain/fixtures/share_input/README.md)
- [ ] 切到 4:5，確認解碼尺寸為 `1080 × 1350 px`。核對完整地名、最大震度 2、
  報告 ID、氣象署與 ExpTech Core v2 的完整署名及量表依據網址。
- [ ] 按「重新產生 PNG」，確認同格式與主題的 SHA-256 相同。切換深色再產圖，確認配色及 SHA-256
  改變，再重新產生一次確認深色也可重現。
- [ ] 選「缺少身分證據」或「美濃歷史報告」，按「產生 PNG」。確認各自顯示
  `missingSourceIdentity` 或 `missingAreaIdentity` 與 JSON Pointer；按「重試」可再次檢查。
  切回已查證樣本後應能成功產圖。
- [ ] 在尚未準備原生產物的環境，執行 `tool/dev/qa_report_picture.sh <device-id> --allow-missing-native`。
  按「產生 PNG」，確認顯示 `unavailable` 與建置提示。此旗標會略過啟動器的存在檢查，
  已安裝的原生產物仍會由建置系統納入。

## 回報與限制

請附上 Git SHA、模擬器 ID／系統與架構、樣本、主題、操作步驟及畫面截圖。若產圖成功，
附上 ABI、Capabilities、尺寸與 PNG SHA-256；若失敗，貼上完整錯誤碼、JSON Pointer
或 Native status，以及啟動指令的相關輸出。

本畫面提供離線 16:9 與 4:5 預覽。16:9 沿用既有來源列。
若需取出 PNG 檔案，執行
`tool/dev/qa_report_picture.sh <device-id> --smoke` 並依[原有 smoke 說明](../../ARCHITECTURE.md#offline-smoke-test)
取得 app 沙盒內的 16:9 PNG。另用 `tool/dev/qa_report_picture.sh <device-id> --smoke-4x5`
獨立驗證 1080×1350，輸出檔名為 `report-picture-4x5-light.png` 及
`report-picture-4x5-dark.png`。互動預覽可切換 16:9 與 4:5，並依各格式和主題比對重複產圖的 SHA-256。
原生資產的公開散布與實體裝置驗收仍適用[原生建置限制](../../ARCHITECTURE.md#native-build-inputs)。

## 正式 4:5 分享流程

在地震報告展開詳細資訊後，選取「地震分享圖」。目前可產圖的語言為繁體中文（臺灣），
可產圖的報告為與已查證之原始本文 SHA-256 完全相符的臺東縣近海
`115000-2026-0422-111524`。資料修訂後須重新查證。美濃歷史報告可用來驗證不支援狀態。
切換淺色與深色後，分別確認預覽、相簿原檔、系統分享所交付的 PNG 雜湊一致。
關閉後重新開啟，並確認前一次的產圖結果未混入新預覽。

### 實體裝置驗收

- iPhone、iPad 與 Android 實機確認詳情頁入口、兩種主題、旋轉與放大文字下的操作。
  iPad 確認系統分享視窗正確錨定。用 VoiceOver、TalkBack 確認可操作主題、存檔與分享。
- 驗證相簿新增權限的允許、拒絕及從設定重新開啟。Android API 26–28 另驗證舊版儲存權限。
- 從相簿匯出原檔並用系統分享交付給接收端，比對原始 PNG 雜湊。確認取消系統分享可回到預覽。

### 發行驗收

- 確認發布所含的原生函式庫、字型及相關聲明，並審查原生資產散布權利。
- 以簽署後的候選安裝包驗證 iOS device slice、Android 支援的 ABI 與 16 KB 頁面相容性，
  確認 ABI 1.3 的 4:5 能力可用，且 bit 10 維持關閉。
- 確認發行所需的可分享報告涵蓋範圍。新增支援須具備能綁定至原始本文的來源、行政區、
  測站、震度量表和規模種類證據。
