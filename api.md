# DPIP API 對照表

區域綁定的端點 —— 經 DNS 負載平衡的裸主機（`api.lb`、`api.core`）一律不使用。
區域由 `RegionSelection` 狀態決定；多活（multi-active）層級會在其各區域之間容錯切換。

- **區域：** LB = `tpe1`（台北）、`khh1`（高雄）；Core = `tyo1`（東京）、
  `tnn1`（台南）。
- **路徑前綴：** 所有路徑都是 `/api/...`。
- **層級（Tier）：** `lbApi` = LB（多活）、`lbStatic` = LB static（多活；
  basemap、OSM、terrain 圖磚）、`coreApi` = Core（多活）、`coreStatic` = Core
  static（多活）、`coreExclusiveApi` = 僅 `api.core-tnn1`、`coreStaticExclusive`
  = 僅 `static.core-tnn1`、`legacyApi` = 舊 server `api-1`（逐步淘汰中）。

> 沒有 `lib/api/` 巨石檔：每個端點在其所屬 feature 的 `data/`（基礎設施則在
> `core/`）裡，各自建成一個輕薄的 datasource，並帶著自己的 `ApiTier`
> （`core/network/api_region.dart`）；路徑字串集中於
> `core/network/api_paths.dart`（與 `EtagInterceptor` 共用，不會漂移）。
>
> **第一欄一律寫成 `類別.方法`。** 只寫方法名的版本曾經整段對不上程式碼 ——
> `getWeatherStations`、`getRainLatest`、`getTyphoonTrack` 這些名字從來不存在，
> 真正的呼叫是一個參數化的 `MeteorSnapshotApi` 加上兩個專用類別。帶著類別名，
> 一次 grep 就能證實或推翻這張表的任何一列。
>
> **對時優先走 SNTP，HTTP `/ntp` 只是退路。** App 的時鐘使用真正的 **SNTP**
> （`flutter_ntp`，UDP/123），對 `time.exptech.com.tw`（主）/
> `time.apple.com`（備）—— 見 `core/realtime/ntp_time_source.dart` 與
> `app_time.dart`（`AppTime.utc` / `AppTime.utc8`）。
>
> 兩台都失敗才改打 **`https://api.lb-{tpe1,khh1}.exptech.dev/ntp`**
> （`core/realtime/http_time_source.dart`；桌面小工具的對應實作是 iOS 的
> `WidgetHTTPTimeSource.swift` 與 Android 的 `WidgetClock.kt`），因為企業
> Wi-Fi、飯店與校園網路常擋掉 UDP/123，而那時唯一的替代品是完全不校時。順序是精度而非偏好：SNTP 的
> RFC 5905 交換約到毫秒，單趟 HTTPS 只到 ±RTT/2（實測 ±150 ms）。
>
> **它是逐台的應用層容錯，跟 `ApiTier` 無關。** 主機清單來自區域選擇
> （`hostsFor(regions.lbOrder)`，選定區域先打），所以這條退路跟著 App 的區域
> 走；沒有 `ApiClient` 的 tier 換台，也沒有一份會過 `EtagInterceptor` 的絕對
> URL。以前那個 bare `api.lb.exptech.dev` 已經不用了 —— 它把選擇權交給
> Cloudflare，而那個池子裡有慢的後端；2026-11-28 實測它已經逾時不回。
>
> **`/ntp` 的 body 不可盲信，要用它自己的 `Date` header 驗證。** body 是後端的
> 時鐘，而後端的時鐘不一定對：`lb-*` 這一池有四台，撰寫時 `lb-2` 與 `lb-4` 都
> 慢 15.7 秒，而且兩台數值一致 —— 跨主機取多數也抓不到。
>
> 能抓到的是同一個回應的 `Date` header：這台在 Cloudflare 後面，`Date` 由
> **edge** 蓋，跟哪一台後端回應無關,所以每個回應都能自我檢查 —— body 與自己的
> `Date` 差超過 2 秒就是壞後端（或凍結的快取），直接丟棄,不需要知道它來自哪
> 個節點。（來回超過 1.5 秒也丟棄，因為 offset 估計的誤差隨 RTT 成長。）
>
> 連續 30 次取樣都落在自己 header 的 910 ms 內，所以這個名字目前確實會導到正
> 常的後端 —— 而上面那條檢查的作用，就是讓這件事不必靠 App 去假設。全部被拒
> 就維持舊 anchor：裝上 15 秒誤差比不校時更糟。
>
> （`time.exptech.com.tw`，也就是 SNTP 的主機，同樣回應 `/ntp`，但它提供的憑證
> 是 `CN=tpe-1.lb.exptech.dev` 且已於 2026-03-13 過期，HTTPS 連不上；而且它的
> `Date` 由同一台機器上的 openresty 蓋，無法自我驗證。所以不用它。）

## 多活備援 (multi-active)

