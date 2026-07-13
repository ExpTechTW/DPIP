# DPIP API 對照表

區域綁定的端點 —— 經 DNS 負載平衡的裸主機（`api.lb`、`api.core`）一律不使用。
區域由 `RegionSelection` 狀態決定；多活（multi-active）層級會在其各區域之間容錯切換。

- **區域：** LB = `tpe1`（台北）、`khh1`（高雄）；Core = `tyo1`（東京）、
  `tnn1`（台南）。
- **路徑前綴：** 所有路徑都是 `/api/...`（由 curl 於 2026-07 驗證）。
- **層級（Tier）：** `lbApi` = LB（多活）、`coreApi` = Core（多活）、
  `coreExclusiveApi` = 僅 `api.core-tnn1`、`coreStaticExclusive` =
  僅 `static.core-tnn1`、`legacyApi` = `api-1`（尚未遷移）。

> 這是**端點目錄**，不是程式碼對照表。沒有 `lib/api/` 巨石檔：每個端點在其所屬
> feature 的 `data/`（基礎設施則在 `core/`）裡，於該功能實作時各自建成一個輕薄的
> datasource，並帶著自己的 `ApiTier`。目前已上線：地震 EEW
> （`features/earthquake/data/earthquake_api.dart`）、雷達
> （`features/weather/data/radar_api.dart`）。其餘皆為預先登錄，待其功能落地。
>
> **對時不是 HTTP 端點。** App 的時鐘使用真正的 **SNTP**
> （`flutter_ntp`，UDP/123），對 `time.exptech.com.tw`（主）/
> `time.apple.com`（備），而非 `/ntp` HTTP 呼叫 —— 見
> `core/realtime/ntp_time_source.dart` 與 `app_time.dart`（`AppTime.utc` /
> `AppTime.utc8`）。

## 多活備援 (multi-active)

| 方法 | 路徑 | 層級 | 主機（容錯順序 = 選定區域優先） |
|---|---|---|---|
| `openEewSse` | `/api/v2/eq/eew?sse=1` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getRtsRealtime` | `/api/v2/trem/rts` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getEewRealtime` | `/api/v2/eq/eew` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getReportList` | `/api/v2/eq/report` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `getReport` | `/api/v2/eq/report/{id}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |

> **即時串流走 SSE，不是輪詢。** `?sse=1` 旗標會把端點切換成
> `text/event-stream`：每個事件的 `data:` 就是純 GET 會回傳的**同一份 JSON**
> （模型不變），改為在變動時推送，而非每秒拉取。`openEewSse` 是 EEW 的即時傳輸
> （`getEewRealtime` 保留為一次性快照）；RTS 落地時，`/api/v2/trem/rts?sse=1`
> 是同樣的形狀。傳輸、緩衝與重連都藏在即時 `RealtimeSource` seam 後面
> （`core/realtime/sse_realtime_source.dart`）—— channel、過期分類器與生命週期都不變。
> EEW 是**突發型**（地震之間靜默 → 存活判定用「連線開著」）；RTS 是**連續型**
> （約 1 Hz → 存活判定用「最近有事件」）。

## 沒多活備援 (single host, no failover)

**雷達（v2，已上線）** —— 僅 `core-tnn1`，跨兩個 exclusive 層級。時間清單是
差量編碼的 Unix 秒（`[baseSec, Δ, …]`），在 API 主機上帶 ETag/304；tile 是 WebP，
放在 **static** 主機（由 MapLibre 直接抓取，`Cache-Control: max-age=300`）。
`{sec}` 就是解出清單後的 10 位數秒，直接使用。

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `getFrames` | `/api/v2/tiles/radar/list` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `tileUrl` | `/api/v2/tiles/radar/{sec}/{z}/{x}/{y}.webp` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

