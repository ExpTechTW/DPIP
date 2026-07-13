# DPIP API Map

Region-pinned endpoints — the DNS-balanced bare hosts (`api.lb`, `api.core`)
are never used. The region is chosen by `RegionSelection` state; multi-active
tiers fail over across their regions.

- **Regions:** LB = `tpe1` (Taipei), `khh1` (Kaohsiung); Core = `tyo1` (Tokyo),
  `tnn1` (Tainan).
- **Path prefix:** all paths are `/api/...` (verified by curl 2026-07).
- **Tiers:** `lbApi` = LB (multi-active), `coreApi` = Core (multi-active),
  `coreExclusiveApi` = `core-tnn1` only, `legacyApi` = `api-1` (not yet migrated).

> This is the **endpoint catalogue**, not a code map. There is no `lib/api/`
> monolith: each endpoint is (re)built as a thin datasource in the owning
> feature's `data/` (or `core/` for infra) when that feature is implemented,
> carrying its own `ApiTier`. Live today: earthquake EEW
> (`features/earthquake/data/earthquake_api.dart`), radar
> (`shared/map/radar_api.dart`). The rest below are staged here until their
> feature lands.
>
> **Time sync is not an HTTP endpoint.** The app's clock uses real **SNTP**
> (`flutter_ntp`, UDP/123) against `time.exptech.com.tw` (primary) /
> `time.apple.com` (backup), not a `/ntp` HTTP call — see
> `core/realtime/ntp_time_source.dart` + `app_time.dart` (`AppTime.utc` /
> `AppTime.utc8`).

## 多活備援 (multi-active)

| Method | Path | Tier | Hosts (failover order = selected first) |
|---|---|---|---|
| `openEewSse` | `/api/v2/eq/eew?sse=1` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getRtsRealtime` | `/api/v2/trem/rts` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getEewRealtime` | `/api/v2/eq/eew` | `lbApi` | `api.lb-{tpe1,khh1}.exptech.dev` |
| `getReportList` | `/api/v2/eq/report` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |
| `getReport` | `/api/v2/eq/report/{id}` | `coreApi` | `api.core-{tyo1,tnn1}.exptech.dev` |

> **Live feeds are SSE, not polling.** The `?sse=1` flag switches an endpoint to
> `text/event-stream`: each event's `data:` is the *same JSON* the plain GET
> returns (so models are unchanged), pushed on change instead of pulled each
> second. `openEewSse` is the live EEW transport (`getEewRealtime` remains as the
> one-shot snapshot); `/api/v2/trem/rts?sse=1` is the same shape for RTS when that
> feed lands. Transport, buffering, and reconnection live behind the realtime
> `RealtimeSource` seam (`core/realtime/sse_realtime_source.dart`) — the channel,
> staleness classifier, and lifecycle are unchanged. EEW is **bursty** (silent
> between earthquakes → liveness = "connection open"); RTS is **continuous**
> (~1 Hz → liveness = "recent event").

## 沒多活備援 (single host, no failover)

Migrated to the region topology (`core-tnn1`):

| Method | Path | Tier | Host |
|---|---|---|---|
| `getRadarList` | `/api/v1/tiles/radar/list` | `coreExclusiveApi` | `api.core-tnn1.exptech.dev` |

Not yet migrated — legacy `api-1` (move to `core-tnn1` as the backend deploys):

| Method | Path | Tier | Host |
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
| `getAnnouncements` | `/api/v1/dpip/announcement` | `legacyApi` | `api-1.exptech.dev` |
| `updateDeviceLocation` | `/api/v2/location/{platform}/{token}/{version}/{lat},{lng}` | `legacyApi` | `api-1.exptech.dev` |
| `getNotify` | `/api/v2/notify/{token}` | `legacyApi` | `api-1.exptech.dev` |
| `setNotify` | `/api/v2/notify/{token}/{channel}/{status}` | `legacyApi` | `api-1.exptech.dev` |
| `getNotificationHistory` | `/api/v1/notify/history` | `legacyApi` | `api-1.exptech.dev` |

## 暫時無 (unavailable)

| Method | Note |
|---|---|
| `getTsunamiList` | Temporarily unavailable — throws `UnsupportedError`. |

## External (third-party, no region)

| Method | URL |
|---|---|
| `getLocalizationProgress` | `https://exptech.dev/api/v1/dpip/locale` |
| `getReleases` | `https://api.github.com/repos/ExpTechTW/DPIP-Pocket/releases` |
| `getStatus` | `https://status.exptech.dev/api/v1/status/data?duration=1d` |

## curl availability (2026-07, HTTP status)

| Endpoint | lb-tpe1 | lb-khh1 | core-tyo1 | core-tnn1 | api-1 |
|---|:--:|:--:|:--:|:--:|:--:|
| `/api/v2/trem/rts` | 200 | 200 | 404 | 401 | 200 |
| `/api/v2/eq/eew` | 200 | 200 | 200 | 200 | — |
| `/api/v2/eq/report` | 404 | 404 | 200 | 200 | 404 |
| `/api/v1/trem/station` | 404 | 404 | 404 | 404 | 200 |
| `/api/v2/meteor/weather/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v1/dpip/realtime/list` | 404 | 404 | 404 | 404 | 200 |
| `/api/v1/tiles/radar/list` | 404 | 404 | 404 | 200 | — |
| `/api/v1/tsunami/list` | 404 | 404 | 404 | 404 | 404 |