| 類別.方法 | 路徑 | 層級 | 主機（容錯順序 = 選定區域優先） |
|---|---|---|---|
| `SseMux.lb` | `/api/v1/sse?topics=…[&mode=live]` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `EarthquakeApi.getEewRealtime` | `/api/v2/eq/eew` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `EarthquakeApi.getEewAt` | `/api/v2/eq/eew/{sec}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `EarthquakeApi.getRtsAt` | `/api/v3/trem/rts/{sec}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `TremStationRepositoryImpl.refresh` | `/resource/station` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `EarthquakeApi.getReportList` | `/api/v2/eq/report` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `EarthquakeApi.getReport` | `/api/v2/eq/report/{id}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `FrameTileApi.getFrames` | `/api/v2/tiles/radar/list` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `FrameTileApi.tileUrl` | `/api/v2/tiles/radar/{sec}/{z}/{x}/{y}.webp` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `FrameTileApi.getFrames` | `/api/v2/tiles/qpesums/list` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `FrameTileApi.tileUrl` | `/api/v2/tiles/qpesums/{sec}/{z}/{x}/{y}.webp` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.tileUrl` | `/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.getAedDetail` | `/api/v2/tiles/dpm/aed/{id}` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.getRestroomDetail` | `/api/v2/tiles/dpm/restroom/{id}` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.getShelterDetail` | `/api/v2/tiles/dpm/shelter/{id}` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |

> **地震報告 list（v2）query：** `limit`/`page`、`sort`/`order`
> （`time`\|`intensity`\|`magnitude`\|`depth` × `asc`\|`desc`）、震度／規模／深度
> 區間、`startTime`/`endTime` 為 **`YYYY-MM-DD`（Asia/Taipei 當日）**、可選
> `city`/`cityMinInt`/`cityMaxInt`。`loc` 與經緯度篩選已移除。伺服器會把非正規
> query **302** 到 canonical（參數字母序、去掉預設值）以利 ETag／快取。
> `getEewAt` / `getRtsAt` 是**歷史回放**（時間軸），tier 為 `coreApi`。
> `getRtsAt` 的 `{sec}` 必須是 10 位數的 Unix 秒；剛過去的一兩分鐘可能只有一個
> 區域歸檔好（實測 now−30 s：tnn1 200、tyo1 404），所以 404 是常態而非故障。

> **測站清單 `/resource/station` 是 CSV**（`Content-Type` 卻標成 JSON）：
> `loc_code,id,lat,lon,floor,code,net,time,work`，`id` 是 RTS 用的 hex 裝置 id、
> `code` 是鄉鎮代碼。每個區域的 nginx 各自產生弱 ETag（同檔不同值），帶
> `If-None-Match` 回 **304**。App 自己帶驗證器、把最後一份成功的清單連同 ETag
> 存進 `dpip.db` 的 `trem_station`（不是 HTTP 快取，那個會被系統清掉），
> 開強震監視器時先畫存著的、再問一次伺服器。

> **即時串流走 SSE（gzip 壓縮），不是輪詢，而且整個 App 只開一條連線。**
> `SseMux.lb` 開 `/api/v1/sse?topics=<a,b>`：`topics` 是 App 正在串流的每一個
> topic（常數在 `EarthquakeApi`，在 `earthquake_providers.dart` 註冊）——
> `eq.eew.v1` 是地震速報清單（每則都是完整快照，連上就先送目前那份）、
> `trem.rts.v1` 是即時測站。每則事件以 topic 為名（`event: eq.eew.v1`、
> `event: trem.rts.v1`），`data:` 一律是 **base64 的 gzip**，由
> **應用層**在 `sse_realtime_source.dart` 解壓。連線一開先送 `retry:` 與
> `event: info`（列出允許與 `denied` 的 topic），之後約每 60 秒一行 `: ping`。
> 只要還有一個 feed 在用就維持這一條，最後一個放手（進背景）就關掉；某個 feed
> 自己重連時是加入已開的那一條，不會另開。
>
> `trem.rts.v1` 的內容是 `rts.v1` JSON（`{ts, stations:{<hex id>:{i, pga?, alert?}}, eq}`，**沒有**
> v2 的 `box`／`int`／`I`／`pgv` —— 由前端從 alert 測站推算）。不帶 `mode=live`
> 時是**睡眠模式**：只送有測站 alert 的幀；App 只在強震監視器顯示時要
> `mode=live`（整條共用連線一起切換），換模式時先連新的、收到招呼才斷舊的。
> 不要訂 `trem.eew.v1` —— 那是 TREM 自己的 EEW，不是 CWA 的。
>
> 傳輸、緩衝與重連都藏在 `RealtimeSource` seam 後面 —— channel、過期分類器與
> 生命週期都不變。EEW 是**突發型**（地震之間靜默 → 存活判定用「連線開著」）；
> RTS live 時是**連續型**（約 2 Hz → 「最近有事件」），睡眠時靜默就是「平靜」。

### 雷達（v2）—— Core 雙區多活