Legacy `api-1`（待後端部署後移至 `core-tnn1`）—— 皆為預先登錄，待其功能落地：

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `getRtsAt` | `/api/v2/trem/rts/{sec}` | `legacyApi` | `api-1.exptech.dev` |
| `getEewAt` | `/api/v2/eq/eew/{sec}` | `legacyApi` | `api-1.exptech.dev` |
| `getStations` | `/api/v1/trem/station` | `legacyApi` | `api-1.exptech.dev` |
| `getMeteorStation` | `/api/v2/meteor/station/{id}` | `legacyApi` | `api-1.exptech.dev` |
| `getWeatherList` | `/api/v2/meteor/weather/list` | `legacyApi` | `api-1.exptech.dev` |
| `getWeather` | `/api/v2/meteor/weather/{time}` | `legacyApi` | `api-1.exptech.dev` |
| `getWeatherRealtime` | `/api/v3/weather/realtime/{lat},{lon}` | `legacyApi` | `api-1.exptech.dev` |
| `getWeatherForecast` | `/api/v3/weather/forecast/{region}` | `legacyApi` | `api-1.exptech.dev` |
| `getRainList` | `/api/v2/meteor/rain/list` | `legacyApi` | `api-1.exptech.dev` |
| `getRain` | `/api/v2/meteor/rain/{time}` | `legacyApi` | `api-1.exptech.dev` |
| `getLightningList` | `/api/v2/meteor/lightning/list` | `legacyApi` | `api-1.exptech.dev` |
| `getLightning` | `/api/v2/meteor/lightning/{time}` | `legacyApi` | `api-1.exptech.dev` |
| `getTyphoonImagesList` | `/api/v2/meteor/typhoon/images/list` | `legacyApi` | `api-1.exptech.dev` |
| `getTyphoonGeojson` | `/api/v2/meteor/typhoon/geojson` | `legacyApi` | `api-1.exptech.dev` |
| `getTsunami` | `/api/v1/tsunami/{id}` | `legacyApi` | `api-1.exptech.dev` |
| `getRealtimeList` | `/api/v1/dpip/realtime/list` | `legacyApi` | `api-1.exptech.dev` |
| `getHistoryList` | `/api/v1/dpip/history/list` | `legacyApi` | `api-1.exptech.dev` |
| `getRealtimeRegion` | `/api/v1/dpip/realtime/{region}` | `legacyApi` | `api-1.exptech.dev` |
| `getHistoryRegion` | `/api/v1/dpip/history/{region}` | `legacyApi` | `api-1.exptech.dev` |
| `getEvent` | `/api/v1/dpip/event/{id}` | `legacyApi` | `api-1.exptech.dev` |
| `✅ updateDeviceLocation` | `/api/v2/location/{platform}/{token}/{version}/{lat},{lng}` | `legacyApi` | `api-1.exptech.dev` |
| `✅ getNotify` | `/api/v2/notify/{token}` | `legacyApi` | `api-1.exptech.dev` |
| `✅ setNotify` | `/api/v2/notify/{token}/{channel}/{status}` | `legacyApi` | `api-1.exptech.dev` |

## 暫時無 (unavailable)

| 方法 | 說明 |
|---|---|
| `getTsunamiList` | 暫時無法使用 —— 會拋出 `UnsupportedError`。 |

## 外部（第三方，無區域）

| 方法 | URL |
|---|---|
| `getLocalizationProgress` | `https://exptech.dev/api/v1/dpip/locale` |
| `getReleases` | `https://api.github.com/repos/ExpTechTW/DPIP-Pocket/releases` |

## curl 可用性（2026-07-14，HTTP 狀態碼）

| 端點 | lb-tpe1 | lb-khh1 | core-tyo1 | core-tnn1 | api-1 |
|---|:--:|:--:|:--:|:--:|:--:|
| `/api/v2/trem/rts` | 200 | 200 | 404 | 401 | 200 |
| `/api/v2/eq/eew` | 200 | 200 | 200 | 200 | 404 |
| `/api/v2/eq/report` | 404 | 404 | 200 | 200 | 404 |
| `/api/v1/trem/station` | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/meteor/weather/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v1/dpip/realtime/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/tiles/radar/list` | 404 | 404 | 404 | 200 | 404 |
| `/api/v1/tsunami/list` | 404 | 404 | 404 | 404 | 404 |
| `/api/v2/eq/eew?sse=1` | 200 | 200 | 200 (json) | 401 | 404 |
| `/api/v2/trem/rts?sse=1` | 200 | 200 | 404 | 401 | 200 (json) |

雷達 **tile** 不在這張表裡 —— 它們由 `static.core-tnn1.exptech.dev` 提供
（`/api/v2/tiles/radar/{sec}/{z}/{x}/{y}.webp`，`image/webp`），和上面的時間清單
是不同主機。

只有 `lb-tpe1` / `lb-khh1` 對 `?sse=1` 回傳真正的 `text/event-stream`；
`200 (json)` = HTTP 200 但為 `application/json`（旗標被忽略）—— `core-tyo1` 之於
`eew?sse=1`、`api-1` 之於 `rts?sse=1`。`core-tnn1` 對兩者都回 401。這就是 SSE
串流固定用 `lbApi` 的原因。
