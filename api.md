# DPIP API 對照表

區域綁定的端點 —— 經 DNS 負載平衡的裸主機（`api.lb`、`api.core`）一律不使用。
區域由 `RegionSelection` 狀態決定；多活（multi-active）層級會在其各區域之間容錯切換。

- **區域：** LB = `tpe1`（台北）、`khh1`（高雄）；Core = `tyo1`（東京）、
  `tnn1`（台南）。
- **路徑前綴：** 所有路徑都是 `/api/...`。
- **層級（Tier）：** `lbApi` = LB（多活）、`coreApi` = Core（多活）、
  `coreExclusiveApi` = 僅 `api.core-tnn1`、`coreStaticExclusive` =
  僅 `static.core-tnn1`、`legacyApi` = 舊 server `api-1`（逐步淘汰中）。

> 這是**端點目錄**，不是程式碼對照表。沒有 `lib/api/` 巨石檔：每個端點在其所屬
> feature 的 `data/`（基礎設施則在 `core/`）裡，各自建成一個輕薄的 datasource，
> 並帶著自己的 `ApiTier`（`core/network/api_region.dart`）；路徑字串集中於
> `core/network/api_paths.dart`（與 `EtagInterceptor` 共用，不會漂移）。
>
> **對時不是 HTTP 端點。** App 的時鐘使用真正的 **SNTP**
> （`flutter_ntp`，UDP/123），對 `time.exptech.com.tw`（主）/
> `time.apple.com`（備），而非 `/ntp` HTTP 呼叫 —— 見
> `core/realtime/ntp_time_source.dart` 與 `app_time.dart`（`AppTime.utc` /
> `AppTime.utc8`）。

## 多活備援 (multi-active)