時間清單是差量編碼的 Unix 秒（`[baseSec, Δ, …]`），在 API 主機上帶 ETag/304；
tile 是 WebP，放在 **static** 主機（由 MapLibre 直接抓取；`Cache-Control:
no-store` 加弱 ETag，重新驗證回 304，2026-11-16 實測）。`{sec}` 就是解出清單後的
10 位數秒，直接使用。

**有效觀測範圍不是宣告網格。** 宣告的是 115–126.5°E、18–29°N（921 × 881 格，
0.0125°），但實際只有四座雷達測距圓的聯集裁到該網格內才有觀測；其餘是空的。
空白代表「未觀測」而非「無降水」，所以地圖的「顯示掃描範圍」外框畫的是那個聯集，
幾何與推導在 `radar_scan_range.dart`。

| 類別.方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `FrameTileApi.getFrames` | `/api/v2/tiles/radar/list` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `FrameTileApi.tileUrl` | `/api/v2/tiles/radar/{sec}/{z}/{x}/{y}.webp` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |


> **tile 由 MapLibre 直接抓，URL 只寫選定區域的那一台；那一台失敗時由
> `MapTileCache` 接手。** MapLibre 下載失敗不會告訴 App，所以接手的時機有兩個：
> MapLibre 又來要一塊它自己沒抓到、也不是 App 自己取消（`cancelFetches`）的
> tile，或 App 自己對那一台的上一次 tile 請求就失敗了。接手後改由
> `ApiClient.getTileBytes` 抓，每台最多一次，再用 MapLibre 原本那個 URL 交回去；
> 順序照 `coreStatic`，只是 30 秒內剛失敗過的那一台排到最後（過了 30 秒再排回
> 前面試一次，看它好了沒）。連線錯誤、逾時與 5xx 換台。
>
> **某一區少了某一幀時，後端回 500，不是 404**（兩區皆然，2026-11-28 實測），所以
> 那個缺口照 5xx 換台，也照 5xx 計入主機健康度。`notFoundFailsOver` 仍然開著（同
> 氣象 v5 的 `getAt`），後端哪天改回 404 也一樣會問另一區；404 不計入主機健康度。
>
> MapLibre 自己取消的下載（tile 下載到一半就捲出畫面）不會通知 Dart —— fork 的
> tile bridge 只呼叫 `cacheablePatterns`、`getBatch`、`putBatch` —— 所以那種 tile
> 再被要一次時會被接手一次，從選定區域先抓。
>
> **快取鍵不看區域。** tile 以 `tileCacheKey` 存：兩區的同一塊都存在
> `static.core-tnn1` 的 URL 下（更新前雷達、QPESUMS、DPM 只在 tnn1，裝置上既有的
> 快取就是這個名字），所以換區或換台都直接命中，不會重抓。

### 未來1小時降水預報 QPESUMS（v2）—— Core 雙區多活

QPESUMS 定量降水預報 XYZ WebP。時間清單是差量編碼的 Unix **秒**
（`[baseSec, Δ, …]`，每 600 秒一筆）；tile 在 **static** 主機。`{sec}` 就是解出
清單後的 10 位數秒，直接使用；改用 13 位數毫秒會回 500（2026-11-16 實測）。
`framesFromList` 原樣使用清單的值，所以 App 不受影響。

**覆蓋範圍是方形，整塊都有資料**：441 × 561 格，每格 0.0125°
（與雷達同解析度）；118.0–123.5125°E、20.0–27.0125°N 是整塊格網的外緣，
不是格心座標。

這**不是**雷達的有效範圍。預報發布在自己的網格上，雷達的是測距圓聯集，兩者在
方形四角（預報有、圓弧無）與圓弧外凸處（圓弧有、方形無）都不一致。「顯示掃描
範圍」外框因此各畫各的幾何，QPESUMS 的在 `qpesums_scan_range.dart`。

| 類別.方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `FrameTileApi.getFrames` | `/api/v2/tiles/qpesums/list` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `FrameTileApi.tileUrl` | `/api/v2/tiles/qpesums/{sec}/{z}/{x}/{y}.webp` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |

### 防災地圖 DPM（v2）—— Core 雙區多活

MapLibre **vector tiles**（gzip MVT）+ 點位詳情 JSON。目前有 **AED / 無障礙廁所 /
避難所**三層；其他類型走同一路徑形狀 `/api/v2/tiles/dpm/{layer}/…`。Tile 與詳情都
在 **static** 主機（`Cache-Control: max-age=60, must-revalidate` + ETag）；
tile 由 MapLibre 直接抓，詳情經 `ApiClient`。Source-layer 名 = `{layer}`
（AED 為 `aed`）。單點有 `id`（內部 PK，打詳情用，非 `aed_id`）；低 zoom 的
cluster 帶 `point_count`。

