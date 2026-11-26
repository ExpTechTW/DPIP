# 地震分享圖 QA

在 DPIP 根目錄執行。相鄰的 eq-report-pic checkout 必須含有已合併的
`76662bb9710eafa2a77a694605513163db7c5967`（Rust #17）。需要 Rust 鎖定工具鏈、
Xcode、Android NDK `28.2.13676358`，以及 Rust 的 iOS arm64、iOS Simulator
arm64／x86_64、Android arm64／x86_64 targets。

```sh
DPIP_EQR_BUILD="$PWD/native/eq_report_pic/reviewed-76662bb"
mkdir -p "$(dirname "$DPIP_EQR_BUILD")"
tool/dev/build_report_picture.sh ../eq-report-pic "$DPIP_EQR_BUILD"
export DPIP_EQR_BUILD
```

已備妥相同修訂的可信套件時可直接設定 `DPIP_EQR_BUILD`。自行建置時輸出須為新目錄。
腳本從已審查的 Git 修訂建置兩個 profile，並在套件目錄外
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

切換到首次選取的組合時，確認載入期間複製、儲存和分享按鈕消失。切回同一個已完成
的版型、地圖模式和主題，應立即回到原圖。從不同地圖模式回到 4:5 應選到同一張資訊卡。
關閉對話框再開啟，應重新產圖。改選報告時確認舊結果無法匯出。
臺東縣近海樣本應顯示 ML 3.9、深度 43.5 km、
臺東縣震度 2 與花蓮縣震度 1。報告舊版資料請看
[原始本文與身分證據](../../test/features/earthquake/domain/fixtures/share_input/README.md)。
現有報告若缺少身分或行政區證據，應顯示不支援。另檢查非臺灣繁體中文顯示的語言狀態。

選一張圖，依序複製、儲存和分享，確認接收方讀到相同尺寸及 SHA-256。先關閉分享
對話框，再到支援貼上圖片的 App 貼上。iOS 以 `public.png` 存入系統剪貼簿。
Android 用獨立的私有目錄提供唯讀 URI，最多保留四張、每張上限 16 MiB，滿一小時
後在程序存活期間清理，或於下次初始化時清理。Android 13 以上由系統提示複製成功。
以兩個獨立接收 App 驗證對話框關閉後貼上。iOS 26.5 讀回 1080 × 1350，
Android 17 讀回 1080 × 1920，兩者皆以 PNG 解碼並逐張與 Rust 輸出核對 SHA-256。

另在 iOS 拒絕新增照片後確認仍可複製，再從設定授權並測試儲存。Android API 29
以上透過 MediaStore 寫入，API 26–28 需另驗證舊版儲存授權。iPad 的系統分享視窗
應錨定至發送按鈕。

## iOS 詳情底部面板量測

三個隔離 Debug 建置固定 Flutter 3.50.1，Framework
`ae9b586f34a8443573f82ef57c3bf914a908cbf7`，Engine
`4d35714800b9266b6693a58e1225ecd7e9e45ed7`。同一台 iPhone 17 Pro／iOS 26.5
模擬器開啟相同報告，面板先展開，再各執行十次下拉與十次上拉。
`FrameTiming` 記錄擷取期間的 Flutter build 和 raster 時間。

| 建置 | 警告數 | 取樣幀數 | Build p95 | Raster p95 | 任一階段超過 16.67 ms |
|---|---:|---:|---:|---:|---:|
| main `77f8049a` | 30 | 650 | 4.71 ms | 3.16 ms | 3 |
| PR #681 `708b1fe0` | 48 | 1,696 | 3.46 ms | 1.55 ms | 4 |
| 整合檢查點 `1ca3b4eb` | 33 | 753 | 4.12 ms | 2.61 ms | 5 |

Flutter 的 iOS 觸控分支用單調時鐘的當下時間推算目標，display link 則以其 frame
時間推算。兩條路徑的目標逆序時，`BeginFrame` 將時間戳夾回上一值，因此三個版本
都能觸發同一項警告。PR #681 與整合版另錄製 DevTools 的 VM timeline，兩者皆有
平台視圖合成、面板 extent 更新與 layout，但未觀察到 `BaseMap`、`MapLibreMap`
或完整詳情內容跟著每次拖曳重建。下拉跨過門檻時才會重設捲動位置，分享圖僅在
按下按鈕後產生。這組 Debug 取樣同時有少數慢幀，現有證據不足以定位為此次整合的
掉幀回歸。這次未修改面板。參見 [Flutter #197370](https://github.com/flutter/flutter/issues/197370)、
[Flutter #191444](https://github.com/flutter/flutter/pull/191444)。

實機可使用上方啟動指令，將設定與套件路徑改成 `production` 並加上 `--profile`。
在 DevTools Performance 錄製相同拖曳，分別記錄 UI、raster 與卡頓時的 timeline，
供上游修正釋出後以同一手法比對。

## 分享圖快取量測

Android 17 Pixel 10 Pro 模擬器的 Debug QA 建置使用固定 Rust 修訂與已驗證的臺東
報告，在兩個冷啟動程序中各依序選取十四種組合，再重跑同一輪。時間從提交選項量到
PNG 可供預覽及匯出，使用離線報告 fixture，未包含網路或面板合成時間。

| 量測 | 檢查點 `1ca3b4eb` | 加入快取 |
|---|---:|---:|
| 第一輪 FFI 呼叫 | 14 | 14 |
| 第二輪 FFI 呼叫 | 14 | 0 |
| 第二輪 PNG 就緒時間中位數 | 842 ms | 1.35 ms |
| 第二輪程序 RSS 中位數 | 549 MiB | 555 MiB |
| 整次程序 RSS 峰值 | 626 MiB | 601 MiB |
| 快取內壓縮 PNG | 0 | 14 張，共 2.90 MiB |

兩輪每張圖的 SHA-256 逐一相同。上限維持 8 MiB 與 14 筆，依最近使用順序淘汰，
記憶體壓力時釋出快取，目前預覽與進行中的匯出保有原圖。RSS 為單次模擬器程序
取樣，包含 Flutter 引擎及原生渲染期間的配置。

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
實體裝置簽署版本與公開發行需各自驗收。Rust #17 將臺東樣本標為「小區域有感地震」。
完整的來源 ID 仍用於查證與匯出檔名。
