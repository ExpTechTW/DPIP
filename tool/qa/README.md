# 地震分享圖 QA

在 DPIP 根目錄執行。相鄰的 eq-report-pic checkout 必須含有已合併的
`e9f066fb83fabfcd2184d1483d34212534b64e6e`（Rust #16）。需要 Rust 鎖定工具鏈、
Xcode、Android NDK `28.2.13676358`，以及 Rust 的 iOS arm64、iOS Simulator
arm64／x86_64、Android arm64／x86_64 targets。

```sh
DPIP_EQR_BUILD="$PWD/native/eq_report_pic/reviewed-e9f066f"
mkdir -p "$(dirname "$DPIP_EQR_BUILD")"
tool/dev/build_report_picture.sh ../eq-report-pic "$DPIP_EQR_BUILD"
export DPIP_EQR_BUILD
```

建置輸出須為新目錄。腳本從已審查的 Git 修訂建置兩個 profile，並在套件目錄外
產生個別的可信 manifest。使用來自受信任建置或受控管道的 manifest。啟動器每次把
已驗證的套件放入新的 staging 目錄。Flutter Hot Reload 沿用該次建置連結的 Rust 函式庫。

## 從一般地震報告詳情頁操作

```sh
# device_id 請換成模擬器 UDID 或 Android Emulator ID
report_route=/data/earthquake/115000-2026-0422-111524

tool/dev/run_report_sharing.sh ios qa "$ios_device_id" ../eq-report-pic \
  "$DPIP_EQR_BUILD/packages/qa" "$DPIP_EQR_BUILD/trusted/qa.json" \
  --no-pub --route "$report_route"

tool/dev/run_report_sharing.sh android qa "$android_device_id" ../eq-report-pic \
  "$DPIP_EQR_BUILD/packages/qa" "$DPIP_EQR_BUILD/trusted/qa.json" \
  --no-pub --route "$report_route"
```

首次安裝會先顯示初次設定。選擇繁體中文（臺灣）後，重新執行上方指令可直接開啟
臺東縣近海報告。展開詳情卡片後點「地震分享圖」。修改 Flutter 元件後，在還在執行的
終端機按 `r`。UI 的修改入口在
[earthquake_share_dialog.dart](../../lib/features/earthquake/presentation/widgets/earthquake_share_dialog.dart)
的 `EarthquakeShareDialog`、`_ShareChoices`、`_PngPreview` 與
[report_detail_page.dart](../../lib/features/earthquake/presentation/pages/report_detail_page.dart)
的 `_expandedContent`。調整介面文案時編輯 `lib/l10n/app_*.arb`，執行
`tool/dev/l10n.sh` 後再 Hot Reload。

| 版型 | 尺寸 | 地圖模式 | 主題 | 組數 |
|---|---|---|---|---:|
| 16:9 | 1920 × 1080 | 群集、測站、鄉鎮 | 淺色、深色 | 6 |
| 4:5 | 1080 × 1350 | 版型固定 | 淺色、深色 | 2 |
| 9:16 | 1080 × 1920 | 群集、測站、鄉鎮 | 淺色、深色 | 6 |

切換選項後，確認載入時儲存與分享按鈕消失，完成後回到同一張預覽。關閉對話框、
改選報告再開啟，確認舊結果無法匯出。臺東縣近海樣本應顯示 ML 3.9、深度 43.5 km、
臺東縣震度 2 與花蓮縣震度 1。報告舊版資料請看
[原始本文與身分證據](../../test/features/earthquake/domain/fixtures/share_input/README.md)。
現有報告若缺少身分或行政區證據，應顯示不支援。另檢查非臺灣繁體中文顯示的語言狀態。

確認相簿新增影像原檔的 SHA-256 與系統分享交付的檔案一致。iOS 驗證拒絕新增照片、
從設定授權、再按儲存。Android API 29 以上透過 MediaStore 寫入，API 26–28
需另驗證舊版儲存授權。iPad 系統分享視窗應錨定至發送按鈕。

## 離線煙霧測試與矩陣

```sh
tool/dev/qa_report_picture.sh "$device_id" --smoke-story
tool/dev/qa_report_picture.sh "$device_id" --smoke-matrix
```

煙霧測試驗證已查證臺東樣本，包含工作 isolate 排隊、原生錯誤、重試與釋放。
矩陣另逐幅解碼十四張圖，記錄尺寸、SHA-256、產圖耗時及程序 RSS。兩個工具 target
只用於 QA。在 iOS 的 App 沙盒 `Documents/report-picture-matrix`，或 Android 的
`run-as com.exptech.dpip.storyqa` 下的 `app_flutter/report-picture-matrix`，
可以取得原始 PNG 和 `matrix.json`。完成後再啟動上方的一般詳情頁流程。

## 最終套件查核與發行限制

```sh
tool/dev/verify_report_picture_package.sh ios "$app_bundle" "$ios_stage" "$link_map"
tool/dev/verify_report_picture_package.sh android "$apk" "$android_stage" "$zipalign"
```

`stage` 指 launcher 輸出路徑底下的 `qa` 或 `production` 目錄。iOS 使用同次
建置的 `Runner-LinkMap-normal-arm64.txt`。Android 使用 SDK Build Tools 的
`zipalign`。正式設定將啟動參數改成 `production`，候選目錄及 manifest 一併切換。
正式 app 只提供 16:9 和 4:5。ABI 維持 1.3、能力遮罩為 `0x31f`，bit 10 關閉。

Story 保留「開發預覽・底圖完整性未驗證」頁尾。底圖與字型散布權利、地理完整性、
實體裝置簽署版本與公開發行需各自驗收。Rust #17 尚未合併時，本分支維持 Rust #16
的報告識別碼呈現。