| 方法 | 路徑 | 層級 | 主機（容錯順序 = 選定區域優先） |
|---|---|---|---|
| `openEewSse` | `/api/v2/eq/eew?sse=1&compress=1` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `openRtsSse` | `/api/v2/trem/rts?sse=1&compress=1` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getRtsRealtime` | `/api/v2/trem/rts` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getEewRealtime` | `/api/v2/eq/eew` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getEewAt` | `/api/v2/eq/eew/{sec}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `getReportList` | `/api/v2/eq/report` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `getReport` | `/api/v2/eq/report/{id}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |

> **地震報告 list（v2）query：** `limit`/`page`、`sort`/`order`
> （`time`\|`intensity`\|`magnitude`\|`depth` × `asc`\|`desc`）、震度／規模／深度
> 區間、`startTime`/`endTime` 為 **`YYYY-MM-DD`（Asia/Taipei 當日）**、可選
> `city`/`cityMinInt`/`cityMaxInt`。`loc` 與經緯度篩選已移除。伺服器會把非正規
> query **302** 到 canonical（參數字母序、去掉預設值）以利 ETag／快取。
> `getEewAt` 是**歷史回放**（時間軸），tier 為 `coreApi`。

> **即時串流走 SSE（gzip 壓縮），不是輪詢。** `?sse=1` 把端點切換成
> `text/event-stream`；再加 `&compress=1`，payload 會以 `event: g` 事件送出，其
> `data:` 是 **base64 的 gzip**（解開後就是純 GET 的同一份 JSON，模型不變），由**應用層**
> 在 `sse_realtime_source.dart` 解壓 —— 對 ~1 Hz 的 RTS 特別省流量。改為在變動時
> 推送，而非每秒拉取。EEW（`openEewSse`）與 RTS（`openRtsSse`）都已上線走 SSE；
> `getEewRealtime` / `getRtsRealtime` 保留為一次性快照。傳輸、緩衝與重連都藏在
> `RealtimeSource` seam 後面（`core/realtime/sse_realtime_source.dart`）——
> channel、過期分類器與生命週期都不變。EEW 是**突發型**（地震之間靜默 → 存活判定用
> 「連線開著」）；RTS 是**連續型**（約 1 Hz → 存活判定用「最近有事件」）。

## 沒多活備援 (single host, no failover)

### Basemap / Terrain（全域 static LB，無區域）

Basemap 與 terrain 都由 MapLibre 直接抓（app 的 tile bridge 會以 URL 為鍵快取），
不經 `ApiClient` 的區域 failover。

| 用途 | 路徑 | 主機 |
|---|---|---|
| basemap | `/api/v1/map/tiles/{z}/{x}/{y}.pbf` | `static.lb.exptech.dev` |
| terrain | `/api/v1/map/terrain/{z}/{x}/{y}.png` | `static.lb.exptech.dev` |

> **Terrain 是 Mapbox terrain-RGB，MapLibre 原生讀得懂。** 每個像素編碼
> `height = (R·65536 + G·256 + B)/10 − 10000` 公尺，正是 MapLibre
> `raster-dem` 的 `encoding: 'mapbox'` —— style 直接以該 encoding 使用原始
> PNG，**不需要任何 app 端轉換**（參照 `satellite-tiles-go/web` 的底圖處理）。
> 底圖以 `encoding: 'mapbox'`、`tileSize: 512`、`bounds: [110, 10, 132, 35]`
> 註冊 `raster-dem` source，疊半透明 `hillshade` layer 呈現立體感；`bounds`
> 刻意大於真實 DEM bbox，讓 hillshade 邊緣永遠不會在畫面上碰到純背景。

### 雷達（v2）—— `core-tnn1`

時間清單是差量編碼的 Unix 秒（`[baseSec, Δ, …]`），在 API 主機上帶 ETag/304；
tile 是 WebP，放在 **static** 主機（由 MapLibre 直接抓取，`Cache-Control:
max-age=300`）。`{sec}` 就是解出清單後的 10 位數秒，直接使用。

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `getFrames` | `/api/v2/tiles/radar/list` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `tileUrl` | `/api/v2/tiles/radar/{sec}/{z}/{x}/{y}.webp` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 衛星雲圖（v2）—— `core-tnn1`

Himawari-9 AHI 的 XYZ WebP,預設是 Band-13 IR。時間清單是差量編碼的
Unix 秒（`[baseSec, Δ, …]`）,在 API 主機上帶 ETag/304;tile 在 **static**
主機。`{sec}` 就是解出清單後的 10 分鐘秒,直接使用。

`?channel=` 選取渲染的頻道或產品 —— 單一頻道用數字（`13`）、命名產品用名稱
（`btd_wvirw`、`cloudtop`…,即 `satellite-tiles-go/docs.md` 的產品目錄）。
帶 channel 時時間清單為該 channel 的交集（產品需要的頻道缺一就不可渲染,
`list` 只列齊全的時刻）。App 的圖層選擇器為每個 channel 註冊一個獨立圖層
（`satellite` 保留給 B13,其餘為 `satellite-<channel>`）。

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `getFrames` | `/api/v2/tiles/satellite/list[?channel=…]` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `tileUrl` | `/api/v2/tiles/satellite/{sec}/{z}/{x}/{y}.webp[?channel=…]` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 未來1小時降水預報 QPESUMS（v2）—— `core-tnn1`

QPESUMS 定量降水預報 XYZ WebP。時間清單是差量編碼的 Unix **毫秒**
（`[baseMs, Δ, …]`）；tile 在 **static** 主機。`{ms}` 就是解出清單後的 13 位數
毫秒，直接使用（時間軸解析已同時支援秒與毫秒）。

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `getFrames` | `/api/v2/tiles/qpesums/list` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `tileUrl` | `/api/v2/tiles/qpesums/{ms}/{z}/{x}/{y}.webp` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 防災地圖 DPM（v2）—— `core-tnn1`

MapLibre **vector tiles**（gzip MVT）+ 點位詳情 JSON。目前有 **AED / 無障礙廁所 /
避難所**三層；其他類型走同一路徑形狀 `/api/v2/tiles/dpm/{layer}/…`。Tile 與詳情都
在 **static** 主機（`Cache-Control: max-age=60, must-revalidate` + ETag）；
tile 由 MapLibre 直接抓，詳情經 `ApiClient`。Source-layer 名 = `{layer}`
（AED 為 `aed`）。單點有 `id`（內部 PK，打詳情用，非 `aed_id`）；低 zoom 的
cluster 帶 `point_count`。

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `tileUrl` | `/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |
| `getAedDetail` | `/api/v2/tiles/dpm/aed/{id}` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |
| `getRestroomDetail` | `/api/v2/tiles/dpm/restroom/{id}` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |
| `getShelterDetail` | `/api/v2/tiles/dpm/shelter/{id}` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 風場 Wind（v2 / v1）—— `core-tnn1`

風場 overlay：XYZ WebP 圖層 + 低 zoom 的 **`.bin` 向量風場**（`WND1` 格式，
`fetchWindBin`）。時間清單／圖層與其他 tiles 家族同形狀；`.bin` 用 `{model}`
（`gfs` / `ecmwf`）與 `{frame}` 定址。圖層選擇器把 wind 註冊為獨立圖層。

| 方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `getFrames` | `/api/v2/tiles/wind/list[?model=…]` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `tileUrl` | `/api/v2/tiles/wind/{ts}/{z}/{x}/{y}.webp[?model=…]` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |
| `fetchWindBin` | `/api/v1/wind/{model}/{frame}.bin` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 氣象家族（**v5**）—— `core-tnn1`

