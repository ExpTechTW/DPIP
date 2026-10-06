## 這個 PR 做了什麼

接著 #584，把測試套件還沒碰到的程式庫補上測試。行覆蓋率從 **66.23% 提高到 94.48%**，零覆蓋的檔案從 26 個減到 2 個（`lib/bootstrap.dart`、`lib/main.dart`）。

|  | main（`fcd37d29`） | 這個 PR |
|---|---|---|
| 行覆蓋率 | 66.23%（22,631／34,170） | **94.48%**（32,345／34,233） |
| 零覆蓋的檔案 | 26 | 2 |
| 完全覆蓋的檔案 | 199 | 296 |
| 測試數 | 2,517 | 2,949（+432） |

兩邊都用 `tool/dev/coverage.sh` 在同一台機器上量測；main 的數字是在獨立的 worktree 量的。

### 改動內容

一個 commit（`4b5900b9`），共 156 個檔案：

- **新增 120 個測試檔。**
- **35 個既有測試檔加了案例。**
- **唯一動到正式程式碼的是 `lib/core/meshtastic/data/meshtastic_client_impl.dart`**，只是加上測試用的注入點，正式環境的行為不變：
  - 建構子可以注入 `MeshtasticClient`、藍牙支援檢查、adapter 狀態串流、已連線／系統裝置清單，以及 adapter 等待逾時。不注入時一律使用原本的 `FlutterBluePlus`。
  - `channelConfirmTimeout`（`@visibleForTesting`，預設 8 秒）讓測試不必真的等完 managed-mode radio 的 8 秒逾時。
  - 計算收包量的那個常駐訂閱，改成用 `_rxHooked` 確保只掛一次，注入的 client 也會被計數。正式環境一樣只在第一次建立 client 時掛上。

### 覆蓋率增加最多的區域

| 區域 | 新增覆蓋行數 |
|---|---|
| `lib/features/map` | +2,545 |
| `lib/features/earthquake` | +1,439 |
| `lib/core` | +1,145 |
| `lib/shared` | +939 |
| `lib/features/home` | +906 |
| `lib/features/meshtastic` | +561 |
| `lib/features/weather` | +507 |
| `lib/app` | +376 |

單一檔案增加最多的：

| 檔案 | 覆蓋行數（前 → 後／總行數） |
|---|---|
| `features/earthquake/presentation/pages/report_detail_page.dart` | 0 → 657／659 |
| `shared/map/map_scaffold.dart` | 0 → 542／682 |
| `features/earthquake/presentation/pages/report_replay_page.dart` | 0 → 529／535 |
| `features/map/presentation/widgets/typhoon_panel.dart` | 1 → 525／540 |
| `features/meshtastic/presentation/pages/meshtastic_page.dart` | 307 → 803／846 |
| `features/map/presentation/widgets/station_sheet.dart` | 39 → 480／520 |
| `features/weather/presentation/pages/weather_ranking_page.dart` | 0 → 410／435 |
| `core/meshtastic/data/meshtastic_client_impl.dart` | 32 → 417／419 |
| `features/map/presentation/widgets/dpm_sheet.dart` | 0 → 264／275 |
| `features/map/presentation/layers/disaster_map_layer.dart` | 32 → 292／311 |

### 還沒覆蓋的

- `lib/bootstrap.dart`（160 行）：開資料庫、Firebase、通知 plugin 的啟動流程，要測得先替整條啟動鏈做測試替身，另開 PR 處理。
- `lib/main.dart`（1 行）。

## 相關 issue

沒有對應的 issue。前一階段是 #584（已合併）。

## 怎麼驗

- `tool/dev/coverage.sh` 在這個分支跑完整套件：2,949 個測試全數通過，上表數字就是這次的結果。
- `tool/dev/analyze.sh` 無問題；`tool/check/commits.sh origin/main..HEAD` 通過；layering、l10n、storage、tooling 四道 gate 都通過。
- `meshtastic_client_impl.dart` 是這個 PR 唯一動到的正式程式碼，請 review 時特別看：
  - 沒有注入時，每個注入點都退回原本的 `FlutterBluePlus` 呼叫。
  - 收包計數的訂閱在正式環境仍然只掛一次。
- 實機沒有影響可看：除了上面這個檔案的注入點，其餘都是 `test/` 底下的改動。

## 檢查清單

- [x] `tool/check/commits.sh origin/main..HEAD` 通過
- [x] 一個 commit 一件事（補測試；正式程式碼只加測試注入點）
- [x] `tool/dev/analyze.sh` 與 `tool/dev/test.sh` 通過
- [x] 沒有新的使用者可見字串
- [x] 沒有 UI 變更