| 類別.方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `DisasterMapApi.tileUrl` | `/api/v2/tiles/dpm/{layer}/{z}/{x}/{y}.mvt` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.getAedDetail` | `/api/v2/tiles/dpm/aed/{id}` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.getRestroomDetail` | `/api/v2/tiles/dpm/restroom/{id}` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |
| `DisasterMapApi.getShelterDetail` | `/api/v2/tiles/dpm/shelter/{id}` | `coreStatic` | `static.core-{tyo1,tnn1}.exptech.dev` |


> **tile 的換台與快取鍵同雷達**（見上）；詳情經 `ApiClient`，照 `coreStatic`
> 的順序換。

### Basemap / OSM / Terrain（`lbStatic`）—— LB 雙區多活

Basemap、OSM 詳細街道建築與 terrain 都由 MapLibre 直接抓。style 的 URL 寫選定
區域的那一台（`staticLbOrigin(RegionSelection.lb)`）：選台北抓 `static.lb-tpe1`、
選高雄抓 `static.lb-khh1`，換區時 style 一起換（`BaseMap` 以
`watch<RegionSelection>()` 重建 style 字串）。那一台失敗時跟雷達一樣由
`MapTileCache` 接手，照 `lbStatic` 的順序換到另一區（見雷達一節），只是 **404
不換**：每台都是同一份資料，海面上的 404 在哪一台都是 404。OSM 是可選
疊圖，只覆蓋臺灣資料範圍；一般 basemap 始終保留，因此資料範圍外不會變成空白。

| 用途 | 路徑 | 主機 |
|---|---|---|
| basemap | `/api/v1/map/tiles/{z}/{x}/{y}.pbf` | `static.lb-{tpe1,khh1}.exptech.dev` |
| OSM 詳細圖資 | `/api/v1/map/gsi/{z}/{x}/{y}.pbf` | `static.lb-{tpe1,khh1}.exptech.dev` |
| terrain | `/api/v1/map/terrain/{z}/{x}/{y}.png` | `static.lb-{tpe1,khh1}.exptech.dev` |

> **快取鍵是裸的 `static.lb.exptech.dev`。** 兩區的同一塊 tile 都以這個 URL 存
> （`tileCacheKey`）—— 那正是釘區域之前每一列用的名字，所以更新後既有的快取照樣
> 命中，換區也不會重抓整張地圖。這個裸主機只當鍵，App 不再對它發請求。

> **App 內附一份 basemap，給沒有網路時用。** 臺灣（含離島）z0–9 加全球 z0–2，
> 共 122 塊、1.05 MiB（`assets/map/basemap_seed/`），由 `tool/gen/basemap_seed.sh`
> 從上表的 basemap 路徑抓下來產生。啟動時種進 tile store（種在上面那個快取鍵下，
> 任一區域的 URL 都讀得到），但只是**退路**：MapLibre 要到其中一塊時一律先問
> 網路，網路答不出來才交出內附版本，第一次下載成功就永久取代它；server 給過的列
> （含 404）永遠不會被它蓋掉。

> **Terrain 是 Mapbox terrain-RGB，MapLibre 原生讀得懂。** 每個像素編碼
> `height = (R·65536 + G·256 + B)/10 − 10000` 公尺，正是 MapLibre
> `raster-dem` 的 `encoding: 'mapbox'` —— style 直接以該 encoding 使用原始
> PNG，**不需要任何 app 端轉換**（參照 `satellite-tiles-go/web` 的底圖處理）。
> 底圖以 `encoding: 'mapbox'`、`tileSize: 512`、`bounds: [110, 10, 132, 35]`
> 註冊 `raster-dem` source，疊半透明 `hillshade` layer 呈現立體感；`bounds`
> 刻意大於真實 DEM bbox，讓 hillshade 邊緣永遠不會在畫面上碰到純背景。
### 海嘯 CWA tsunami —— Core 雙區多活

兩支端點都是**索引 + 詳情**：索引只有事件摘要與 `id`，詳情才是內文與
`data.area`。**時間單位是 Unix 毫秒**（`sent`、`validUntil`、以及 area 內各自的
時間），與氣象家族的秒不同、也不經差量編碼 —— 直接當 13 位數毫秒用。

**`data.area` 是位置式陣列，欄位數隨 `data.type` 改變**：`predict` 五欄
`[地區, 沿岸範圍, 預估浪高, 抵達時間, 顏色]`、`observe` 六欄
`[測站代碼, 測站名, 觀測浪高, 觀測時間, 經度, 緯度]`。用錯分支不會拋錯，只會把
海岸範圍當成測站名；`observe` 的經緯度**可以整組是 `null`**（2024-04-03 的
臺中港就是），所以地圖只畫有座標的那幾筆。解碼與判斷都在
`TsunamiReport.decode`。

**索引 `reports` 是最新在前，且會混入往年事件** —— `no`（`113003`）才是同一個
事件的鍵，`rep`（`第3報`）是該事件內的第幾報。事件的**最後一報通常是「海嘯警報
解除」**（`observe`、只有實測），所以「只读最新一報」等於看不到預估；列表與報告
選擇器因此都以**最新事件的整個事件**為單位（`TsunamiBulletin.newestEvent`）。