**已自 `api-1` 的 v2/v3 遷移完成。** 四個家族（weather / rain / lightning /
typhoon）共用同一組形狀：`/api/v5/meteor/{family}` 是最新快照、`/list` 是可用時間
清單、`/{sec}` 是該時刻的歷史快照且放在 **static** 主機。舊的
`/api/v2/meteor/*`、`/api/v3/weather/*` 在 `api-1` 上仍然活著，但 App 已不再呼叫。

時間軸與數值皆為**差量／哨符編碼**，由 `core/network/meteor_decode.dart` 還原：
`ts` 是 `[baseSec, Δ, …]`，數值序列中的 `-99` 代表 null（缺值），不是讀數。

| 方法 | 路徑 | 層級 |
|---|---|---|
| `getWeatherStations` | `/api/v5/meteor/weather/station` | `coreExclusiveApi` |
| `getWeatherLatest` | `/api/v5/meteor/weather` | `coreExclusiveApi` |
| `getWeatherList` | `/api/v5/meteor/weather/list` | `coreExclusiveApi` |
| `getWeatherAt` | `/api/v5/meteor/weather/{sec}` | `coreStaticExclusive` |
| `getWeatherTrend` | `/api/v5/meteor/weather/trend/{id}?range=24h\|7d` | `coreExclusiveApi` |
| `getWeatherRealtime` | `/api/v5/meteor/weather/realtime/{lat},{lng}` | `coreExclusiveApi` |
| `getWeatherForecast` | `/api/v5/meteor/weather/forecast/{code}` | `coreExclusiveApi` |
| `getRainStations` | `/api/v5/meteor/rain/station` | `coreExclusiveApi` |
| `getRainLatest` | `/api/v5/meteor/rain` | `coreExclusiveApi` |
| `getRainList` | `/api/v5/meteor/rain/list` | `coreExclusiveApi` |
| `getRainAt` | `/api/v5/meteor/rain/{sec}` | `coreStaticExclusive` |
| `getRainTrend` | `/api/v5/meteor/rain/trend/{id}?range=24h\|7d` | `coreExclusiveApi` |
| `getLightningLatest` | `/api/v5/meteor/lightning` | `coreExclusiveApi` |
| `getLightningList` | `/api/v5/meteor/lightning/list` | `coreExclusiveApi` |
| `getLightningAt` | `/api/v5/meteor/lightning/{sec}` | `coreStaticExclusive` |
| `getTyphoonLatest` | `/api/v5/meteor/typhoon` | `coreExclusiveApi` |
| `getTyphoonTrack` | `/api/v5/meteor/typhoon/track` | `coreExclusiveApi` |
| `getTyphoonPotential` | `/api/v5/meteor/typhoon/potential` | `coreExclusiveApi` |
| `getTyphoonProbability` | `/api/v5/meteor/typhoon/probability` | `coreExclusiveApi` |
| `getTyphoonWarning` | `/api/v5/meteor/typhoon/warning` | `coreExclusiveApi` |
| `getTyphoonKindList` | `/api/v5/meteor/typhoon/{kind}/list` | `coreExclusiveApi` |
| `getTyphoonKindAt` | `/api/v5/meteor/typhoon/{kind}/{sec}` | `coreStaticExclusive` |

> **颱風多颱**：`/`、`/track`、`/potential`、`/probability`、`/warning` 一律
> `{ updated, cyclones: [...] }`；唯一識別是 **`tdNo`**（CWA `CwaTdNo`，未命名
> TD 也有）。地圖 overlay 由 client 從 typed payloads 組出（不抓 `/geojson`）。
> `/warning` 的 CAP 通常一報（`cyclones` 長度 0–1）。

> ⚠️ **`?range` 目前被伺服器忽略。** 對 weather 與 rain 的 `trend/{id}` 實測
> （2026-08-02，多個測站）：`range=7d`、`7D`、`week`、`168h`、改用其他參數名、
> 乃至完全不帶參數，回應一律是 `"range":"24h"` 且為 24 筆逐時資料。App 送出的參數
> 是對的，是後端尚未實作 —— 在後端補上之前，「7 天」等同 24 小時。

### 裝置與通知 —— `core-tnn1`

| 方法 | 路徑 | 層級 |
|---|---|---|
| `updateDeviceLocation` | `/api/v2/location/{platform}/{token}/{version}/{lat},{lng}` | `coreExclusiveApi` |
| `getNotify` | `/api/v2/notify/{token}` | `coreExclusiveApi` |
| `setNotify` | `/api/v2/notify/{token}/{channel}/{status}` | `coreExclusiveApi` |

