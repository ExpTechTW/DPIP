# 地震分享圖 QA

在 DPIP 根目錄執行。相鄰的 eq-report-pic checkout 須含有合併提交
`6c2ca6e21c9a50cd386d5c83064a261227a49326`（Rust #19）。原生 staging
使用此提交的驗證器、固定的 Git tree 與兩份獨立核准的 manifest SHA-256。
需要 Xcode 與 Android NDK `28.2.13676358`。

```sh
export DPIP_EQR_BUILD="/Users/yincheng/development/eq-report-pic/out/v3-post-merge.nh4HTH/native"
rust_checkout="/Users/yincheng/development/eq-report-pic"
```

啟動器每次把已驗證的套件放入新的 staging 目錄。Flutter Hot Reload 沿用該次
建置連結的 Rust 函式庫。若需重建套件，`tool/dev/build_report_picture.sh` 接受
Rust checkout 和新的絕對輸出目錄。重建結果仍須符合核准的 manifest SHA-256。

## 從一般地震報告詳情頁操作

```sh
# 裝置 ID 請依環境替換。
ios_device_id=F7FD1D34-DDAD-4EF9-96E6-879F9ADBD34C
android_device_id=emulator-5554
report_route=/data/earthquake/115000-2026-1124-161135

run_report() {
  tool/dev/run_report_sharing.sh "$1" "$2" "$3" "$rust_checkout" \
    "$DPIP_EQR_BUILD/packages/$2" "$DPIP_EQR_BUILD/trusted/$2.json" \
    --no-pub --route "$report_route"
}

run_report ios production "$ios_device_id"
run_report ios qa "$ios_device_id"
run_report android production "$android_device_id"
run_report android qa "$android_device_id"
```

首次安裝會先顯示初次設定。選擇繁體中文（臺灣）後，重新執行上方指令可直接開啟
指定報告。點地圖右上角、地圖設定左邊的分享按鈕。詳情展開時，也可從
標頭右側開啟分享面板。修改 Flutter 元件後，可在仍在執行的終端機按 `r`。
UI 的修改入口在
[earthquake_share_sheet.dart](../../lib/features/earthquake/presentation/widgets/earthquake_share_sheet.dart)
的 `EarthquakeShareSheet` 和
[report_detail_page.dart](../../lib/features/earthquake/presentation/pages/report_detail_page.dart)
的 `_openShare`。調整介面文案時編輯 `lib/l10n/app_*.arb`，執行
`tool/dev/l10n.sh` 後再 Hot Reload。

| 版型 | 尺寸 | 地圖模式 | 主題 | 組數 |
|---|---|---|---|---:|
| 16:9 | 1920 × 1080 | 群集、測站、鄉鎮 | 淺色、深色 | 6 |
| 4:5 | 1080 × 1350 | 版型固定 | 淺色、深色 | 2 |
| 9:16 | 1080 × 1920 | 群集、測站、鄉鎮 | 淺色、深色 | 6 |

切換選項時，應保留上一張預覽。複製、儲存和分享固定在底部，待所選圖片解碼完成後
可操作。切回已產圖的組合時，快取命中不會顯示載入動畫。從不同地圖模式回到 4:5
應選到同一張資訊卡。關閉分享面板再開啟時應重新產圖。改選報告時確認舊結果無法匯出。
以 `115000-2026-0422-111524` 開啟臺東縣近海樣本時，應顯示 ML 3.9、深度
43.5 km、臺東縣震度 2 與花蓮縣震度 1。v3 使用與詳情相同的原始本文和快照內身分。
來源不可信或屬於未驗證歷史報告時，分享面板應顯示不支援。另檢查非臺灣繁體中文顯示的語言狀態。
[現代與歷史樣本清單](../../test/features/earthquake/domain/fixtures/share_input_v3/corpus.json)

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
tool/dev/qa_report_picture.sh "$ios_device_id" --smoke-4x5
tool/dev/qa_report_picture.sh "$ios_device_id" --smoke-story
tool/dev/qa_report_picture.sh "$android_device_id" --smoke-4x5
tool/dev/qa_report_picture.sh "$android_device_id" --smoke-story
tool/dev/qa_report_picture.sh "$device_id" --smoke-matrix
```

煙霧測試驗證 v3 臺東樣本、支援的版型、原生符號及遮罩，以及工作 isolate 排隊、原生錯誤、重試與釋放。
矩陣另逐幅解碼十四張圖，記錄尺寸、SHA-256、產圖耗時及程序 RSS。兩個工具 target
只用於 QA。在 iOS 的 App 沙盒 `Documents/report-picture-matrix`，或 Android 的
`run-as com.exptech.dpip.storyqa` 下的 `app_flutter/report-picture-matrix`，
可以取得原始 PNG 和 `matrix.json`。完成後再啟動上方的一般詳情頁流程。

主機可對六份來源樣本執行核准 PNG 的位元組比對。每個程序只載入一個 profile。
下列指令使用交接目錄內的 ABI 1.4 macOS 函式庫與已核准的參考輸出。

```sh
export DPIP_EQR_MATRIX_REFERENCE="$rust_checkout/out/v3-delivery.NTkfMT/matrix-one"
for profile in production qa; do
  DPIP_EQR_MATRIX_PROFILE="$profile" \
    DPIP_EQR_MATRIX_LIBRARY="$(dirname "$DPIP_EQR_BUILD")/host-$profile/release/libeq_report_pic.dylib" \
    tool/dev/test.sh test/shared/seismic/report_picture_v3_matrix_test.dart
done
```

## 最終套件查核與發行限制

```sh
tool/dev/verify_report_picture_package.sh ios "$app_bundle" "$ios_stage" "$link_map"
tool/dev/verify_report_picture_package.sh android "$apk" "$android_stage" "$zipalign"
```

`stage` 指 launcher 輸出路徑底下的 `qa` 或 `production` 目錄。iOS 使用同次
建置的 `Runner-LinkMap-normal-arm64.txt`。Android 使用 SDK Build Tools 的
`zipalign`。正式設定將啟動參數改成 `production`，候選目錄及 manifest 一併切換。
正式 app 只提供 16:9 和 4:5。ABI 為 1.4，production 遮罩為 `0xb1f`，QA 為 `0x1b1f`，兩者的 bit 10 皆關閉。

Story 保留「開發預覽・底圖完整性未驗證」頁尾。底圖與字型散布權利、地理完整性、
實體裝置簽署版本與公開發行需各自驗收。Rust #17 將臺東樣本標為「小區域有感地震」。
完整的來源 ID 仍用於查證與匯出檔名。