| 類別.方法 | 路徑 | 層級 |
|---|---|---|
| `TsunamiApi.getReports` | `/api/v1/cwa/tsunami` | `coreApi` |
| `TsunamiApi.getReport` | `/api/v1/cwa/tsunami/{id}` | `coreApi` |

> `coreApi`（多活）而非 `coreExclusiveApi`：`core-tyo1` 與 `core-tnn1` 實測都回
> 200（索引與詳情皆然，2026-10-05），所以它跟著區域容錯，沒有理由只釘在 tnn1。
> 沒有 ETag，因此每次都由 App 重新抓取 —— 只在圖層開啟時抓，索引與內文都小。

### 氣象家族（**v5**）—— Core 雙區多活

**已自 `api-1` 的 v2/v3 遷移完成。** 四個家族（weather / rain / lightning /
typhoon）共用同一組形狀：`/api/v5/meteor/{family}` 是最新快照、`/list` 是可用時間
清單、`/{sec}` 是該時刻的歷史快照且放在 **static** 主機。舊的
`/api/v2/meteor/*`、`/api/v3/weather/*` 在 `api-1` 上仍然活著，但 App 已不再呼叫。

**兩個 core 區都有完整的 v5 meteor**（`api.core-{tyo1,tnn1}` 與
`static.core-{tyo1,tnn1}`，2026-11-28 逐支實測皆 200），所以 mutable 走
`coreApi`、`/{sec}` 走 `coreStatic`，選定區域優先、失敗換另一區。

**兩區各自向氣象署抓資料，不跨區同步**：同一個觀測時間的數值、`forecast` 的
`updateTime` 與 ETag 都可能不同，換區後的回應要當成獨立的一份，不能假設兩區
逐位元組相同。各區的歷史也各自累積：`tnn1` 從 2026-11-26 15:00 才開始，約
11-29 15:00 補滿 3 天；之後任何一區停機也會留下缺口。所以一區 `/list` 裡的時間點
在另一區的 static 可能 404 —— `getAt` 帶 `notFoundFailsOver`，404 時會再問另一區，
兩區都沒有才算 404（不計入主機健康度）。

時間軸與數值皆為**差量／哨符編碼**，由 `core/network/meteor_decode.dart` 還原：
`ts` 是 `[baseSec, Δ, …]`，數值序列中的 `-99` 代表 null（缺值），不是讀數。

`weather` / `rain` / `lightning` 三家共用同一個參數化的 `MeteorSnapshotApi`
（建構時傳入 `_base`），所以**方法名只有五個，不是每家一組**。颱風的形狀不同，
自成 `MeteorTyphoonApi`。

| 類別.方法 | 路徑 | 層級 |
|---|---|---|
| `MeteorSnapshotApi.getStation` | `/api/v5/meteor/{family}/station` | `coreApi` |
| `MeteorSnapshotApi.getLatest` | `/api/v5/meteor/{family}` | `coreApi` |
| `MeteorSnapshotApi.getList` | `/api/v5/meteor/{family}/list` | `coreApi` |
| `MeteorSnapshotApi.getAt` | `/api/v5/meteor/{family}/{sec}` | `coreStatic` |
| `MeteorSnapshotApi.getTrend` | `/api/v5/meteor/{family}/trend/{id}?range=24h\|7d` | `coreApi` |
| `MeteorWeatherApi.getRealtime` | `/api/v5/meteor/weather/realtime/{lat},{lng}` | `coreApi` |
| `MeteorWeatherApi.getForecast` | `/api/v5/meteor/weather/forecast/{code}` | `coreApi` |
| `MeteorTyphoonApi.getCyclones` | `/api/v5/meteor/typhoon` | `coreApi` |
| `MeteorTyphoonApi.getTrack` | `/api/v5/meteor/typhoon/track` | `coreApi` |
| `MeteorTyphoonApi.getPotential` | `/api/v5/meteor/typhoon/potential` | `coreApi` |
| `MeteorTyphoonApi.getProbability` | `/api/v5/meteor/typhoon/probability` | `coreApi` |
| `MeteorTyphoonApi.getWarning` | `/api/v5/meteor/typhoon/warning` | `coreApi` |
| `MeteorTyphoonApi.getList` | `/api/v5/meteor/typhoon/{kind}/list` | `coreApi` |
| `MeteorTyphoonApi.getAt` | `/api/v5/meteor/typhoon/{kind}/{sec}` | `coreStatic` |

`{family}` = `weather` \| `rain` \| `lightning`（`station` 只有前兩家有；
lightning 沒有測站，也沒有 `trend`）。`{kind}` = `track` \| `potential` \|
`probability` \| `warning`（`TyphoonKind.path`，與 enum 名同字）。

> **颱風多颱**：`/`、`/track`、`/potential`、`/probability`、`/warning` 一律
> `{ updated, cyclones: [...] }`；唯一識別是 **`tdNo`**（CWA `CwaTdNo`，未命名
> TD 也有）。地圖 overlay 由 client 從 typed payloads 組出（不抓 `/geojson`）。
> `/warning` 的 CAP 通常一報（`cyclones` 長度 0–1）。