### 舊 server `api-1`（逐步淘汰中）

後端會把端點陸續搬到 `core-tnn1`，這裡會隨之縮減。以下**仍只在 `api-1` 上**，
且都已在 App 中實際使用：

| 方法 | 路徑 | 層級 | 使用處 |
|---|---|---|---|
| `getStations` | `/api/v1/trem/station` | `legacyApi` | 強震監視器測站 |
| `getHistoryList` | `/api/v1/dpip/history/list` | `legacyApi` | 事件頁（全國） |
| `getHistoryRegion` | `/api/v1/dpip/history/{region}` | `legacyApi` | 事件頁（鄉鎮） |
| `getRealtimeList` | `/api/v1/dpip/realtime/list` | `legacyApi` | 首頁拖盤收起（全國生效中） |
| `getRealtimeRegion` | `/api/v1/dpip/realtime/{region}` | `legacyApi` | 首頁拖盤收起（鄉鎮生效中） |
| `getRtsAt` | `/api/v2/trem/rts/{sec}` | `legacyApi` | 強震波形回放（時間軸） |

尚未接上、但端點存在於 `api-1`：

| 方法 | 路徑 | 層級 |
|---|---|---|
| `getEvent` | `/api/v1/dpip/event/{id}` | `legacyApi` |

## 外部（第三方，無區域）

| 方法 | URL |
|---|---|
| `getReleases` | `https://api.github.com/repos/ExpTechTW/DPIP/releases`（ETag；`per_page=30`） |
| `getRainHourForecast` | `https://exptech.dingbot.tw/api/weather/rainforecast/{code}`（`{code}` = 鄉鎮 3 碼；回應為單 series 信封 `{"<系列名>": [{"start": 秒, "rain": [60 × mm]}]}`；空 series `[]` = 該小時無雨，卡片隱藏） |

## curl 可用性（2026-08-02 實測，HTTP 狀態碼）

| 端點 | lb-tpe1 | lb-khh1 | core-tyo1 | core-tnn1 | api-1 |
|---|:--:|:--:|:--:|:--:|:--:|
| `/api/v2/trem/rts` | 200 | 200 | 404 | 401 | 200 |
| `/api/v2/eq/eew` | 200 | 200 | 200 | 200 | 404 |
| `/api/v2/eq/report` | 404 | 404 | 200 | 200 | 404 |
| `/api/v1/trem/station` | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/tiles/radar/list` | 404 | 404 | 404 | 200 | 404 |
| `/api/v5/meteor/weather/station` | 404 | 404 | 404 | **200** | 404 |
| `/api/v5/meteor/weather/list` | 404 | 404 | 404 | **200** | 404 |
| `/api/v5/meteor/rain/station` | 404 | 404 | 404 | **200** | 404 |
| `/api/v5/meteor/rain/list` | 404 | 404 | 404 | **200** | 404 |
| `/api/v5/meteor/lightning/list` | 404 | 404 | 404 | **200** | 404 |
| `/api/v5/meteor/typhoon/geojson` | 404 | 404 | 404 | **200** | 404 |
| `/api/v2/meteor/weather/list`（舊） | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/meteor/rain/list`（舊） | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/meteor/lightning/list`（舊） | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/meteor/typhoon/geojson`（舊） | 404 | 404 | 404 | 404 | 200 |
| `/api/v1/dpip/history/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v1/dpip/realtime/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/notify/{token}` | 404 | 404 | 404 | 401 | 429 |

v5 氣象家族與其 static 快照（`static.core-tnn1` 的
`/api/v5/meteor/{weather,rain,lightning}/{sec}`）實測皆為 200。舊的 v2 路徑在
`api-1` 上仍然存活，所以遷移是**新增而非切換** —— 但 App 只走 v5。

雷達 **tile** 不在這張表裡 —— 它們由 `static.core-tnn1.exptech.dev` 提供
（`/api/v2/tiles/radar/{sec}/{z}/{x}/{y}.webp`，`image/webp`），和上面的時間清單
是不同主機。

只有 `lb-tpe1` / `lb-khh1` 對 `?sse=1` 回傳真正的 `text/event-stream`；
`core-tyo1` 之於 `eew?sse=1`、`api-1` 之於 `rts?sse=1` 都是 HTTP 200 但
`application/json`（旗標被忽略）。`core-tnn1` 對兩者都回 401。這就是 SSE
串流固定用 `lbApi` 的原因。

---

How the client reaches these — `ApiClient`, tiers, failover — is in
[ARCHITECTURE.md § Networking](ARCHITECTURE.md#networking).