> **`?range` 已生效。** `trend/{id}?range=7d` 回 `"range":"7d"` 與 168 筆逐時資料
> （2026-11-16 實測）；不帶參數是 24 小時。2026-08-02 時後端還沒實作，那時 `7d`
> 等同 24 小時。
>
> **雨量的 24 小時不是 24 筆**：約 143 筆、每 10 分鐘一筆（偶有缺漏），每筆是
> 該時刻**之前 60 分鐘**的雨量 —— 每 10 分鐘的雨都落在六筆裡，直接加總會把同一場雨
> 算約六次。
> `7d` 的 168 筆落在整點，每筆與該整點小時最後一筆 10 分鐘資料相同（2026-11-28
> 實測）。累計怎麼算見 `rainRunningTotals`。

> **`FrameTileApi` 的層級看 `path`：** `radar`／`qpesums` 走多活層，`satellite`／
> `wind` 仍釘 tnn1（後端只有 Core 兩區複製了前兩者）。`DisasterMapApi` 一律
> `coreStatic`。這是後端能力的差異，不是偏好 —— 衛星與風場在 tyo1 仍是 404。

## 沒多活備援 (single host, no failover)

留下來的是衛星、風場（後端還沒複製到 tyo1）、notify／location（熱備援，備援節點
平常把寫入導回主節點）、事件家族（只在 `api-1`，而那台本身就是 `core-tnn1`），
以及不走 `ApiTier` 的 `/ntp`（它自己逐台嘗試，見最後一節）。

### 衛星雲圖（v2）—— `core-tnn1`

Himawari-9 AHI 的 XYZ WebP,預設是 Band-13 IR。時間清單是差量編碼的
Unix 秒（`[baseSec, Δ, …]`）,在 API 主機上帶 ETag/304;tile 在 **static**
主機。`{sec}` 就是解出清單後的 10 分鐘秒,直接使用。

**`{channel}` 與 `{style}` 是路徑段，不是 query。** `{channel}` 選頻道或產品
—— 單一頻道用數字（`13`，也是省略時的預設）、命名產品用名稱（`btd_wvirw`、
`cloudtop`…，即 `satellite-tiles-go/docs.md` 的產品目錄）。清單為該 channel 的
交集（產品需要的頻道缺一就不可渲染，`list` 只列齊全的時刻）。

`{style}` 只出現在 tile 路徑：數字頻道可選 `normal` / `jma` / `bd`，命名產品一律
`normal`（調色盤是產品本身的一部分）。`gray` 會摺成 `normal`。推導在
`FrameTileApi._satelliteStyle`。

App 的圖層選擇器為每個 channel 註冊一個獨立圖層（`satellite` 保留給 B13，其餘為
`satellite-<channel>`）。

| 類別.方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `FrameTileApi.getFrames` | `/api/v2/tiles/satellite/{channel}/list` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `FrameTileApi.tileUrl` | `/api/v2/tiles/satellite/{channel}/{style}/{sec}/{z}/{x}/{y}.webp` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 風場 Wind（v2 / v1）—— `core-tnn1`

風場 overlay：XYZ WebP 圖層 + 低 zoom 的 **`.bin` 向量風場**（`WND1` 格式，
`fetchWindBin`）。圖層選擇器把 wind 註冊為獨立圖層。

**`{model}` 是路徑段，不是 query，而且一個 frame 定址需要兩個時間。** 預報是
「哪一次模式跑」加「預報到哪個時刻」，所以 tile 與 `.bin` 都以
`{cycle}`（模式執行時刻）+ `{validTime}`（預報有效時刻）定址；`getFrames` 回傳的
不透明 frame id 由 `FrameTileApi.windFrameParts` 拆成這兩段。`{model}` 是
`gfs` / `ecmwf`。

| 類別.方法 | 路徑 | 層級 | 主機 |
|---|---|---|---|
| `FrameTileApi.getFrames` | `/api/v2/tiles/wind/{model}/list` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |
| `FrameTileApi.tileUrl` | `/api/v2/tiles/wind/{model}/{cycle}/{validTime}/{z}/{x}/{y}.webp` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |
| `FrameTileApi.fetchWindBin` | `/api/v1/wind/{model}/{cycle}/{validTime}.bin` | `coreStaticExclusive` | `static.core-tnn1.exptech.dev` |

### 裝置與通知 —— `core-tnn1`

| 類別.方法 | 路徑 | 層級 |
|---|---|---|
| `LocationApi.updateDeviceLocation` | `/api/v2/location/{platform}/{token}/{version}/{lat},{lng}` | `coreExclusiveApi` |
| `NotifyApi.getNotify` | `/api/v2/notify/{token}` | `coreExclusiveApi` |
| `NotifyApi.setNotify` | `/api/v2/notify/{token}/{channel}/{status}` | `coreExclusiveApi` |

> **熱備援，不是多活。** 一區是 primary、另一區是 standby：寫入只落在 primary，
> standby 對同一條路徑回 **`307`**（不是 301 —— 307 不會被當成永久導向快取）加
> 指向 primary 的 `location`，平常不承載業務流量。**哪一區是 primary 由後端決定，
> 而且換過**：2026-11-20 實測是 tyo1 → `307` → tnn1；2026-11-28 實測反過來，
> tnn1（App 打的那台）回 `307` 加 `location: https://api.core-tyo1.exptech.dev/…`，
> tyo1 直接回 200。Dio 預設跟隨 redirect（`followRedirects: true`、
> `maxRedirects: 5`），所以 tier 維持 `coreExclusiveApi`：沒有第二個 origin 可以
> 換，只有一個指向 primary 的導向。

### 舊 server `api-1`（逐步淘汰中）

後端會把端點陸續搬到 `core-tnn1`，這裡會隨之縮減。以下**仍只在 `api-1` 上**，
且都已在 App 中實際使用：

| 類別.方法 | 路徑 | 層級 | 使用處 |
|---|---|---|---|
| `EventApi.getHistoryList` | `/api/v1/dpip/history/list` | `legacyApi` | 事件頁（全國） |
| `EventApi.getHistoryRegion` | `/api/v1/dpip/history/{region}` | `legacyApi` | 事件頁（鄉鎮） |
| `EventApi.getRealtimeList` | `/api/v1/dpip/realtime/list` | `legacyApi` | 首頁拖盤收起（全國生效中） |
| `EventApi.getRealtimeRegion` | `/api/v1/dpip/realtime/{region}` | `legacyApi` | 首頁拖盤收起（鄉鎮生效中） |

`/api/v1/dpip/event/{id}` 存在於 `api-1`，但 App 裡**沒有任何方法呼叫它** ——
先前這裡列的 `getEvent` 並不存在於程式碼中。

### 對時 `/ntp`（SNTP 的退路，**不走 `ApiClient`**）

| 路徑 | 主機 | 回應 |
|---|---|---|
| `/ntp` | `api.lb-{tpe1,khh1}.exptech.dev`（**HTTPS only**） | Unix **毫秒**純文字，帶小數（`1791607233513.399`） |

主機清單是 `HttpTimeSource.hostsFor(regions.lbOrder)`：選定區域先打，答不出來
（連不上、body 與自己的 `Date` 差超過 2 秒）才換另一區。不是 `ApiTier`，所以不
經 `ApiClient` 的 tier 容錯 —— 它的 absolute-URL 路徑都會過 `EtagInterceptor`，
而快取一個對時回應比不對時更糟。Dart 用裸 `HttpClient`、Swift 用 `URLSession` +
`reloadIgnoringLocalAndRemoteCacheData`，兩邊都送 `Cache-Control: no-store`。

桌面小工具沒有區域設定，所以固定 `tpe1 → khh1`（iOS 的
`WidgetHTTPTimeSource.swift`、Android 的 `WidgetClock.kt`），每台的逾時與 `Date`
驗證規則都跟 App 相同。
為何每個回應都要拿 `Date` header 驗證，見上方「對時」段落。

## 外部（第三方，無區域）

走 `ApiClient.getAbsolute` / `postAbsolute`：沒有 tier、沒有區域容錯，也不參與
ETag 重新驗證。

| 類別.方法 | URL |
|---|---|
| `ChangelogApi.getReleases` | `https://api.github.com/repos/ExpTechTW/DPIP/releases`（ETag；`per_page=30`） |
| `ChangelogApi.getAvatarBytes` | `https://avatars.githubusercontent.com/…`（貢獻者頭像，內容定址故長快取） |
| `RainHourTrendApi.getForecast` | `https://exptech.dingbot.tw/api/weather/rainforecast/{code}`（`{code}` = 鄉鎮 3 碼；回應為單 series 信封 `{"<系列名>": [{"start": 秒, "rain": [60 × mm]}]}`；空 series `[]` = 該小時無雨，卡片隱藏） |
| `StatusPageMonitor.over` | `https://status.exptech.dev/data/summary.json`（狀態頁的摘要；它回報異常時點亮「更多」分頁的狀態點） |
| `HasteApi.upload` | `https://haste.exptech.dev/api/pastes`（**POST**，上傳 App 日誌；回應的 `key` 組成 `https://haste.exptech.dev/<key>`） |
| `MlIntensityService._download` | `https://exptechtw.github.io/TREM-Lite/models/intensity_ml_v1.onnx`，失敗再試 `https://cdn.jsdelivr.net/gh/ExpTechTW/TREM-Lite@main/packages/core/static/models/intensity_ml_v1.onnx`（ML v1 震度模型，14.7 MB、gzip 傳輸約 2.3 MB） |

> **ML v1 模型目前沒有 ExpTech 主機提供**（`static.core-{tnn1,tyo1}` 都是 404），
> 所以從 TREM-Lite 發布的位置下載，並以 SHA-256 釘住檔案：jsDelivr 跟著
> `main`，同名重訓的模型會被拒絕。第一次開強震監視器時下載，gzip 壓縮後存在
> `dpip.db` 的 `ml_model`，之後不再連網。檔案一旦放上 `static.core-{region}`，
> 改用 `coreStatic` 層級即可。

> **衛星 TLE 目前不打網路。** `TleSource` 有一條遠端更新路徑（`TleFetcher`），
> 但正式碼沒有接線（`fetch` 為 null），實際只讀打包在 `assets/astro/` 的元素集。

## curl 可用性（2026-11-20 實測，HTTP 狀態碼）

### API 主機

| 端點 | lb-tpe1 | lb-khh1 | core-tyo1 | core-tnn1 | api-1 |
|---|:--:|:--:|:--:|:--:|:--:|
| `/api/v2/eq/eew` | 200 | 200 | 200 | 200 | 404 |
| `/api/v2/eq/report` | 404 | 404 | 200 | 200 | 404 |
| `/api/v3/trem/rts/{now−300}` | 404 | 404 | 200 | 200 | 404 |
| `/api/v1/cwa/tsunami` | 404 | 404 | 200 | 200 | 404 |
| `/api/v2/tiles/radar/list` | 404 | 404 | **200** | 200 | 404 |
| `/api/v2/tiles/qpesums/list` | 404 | 404 | **200** | 200 | 404 |
| `/api/v2/tiles/satellite/13/list` | 404 | 404 | 404 | 200 | 404 |
| `/api/v2/tiles/wind/gfs/list` | 404 | 404 | 404 | 200 | 404 |
| `/api/v5/meteor/weather/list` | 404 | 404 | **200**（11-28） | 200 | 404 |
| `/api/v2/notify/{token}` | 404 | 404 | **307** → tnn1 | 401 | 429 |
| `/api/v1/dpip/history/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v1/sse?topics=…` | 200 | 200 | 200（JSON） | 401 | 404 |

### static 主機

| 端點 | static lb-tpe1 | static lb-khh1 | static core-tyo1 | static core-tnn1 |
|---|:--:|:--:|:--:|:--:|
| `basemap {z}/{x}/{y}.pbf` | 200 | 200 | — | — |
| `/resource/station` | — | — | 200 | 200 |
| `radar/{sec}/…webp` | — | — | 200 | 200 |
| `qpesums/{sec}/…webp` | — | — | 200 | 200 |
| `dpm/{layer}/…mvt`、`dpm/aed/{id}` | — | — | 200 | 200 |
| `satellite/13/…webp` | — | — | 404 | 200 |
| `wind/…webp`、`…bin` | — | — | 404 | 200 |
| `v5/meteor/{family}/{sec}` | — | — | **200**（11-28） | 200 |

### 與 2026-08-02 的差異

- **雷達 list 與 QPESUMS list 在 `core-tyo1` 從 404 變成 200**，tile 與 DPM 也是；
  App 的 tier 因此從 `coreExclusiveApi`／`coreStaticExclusive` 換成
  `coreApi`／`coreStatic`（`FrameTileApi` 依 `path` 決定）。
- **`/api/v2/trem/rts` 換成 `/api/v3/trem/rts/{sec}`**（v2 是即時 SSE、v3 才是
  歷史），SSE 改由 `SseMux` 的 `/api/v1/sse` 承擔。
- **`/api/v1/trem/station` 不存在了**，測站清單是 `/resource/station`（CSV，在
  `static.core-*` 上）。
- **notify／location 在 `core-tyo1` 回 307 導回 tnn1**，而不是 404；那是熱備援
  的導向，不是備援自己在服務。2026-11-28 再測方向反過來：tnn1 回 307 導到
  tyo1、tyo1 回 200 —— primary 換到了 tyo1。
- **v5 meteor 在 `core-tyo1` 從 404 變成 200**（2026-11-28 實測；11-20 時還是
  404），API 與 static 兩邊都是，所以氣象家族換成 `coreApi`／`coreStatic`。
- **`api-1` 的每一條回應 `x-served-by` 都是 `core-tnn1`** —— 它已經是同一個
  origin 的另一個名字，不構成備援。

`/api/v2/tiles/radar/list` 在 tyo1 與 tnn1 都 200，但 **tile 仍在各自區域的
static 主機**上，所以「list 有」與「tile 有」要分開看。

只有 `lb-tpe1` / `lb-khh1` 對 `/api/v1/sse?topics=…` 回傳真正的
`text/event-stream`；`core-tyo1` 回 200 但是 `application/json`，`core-tnn1`
回 401。這就是即時串流固定用 `lbApi` 的原因 —— 跨國的 core 兩區再穩，也接不住 SSE。

---

How the client reaches these — `ApiClient`, tiers, failover — is in
[ARCHITECTURE.md § Networking](ARCHITECTURE.md#networking).
